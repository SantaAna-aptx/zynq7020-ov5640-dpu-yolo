// cam_tb2.v -- ov5640_cam_top simulation with the deterministic framing.
//
// The RTL now frames the stream by COUNTING: tlast rides on the 1280th pixel of each line
// (LINE_PX) and capture stops after 720 lines until the next VSYNC. This testbench sends
// full 1280-pixel lines (so the tlast spacing is exercised for real) but only a few lines
// per frame, which keeps the simulation fast.
//
// Checks:
//   * tuser appears exactly once per frame, on the first pixel after VSYNC
//   * tlast appears exactly on pixel 1280 of every line
//   * pixel data matches the sensor model
//   * tdata never changes while tvalid is held and tready is low (AXI-Stream protocol)
//   * the capture FIFO never overflows
`timescale 1ns/1ps
module cam_tb2;

reg ACLK = 0;
reg ARESETN = 0;
always #10 ACLK = ~ACLK;               // 50 MHz (matches CLKIN1_PERIOD=20ns)

reg cmos_pclk = 0;
always #20.833 cmos_pclk = ~cmos_pclk; // ~24 MHz

reg  [7:0] cmos_data  = 0;
reg        cmos_vsync = 0;
reg        cmos_href  = 0;
wire       cmos_xclk, cmos_scl, cmos_sda_o, cmos_sda_oe, cam_cfg_done, dbg_i2c_done, dbg_retry;
wire [7:0] dbg_pclk_cnt;
wire [15:0] m_axis_video_tdata;
wire        m_axis_video_tvalid, m_axis_video_tuser, m_axis_video_tlast;
reg         m_axis_video_tready = 1'b1;

localparam PX_PER_LINE = 1280;   // must match LINE_PX in ov5640_cam_top.v
localparam LINES       = 65;     // must exceed MIN_LINES_PER_FRAME (64) so the VSYNC debounce accepts a frame
localparam SKIP_FRAMES = 132;    // the RTL drops the first 130 frames

ov5640_cam_top #(.FIFO_DEPTH_LOG(9)) dut (
    .ACLK(ACLK), .ARESETN(ARESETN),
    .cmos_pclk(cmos_pclk), .cmos_data(cmos_data),
    .cmos_vsync(cmos_vsync), .cmos_href(cmos_href),
    .cmos_xclk(cmos_xclk), .cmos_scl(cmos_scl),
    .cmos_sda_i(1'b1), .cmos_sda_o(cmos_sda_o), .cmos_sda_oe(cmos_sda_oe),
    .cam_cfg_done(cam_cfg_done),
    .dbg_pclk_cnt(dbg_pclk_cnt), .dbg_i2c_done(dbg_i2c_done), .dbg_retry(dbg_retry),
    .m_axis_video_tdata(m_axis_video_tdata),
    .m_axis_video_tvalid(m_axis_video_tvalid),
    .m_axis_video_tuser(m_axis_video_tuser),
    .m_axis_video_tlast(m_axis_video_tlast),
    .m_axis_video_tready(m_axis_video_tready)
);

function [15:0] exp_pixel(input integer k);
    exp_pixel = {8'hA0 + k[7:0], 8'h5B + k[7:0]};   // repeats every line
endfunction

//---------------- checker ----------------
integer errors = 0, beats = 0, frames = 0, lines = 0;
integer px_in_line = 0;
// PCLK-domain count of pixels handed to the FIFO, to separate a camera-side loss from a
// FIFO/AXIS-side loss.
integer wr_count = 0, wr_at_last = 0;
always @(posedge cmos_pclk) if (dut.px_valid_w) wr_count = wr_count + 1;
always @(posedge ACLK) begin
    if (ARESETN && m_axis_video_tvalid && m_axis_video_tready) begin
        beats = beats + 1;
        if (m_axis_video_tuser) begin
            if (px_in_line != 0) begin
                errors = errors + 1;
                $display("[ERR] tuser at px %0d (expected 0)", px_in_line);
            end
            frames = frames + 1;
            px_in_line = 0;
        end
        if (m_axis_video_tdata !== exp_pixel(px_in_line)) begin
            errors = errors + 1;
            if (errors < 10)
                $display("[ERR] frame%0d px%0d: got=%h exp=%h", frames, px_in_line,
                         m_axis_video_tdata, exp_pixel(px_in_line));
        end
        if (m_axis_video_tlast) begin
            if (px_in_line != PX_PER_LINE-1) begin
                errors = errors + 1;
                $display("[ERR] tlast at px %0d (expected %0d)  bytes_in_line=%0d pend_v=%b wr=%0d (d=%0d)",
                         px_in_line, PX_PER_LINE-1, dut.bytes_in_line_r, dut.pend_v,
                         wr_count, wr_count - wr_at_last);
                wr_at_last = wr_count;
            end
            lines = lines + 1;
            px_in_line = 0;
        end else begin
            px_in_line = px_in_line + 1;
        end
        if (frames >= 2 && lines >= 2*LINES) begin
            $display("[TB] beats=%0d frames=%0d lines=%0d errors=%0d fifo_ovf=%b",
                     beats, frames, lines, errors, dut.fifo_ovf);
            if (errors == 0 && dut.fifo_ovf === 1'b0) $display("SIM_RESULT=PASS");
            else $display("SIM_RESULT=FAIL");
            $finish;
        end
    end
end

//---------------- AXI-Stream protocol monitor ----------------
reg [15:0] held_data;
reg        held_valid;
always @(posedge ACLK) begin
    if (held_valid && held_data !== m_axis_video_tdata) begin
        errors = errors + 1;
        $display("[ERR] tdata changed while tvalid=1 tready=0: %h -> %h", held_data, m_axis_video_tdata);
    end
    held_valid <= m_axis_video_tvalid & ~m_axis_video_tready;
    held_data  <= m_axis_video_tdata;
end

integer cyc = 0;
always @(posedge ACLK) begin
    cyc = cyc + 1;
    m_axis_video_tready <= (cyc % 97 < 23) ? 1'b0 : 1'b1;   // stall ~24 of every 97 cycles
end

//---------------- sensor model ----------------
integer frame, line, pix;
task send_frame;
begin
    cmos_vsync = 1; repeat (5) @(negedge cmos_pclk);
    cmos_vsync = 0; repeat (2) @(negedge cmos_pclk);
    for (line = 0; line < LINES; line = line + 1) begin
        cmos_href = 1;
        for (pix = 0; pix < 2*PX_PER_LINE; pix = pix + 1) begin
            cmos_data = (pix % 2 == 0) ? (8'hA0 + (pix/2)) : (8'h5B + (pix/2));
            @(negedge cmos_pclk);
        end
        cmos_href = 0;
        repeat (10) @(negedge cmos_pclk);
    end
    repeat (25) @(negedge cmos_pclk);
end
endtask

initial begin
    $display("[TB] start (PX_PER_LINE=%0d LINES=%0d)", PX_PER_LINE, LINES);
    repeat (20) @(posedge ACLK);
    ARESETN = 1;
    #20000;                     // MMCM lock + reset chain
    for (frame = 0; frame < SKIP_FRAMES + 3; frame = frame + 1) send_frame;
    $display("[TB] model finished sending");
end

initial begin
    #120_000_000;    // 120 ms: SKIP_FRAMES=10 plus two 65-line frames
    $display("[TB-TIMEOUT] beats=%0d frames=%0d lines=%0d errors=%0d", beats, frames, lines, errors);
    $display("[TB-DBG] mmcm=%b skip_ge10=%b px_valid=%b sof_seen=%b fifo_ovf=%b px_in_line=%0d bytes_line=%0d",
             dut.mmcm_locked, dut.frame_skip_ge10, dut.px_valid_w, dut.sof_seen, dut.fifo_ovf,
             dut.px_in_line, dut.bytes_in_line_r);
    $display("SIM_RESULT=FAIL");
    $finish;
end

endmodule
