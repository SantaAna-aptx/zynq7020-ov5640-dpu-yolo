// cam_tb.v — ov5640_cam_top 仿真测试台
// 传感器模型：产生 4 行 x 16 像素的测试帧（像素值可辨识），验证 AXIS 输出拼包/sof/eol 正确
`timescale 1ns/1ps
module cam_tb;

reg ACLK = 0;
reg ARESETN = 0;
always #5 ACLK = ~ACLK;   // 100MHz

reg cmos_pclk = 0;
// 24MHz PCLK
always #20.833 cmos_pclk = ~cmos_pclk;

reg  [7:0] cmos_data = 0;
reg        cmos_vsync = 0;
reg        cmos_href = 0;
wire       cmos_xclk;
wire       cmos_scl;
wire       cmos_sda;
wire       cam_cfg_done;
wire [15:0] m_axis_video_tdata;
wire        m_axis_video_tvalid, m_axis_video_tuser, m_axis_video_tlast;
reg         m_axis_video_tready = 1'b1;

// sda/scl 上拉
assign cmos_sda = 1'b1;

integer errors = 0;
integer pixels_checked = 0;

ov5640_cam_top #(.FIFO_DEPTH_LOG(9)) dut (
    .ACLK(ACLK), .ARESETN(ARESETN),
    .cmos_pclk(cmos_pclk), .cmos_data(cmos_data),
    .cmos_vsync(cmos_vsync), .cmos_href(cmos_href),
    .cmos_xclk(cmos_xclk), .cmos_scl(cmos_scl), .cmos_sda(cmos_sda),
    .cam_cfg_done(cam_cfg_done),
    .m_axis_video_tdata(m_axis_video_tdata),
    .m_axis_video_tvalid(m_axis_video_tvalid),
    .m_axis_video_tuser(m_axis_video_tuser),
    .m_axis_video_tlast(m_axis_video_tlast),
    .m_axis_video_tready(m_axis_video_tready)
);

// 期望像素：pixel k = {8'hA0+k, 8'h5B+k}
function [15:0] exp_pixel(input integer k);
    exp_pixel = {8'hA0 + k[7:0], 8'h5B + k[7:0]};
endfunction

// AXIS 监视：帧首 tuser 必须为 1，数据按序
integer frame_count = 0;
integer px_in_frame = 0;
always @(posedge ACLK) begin
    if (ARESETN && m_axis_video_tvalid && m_axis_video_tready) begin
        if (m_axis_video_tuser) begin
            if (px_in_frame != 0 && px_in_frame != 16)
                $display("[TB-WARN] 上一帧像素数=%0d (期望16)", px_in_frame);
            frame_count = frame_count + 1;
            px_in_frame = 0;
        end
        if (m_axis_video_tdata !== exp_pixel(px_in_frame)) begin
            errors = errors + 1;
            $display("[TB-ERR] frame%0d px%0d: got=%h exp=%h",
                     frame_count, px_in_frame, m_axis_video_tdata, exp_pixel(px_in_frame));
        end
        px_in_frame = px_in_frame + 1;
        pixels_checked = pixels_checked + 1;
        if (pixels_checked == 1)
            $display("[TB-INFO] 第一像素: %h (tuser=%b)", m_axis_video_tdata, m_axis_video_tuser);
        if (pixels_checked >= 64) begin
            $display("[TB-PASS] 共校验 %0d 像素 / %0d 帧, 错误 %0d", pixels_checked, frame_count, errors);
            if (errors == 0) $display("SIM_RESULT=PASS");
            else $display("SIM_RESULT=FAIL");
            $finish;
        end
    end
end

// 传感器时序模型：2 帧即可（帧跳过逻辑需 10 帧以上才出数据——发送 12 帧）
// 传感器时序模型：数据在 PCLK 下降沿更新，DUT 在上升沿采样（每字节恰好一次）
integer dbg_cnt = 0;
always @(negedge cmos_pclk) begin
    if (cmos_href && dbg_cnt < 70) begin
        $display("[BYTE] n=%0d data=%h href=%b vsync=%b", dbg_cnt, cmos_data, cmos_href, cmos_vsync);
        dbg_cnt = dbg_cnt + 1;
    end
end

integer frame, line, pix;
task send_frame;
begin
    // VSYNC 高（帧同步期）
    cmos_vsync = 1; repeat (5) @(negedge cmos_pclk);
    cmos_vsync = 0; repeat (2) @(negedge cmos_pclk);
    for (line = 0; line < 4; line = line + 1) begin
        cmos_href = 1;
        for (pix = 0; pix < 32; pix = pix + 1) begin   // 16 像素 = 32 字节
            cmos_data = (pix % 2 == 0) ? (8'hA0 + (pix/2)) : (8'h5B + (pix/2));
            @(negedge cmos_pclk);
        end
        cmos_href = 0;
        repeat (10) @(negedge cmos_pclk);  // 行消隐
    end
    repeat (25) @(negedge cmos_pclk);      // 帧消隐
end
endtask

initial begin
    $display("[TB-INFO] 仿真开始");
    repeat (20) @(posedge ACLK);
    ARESETN = 1;
    #10_000;   // 等 MMCM 锁定 + 复位链完全稳定（10µs），传感器帧从整帧边界开始
    // 持续发帧（前 10 帧被丢弃计数吞掉；MMCM 锁定后采集开始），由监视器在 64 像素后结束
    forever
        send_frame;
end

// 调试计数器
integer vsync_falls = 0, px_valids = 0, axis_fires = 0;
integer href_d_cnt = 0, byte_sel_cnt = 0, href_pin_cnt = 0;
integer dbg_writes = 0, dbg_reads = 0;
always @(posedge ACLK) begin
    if (ARESETN) begin
        if (dut.vsync_fall_d) vsync_falls = vsync_falls + 1;
        if (dut.px_valid_w) begin
            px_valids = px_valids + 1;
            if (dbg_writes < 8) begin
                dbg_writes = dbg_writes + 1;
                $display("[WR%0d] t=%0t px_data=%h sof=%b eol=%b", dbg_writes, $time, dut.px_data_w, dut.px_sof_w, dut.px_eol_w);
            end
        end
        if (dut.href_d)       href_d_cnt = href_d_cnt + 1;
        if (dut.byte_sel_r)   byte_sel_cnt = byte_sel_cnt + 1;
        if (m_axis_video_tvalid && m_axis_video_tready) begin
            axis_fires = axis_fires + 1;
            if (dbg_reads < 8) begin
                dbg_reads = dbg_reads + 1;
                $display("[RD%0d] t=%0t axis=%h tuser=%b tlast=%b", dbg_reads, $time, m_axis_video_tdata, m_axis_video_tuser, m_axis_video_tlast);
            end
        end
    end
end
always @(posedge cmos_pclk) begin
    if (cam_tb.dut.cam_rstn_24m && cmos_href) href_pin_cnt = href_pin_cnt + 1;
end
initial begin
    repeat (30) begin
        #1_000_000;
        $display("[PROG] t=%0tus vsync_falls=%0d px_valids=%0d axis=%0d cfg_done=%b",
                 $time/1000, vsync_falls, px_valids, axis_fires, dut.cam_cfg_done);
    end
end

// 超时保护
initial begin
    #30_000_000;
    $display("[TB-TIMEOUT] 30ms 仿真超时，帧数=%0d 像素=%0d 错误=%0d", frame_count, pixels_checked, errors);
    $display("[TB-DBG] mmcm_locked=%b frame_skip=%0d ge10=%b frame_on=%b px_valid=%b cfg_done=%b xclk=%b",
             dut.mmcm_locked, dut.frame_skip, dut.frame_skip_ge10, dut.frame_on, dut.px_valid_w,
             dut.cam_cfg_done, dut.cmos_xclk);
    $display("[TB-DBG2] href_d拍数=%0d byte_sel拍数=%0d 引脚href拍数=%0d",
             href_d_cnt, byte_sel_cnt, href_pin_cnt);
    if (pixels_checked >= 64 && errors == 0) $display("SIM_RESULT=PASS");
    else $display("SIM_RESULT=FAIL");
    $finish;
end

endmodule
