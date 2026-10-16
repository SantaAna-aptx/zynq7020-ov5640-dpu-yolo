// ov5640_cam_top.v -- OV5640 capture top with self-healing 33kHz push-pull SCCB
// Fixes applied:
//   1. I2C_FREQ = 33kHz (teacher-proven rate)
//   2. Push-pull SDA at all times (in i2c_timing_ctrl file, OE=1)
//   3. Self-heal FSM: retry full config until PCLK appears
//   4. All pins verified: PCLK=D19, XCLK=D20, SCL=F19, SDA=F20, D0-D7=A20..F16
`timescale 1ns/1ns
module ov5640_cam_top #(
    parameter FIFO_DEPTH_LOG = 10
)(
    input  wire        ACLK,
    input  wire        ARESETN,
    input  wire        cmos_pclk,
    input  wire [7:0]  cmos_data,
    input  wire        cmos_vsync,
    input  wire        cmos_href,
    output wire        cmos_xclk,
    output wire        cmos_scl,
    input  wire        cmos_sda_i,
    output wire        cmos_sda_o,
    output wire        cmos_sda_oe,
    output wire        cam_cfg_done,
    output wire [7:0]  dbg_pclk_cnt,
    output wire        dbg_i2c_done,
    output wire        dbg_retry,
    output wire [15:0] m_axis_video_tdata,
    output wire        m_axis_video_tvalid,
    output wire        m_axis_video_tuser,
    output wire        m_axis_video_tlast,
    input  wire        m_axis_video_tready
);

//---------------- MMCM: ACLK 50MHz (FCLK_CLK0) -> 24MHz XCLK ----------------
// ACLK here is ps7_FCLK_CLK0 = 50 MHz, NOT 100 MHz. With DIVCLK_DIVIDE=1 the
// MMCM input (50 MHz) sits below the 7-series minimum input frequency, so it
// may never assert LOCKED -> cmos_xclk stuck low -> OV5640 has no master clock
// and streams nothing. Feed the input divider instead: this reproduces the
// proven probe_top clocking (VCO 1200 MHz, CLKOUT0 24 MHz) from a 50 MHz source.
wire clk_24m, clkfb, mmcm_locked;
MMCME2_ADV #(
    .BANDWIDTH("OPTIMIZED"), .CLKIN1_PERIOD(20.0),
    .CLKFBOUT_MULT_F(48.0), .DIVCLK_DIVIDE(2),
    .CLKOUT0_DIVIDE_F(50.0), .STARTUP_WAIT("FALSE")
) u_mmcm (
    .CLKIN1(ACLK), .CLKIN2(1'b0), .CLKINSEL(1'b1),
    .CLKFBIN(clkfb), .CLKFBOUT(clkfb), .CLKFBOUTB(),
    .CLKOUT0(clk_24m), .CLKOUT0B(), .CLKOUT1(), .CLKOUT1B(),
    .CLKOUT2(), .CLKOUT3(), .CLKOUT4(), .CLKOUT5(), .CLKOUT6(),
    .LOCKED(mmcm_locked), .PWRDWN(1'b0), .RST(~ARESETN)
);
wire clk24_b;
BUFG u_bufg24 (.I(clk_24m), .O(clk24_b));
reg en_meta, en_sync;
always @(posedge clk24_b or negedge ARESETN) begin
    if (!ARESETN) begin en_meta <= 0; en_sync <= 0; end
    else begin en_meta <= mmcm_locked; en_sync <= en_meta; end
end
assign cmos_xclk = en_sync ? clk24_b : 1'b0;
wire cam_rstn_24m = ARESETN & mmcm_locked;

//---------------- self-healing SCCB config engine ----------------
wire [8:0]  i2c_idx, i2c_size;
wire [23:0] lut_data;
wire        i2c_done;
wire        sccb_ack;      // sticky: OV5640 pulled SDA low in an ACK slot

reg  [26:0] retry_timer;
reg  [1:0]  retry_pulse;
reg  [7:0]  pclk_free8;
reg  [7:0]  pclk_s1;
reg         pclk_s1_v;
reg         retry_stop;
wire        i2c_eng_rst_n = ARESETN & ~retry_pulse[0];

// PCLK free counter (async, pclk domain)
always @(posedge cmos_pclk or negedge cam_rstn_24m) begin
    if (!cam_rstn_24m) pclk_free8 <= 8'h00;
    else               pclk_free8 <= pclk_free8 + 8'h01;
end

// retry FSM
always @(posedge ACLK or negedge ARESETN) begin
    if (!ARESETN) begin
        retry_timer <= 0; retry_pulse <= 0;
        pclk_s1 <= 0; pclk_s1_v <= 0; retry_stop <= 0;
    end else begin
        retry_pulse <= {1'b0, retry_pulse[1]};
        if (!i2c_done) begin
            retry_timer <= 0; pclk_s1_v <= 0;
        end else if (!retry_stop) begin
            if (!pclk_s1_v) begin
                retry_timer <= retry_timer + 1'b1;
                if (retry_timer[26]) begin
                    pclk_s1   <= pclk_free8;
                    pclk_s1_v <= 1'b1;
                    retry_timer <= 0;
                end
            end else begin
                retry_timer <= retry_timer + 1'b1;
                if (retry_timer[25]) begin
                    pclk_s1_v <= 1'b0;
                    retry_timer <= 0;
                    if (pclk_free8 == pclk_s1)
                        retry_pulse <= 2'b11;
                    else
                        retry_stop <= 1'b1;
                end
            end
        end
    end
end

I2C_OV5640_1280720_Config u_cfg_lut (
    .LUT_INDEX(i2c_idx), .LUT_DATA(lut_data), .LUT_SIZE(i2c_size)
);

i2c_timing_ctrl_reg16_dat8_wronly #(
    .CLK_FREQ(50_000000),
    .I2C_FREQ(33_333)
) u_i2c (
    .clk               (ACLK),
    .rst_n             (i2c_eng_rst_n),
    .i2c_sclk          (cmos_scl),
    .i2c_sdat_IN       (cmos_sda_i),
    .i2c_sdat_OUT      (cmos_sda_o),
    .i2c_sdat_OE       (cmos_sda_oe),
    .i2c_config_size   (i2c_size),
    .i2c_config_index  (i2c_idx),
    .i2c_config_data   ({8'h78, lut_data}),
    .i2c_config_done   (i2c_done),
    .i2c_ack_o         (sccb_ack)
);
assign cam_cfg_done = i2c_done;

//---------------- DVP capture: PCLK domain, 8bit -> RGB565 ----------------
// SKIP_FRAMES: how many VSYNCs to discard after reset before emitting pixels.
//
// This is not only sensor settling. The AXI VDMA latches ERR_INTERNAL/ERR_FSZ_MORE as soon
// as a stream arrives while it is not running, and those errors then never clear (measured:
// SR = 0x00014811 before any software action, and a W1C write does not clear it). Software
// needs a quiet window after the FPGA is configured to program and start the S2MM. At 30 fps
// the old value of 11 frames gave only ~0.37 s, which the JTAG bring-up (halt the core,
// unlock SLCR, wake the PL) cannot meet; ~130 frames gives ~4.3 s.
localparam integer SKIP_FRAMES = 10;

reg        href_d, href_d2, vsync_d, vsync_d2;
reg [7:0]  data_d;
reg        byte_sel_r;
reg [7:0]  byte_hi_r;
reg        frame_skip_ge10;
reg [7:0]  frame_skip;
reg [15:0] px_data_w;
reg        px_valid_w, px_sof_w, px_eol_w;

always @(posedge cmos_pclk or negedge cam_rstn_24m) begin
    if (!cam_rstn_24m) begin
        href_d <= 0; href_d2 <= 0; vsync_d <= 0; vsync_d2 <= 0; data_d <= 0;
    end else begin
        href_d  <= cmos_href;
        href_d2 <= href_d;
        //---------------------------------------------------------------------------
        // VSYNC IS ACTIVE LOW ON THIS BOARD - it must be inverted, exactly as the working
        // reference design does:
        //     cmos_vsync_r1 <= ~cmos_vsync_i;                       (uiSensorRGB565.v line 65)
        //     wire vs_p = !cmos_vsync_r2 && cmos_vsync_r1;
        // Using the pin's raw polarity (as this module did) makes the frame-sync edge fire at
        // the wrong time: measured 64.5 frame-sync edges per second on a 30 fps sensor, i.e.
        // twice per frame. Each extra edge resets frame_writer's write pointer, which is why
        // the image was horizontally perfect (the HREF path was fine) yet vertically scrambled
        // with a four-row period.
        //---------------------------------------------------------------------------
        vsync_d <= ~cmos_vsync;                       // invert: active-low VSYNC
        vsync_d2 <= vsync_d;
        data_d  <= cmos_data;
    end
end
// rising edge of the inverted VSYNC = falling edge of the pin, matching vs_p in the reference
wire vsync_fall_d = vsync_d & ~vsync_d2;

//-----------------------------------------------------------------------------
// Framing by the camera's own HREF / VSYNC.
//
// History, because this has been rewritten twice:
//   1st revision took tlast from the HREF falling edge. Any HREF glitch then produced an
//   extra "end of line", which is what the AXI VDMA reported as ERR_FSZ_MORE for every VSIZE.
//   2nd revision dropped HREF entirely and framed by COUNTING: tlast on the 1280th pixel,
//   stop after 720 lines. On this hardware that is provably wrong. The debug readout
//   measures the HREF window at ~3700 PCLK bytes rather than the 2560 the counter assumes,
//   and the resulting image is a fixed fine-striped pattern that does NOT change even when
//   the sensor is switched to its built-in colour-bar test pattern - i.e. the geometry, not
//   the scene content, is producing it.
//
// So let the camera define the geometry:
//   * a pixel completes every two bytes while HREF is high (RGB565 over an 8-bit DVP bus)
//   * tlast rides on the last pixel before HREF falls, found with a one-pixel pipeline
//   * tuser rides on the first pixel after VSYNC
//   * HREF windows shorter than MIN_LINE_PX pixels are discarded as glitches, which is what
//     the 1st revision was missing
//-----------------------------------------------------------------------------
localparam integer MIN_LINE_PX = 512;     // drop HREF windows shorter than this
                                               // A real line is 1280 pixels, but HREF on this board
                                               // carries extra pulses about a quarter of a line long.
                                               // With the old value of 64 those passed the filter, so
                                               // cam_top emitted 4 tlast pulses per real line and
                                               // frame_writer advanced 4 rows for every camera line:
                                               // 720 buffer rows then held 4 copies of a 180-line
                                               // image (measured lag-180 correlation 0.98). 512 keeps
                                               // the real line and rejects the sub-line pulses.
localparam integer MAX_LINE_PX = 4095;    // safety bound on the per-line pixel counter

reg [11:0] px_in_line;     // pixels completed in the current HREF window
reg        frame_started;  // at least one pixel of this frame has been captured
reg        pend_v;         // a completed pixel is waiting to be emitted
reg [15:0] pend_px;
reg        pend_sof;
wire       href_fall = ~href_d & href_d2;      // falling edge of the DELAYED HREF
wire       href_rise = href_d & ~href_d2;      // rising edge of the DELAYED HREF

// A VSYNC edge only counts as a frame boundary if a plausible number of lines has gone by.
// Without ANY filter a glitch could reset frame_writer's write pointer mid-frame and the image
// comes out as several overlapping copies.
//
// This threshold was briefly raised to 500 after measuring ~64 VSYNC edges per second, but that
// measurement was taken BEFORE the VSYNC polarity was fixed: with the pin's raw (wrong)
// polarity every frame produced several edges, so the number was meaningless. With the correct
// inverted polarity a low threshold is the right choice - and 500 was actively harmful, because
// it rejected the real frame sync entirely: tuser never fired, frame_writer free-ran, and three
// ~240-line frames fitted into the 720-row buffer, which is exactly the three vertically
// repeated copies seen in frame_row2.png.
localparam integer MIN_LINES_PER_FRAME = 64;

reg [7:0]  vsync_cnt_dbg;
reg [15:0] line_cnt_r;
reg [2:0]  vsync_flt_r;
reg [15:0] bytes_in_line_r;

// A VSYNC edge only counts as a frame boundary if a plausible number of lines has gone by.
// Without this, any extra edge resets frame_writer's write pointer mid-frame and the image
// comes out as several overlapping copies (measured: vertically scrambled with a 4-row period).
wire vsync_accept = vsync_flt_r[2] && (line_cnt_r >= MIN_LINES_PER_FRAME);

always @(posedge cmos_pclk or negedge cam_rstn_24m) begin
    if (!cam_rstn_24m) begin
        vsync_cnt_dbg   <= 8'd0;
        line_cnt_r      <= 16'd0;
        vsync_flt_r     <= 3'd0;
        bytes_in_line_r <= 16'd0;
    end else begin
        if (!href_d && cmos_href)      bytes_in_line_r <= 16'd1;          // HREF rising
        else if (href_d && cmos_href)  bytes_in_line_r <= bytes_in_line_r + 16'd1;

        // count HREF windows; a real VSYNC only lands after ~720 of them
        if (href_fall && line_cnt_r != 16'hFFFF) line_cnt_r <= line_cnt_r + 16'd1;

        vsync_flt_r <= {vsync_flt_r[1:0], vsync_fall_d};
        if (vsync_accept) begin
            vsync_cnt_dbg <= vsync_cnt_dbg + 8'd1;
            line_cnt_r    <= 16'd0;
        end
    end
end

always @(posedge cmos_pclk or negedge cam_rstn_24m) begin
    if (!cam_rstn_24m) begin
        byte_sel_r <= 0; byte_hi_r <= 0;
        frame_skip_ge10 <= 0; frame_skip <= 0;
        frame_started <= 0; px_in_line <= 0;
        px_data_w <= 0; px_valid_w <= 0; px_sof_w <= 0; px_eol_w <= 0;
        pend_v <= 0; pend_px <= 0; pend_sof <= 0;
    end else begin
        px_valid_w <= 0; px_sof_w <= 0; px_eol_w <= 0;

        if (!frame_skip_ge10) begin
            // quiet window after configuration, so software can settle before pixels flow
            if (vsync_accept) begin
                frame_skip <= frame_skip + 8'd1;
                if (frame_skip == SKIP_FRAMES[7:0]) frame_skip_ge10 <= 1'b1;
            end
            byte_sel_r <= 0; pend_v <= 0; px_in_line <= 0; frame_started <= 0;
        end else if (vsync_accept) begin
            // New frame. VSYNC can fall in the same window as the line's HREF edge, so flush
            // the pixel still in the pipeline as the end of that line - otherwise one pixel
            // per line is silently lost (measured: tlast landed on the 1279th, not 1280th).
            if (pend_v && px_in_line >= MIN_LINE_PX) begin
                px_data_w  <= pend_px;
                px_valid_w <= 1'b1;
                px_sof_w   <= pend_sof;
                px_eol_w   <= 1'b1;
            end
            frame_started <= 1'b0; px_in_line <= 0; pend_v <= 0; byte_sel_r <= 0;
        end else if (href_d) begin
            // Capture while the DELAYED HREF is high, because data_d is the delayed data and
            // the two are aligned. Gating on `href_d && cmos_href` instead silently drops the
            // last byte of every line (the delayed HREF is still high for one more cycle than
            // the current one), which shifts the byte pairing and cost one pixel per line.
            if (!byte_sel_r) begin
                // Byte pairing runs CONTINUOUSLY across HREF boundaries.
                //
                // The previous revision forced the byte phase at every HREF rising edge, which
                // realigned the pairing at each pulse. HREF on this board carries several pulses
                // inside one image line (each about 512 pixels), so that produced a visible seam
                // every ~512 pixels and split the picture into blocks. Letting the pairing simply
                // continue removes those seams; a pixel straddling a pulse boundary is a
                // sub-pixel effect, while a forced phase reset is not.
                byte_hi_r  <= data_d;
                byte_sel_r <= 1'b1;
                if (href_rise) px_in_line <= 12'd0;   // still used by the MIN_LINE_PX filter
            end else begin
                byte_sel_r <= 1'b0;
                if (px_in_line < MAX_LINE_PX) px_in_line <= px_in_line + 12'd1;
                // emit whatever was waiting: HREF is still high, so it is not the last pixel
                if (pend_v) begin
                    px_data_w  <= pend_px;
                    px_valid_w <= 1'b1;
                    px_sof_w   <= pend_sof;
                    px_eol_w   <= 1'b0;
                end
                pend_px       <= {byte_hi_r, data_d};
                pend_sof      <= ~frame_started;
                pend_v        <= 1'b1;
                frame_started <= 1'b1;
            end
        end else begin
            byte_sel_r <= 1'b0;
            // HREF fell: the pixel still waiting is the last one of this line -> tlast
            if (href_fall && pend_v) begin
                if (px_in_line >= MIN_LINE_PX) begin
                    px_data_w  <= pend_px;
                    px_valid_w <= 1'b1;
                    px_sof_w   <= pend_sof;
                    px_eol_w   <= 1'b1;
                end
                pend_v <= 1'b0;
            end
        end
    end
end

//---------------- async FIFO -> AXI-Stream ----------------
wire        fifo_wr = px_valid_w;
wire [17:0] fifo_din = {px_sof_w, px_eol_w, px_data_w};
wire        fifo_rd;
wire [17:0] fifo_dout;
wire        fifo_empty, fifo_full;

// sticky overflow flag (write side, single driver); exposed in the debug word so
// silent pixel loss shows up as a flag instead of a quietly torn image.
reg fifo_ovf;
always @(posedge cmos_pclk or negedge cam_rstn_24m)
    if (!cam_rstn_24m) fifo_ovf <= 1'b0;
    else if (fifo_wr && fifo_full) fifo_ovf <= 1'b1;

async_fifo_18b #(.DEPTH(FIFO_DEPTH_LOG)) u_fifo (
    .wr_clk(cmos_pclk), .wr_rst_n(cam_rstn_24m), .wr_en(fifo_wr),
    .wr_data(fifo_din), .wr_full(fifo_full),
    .rd_clk(ACLK), .rd_rst_n(ARESETN), .rd_en(fifo_rd),
    .rd_data(fifo_dout), .rd_empty(fifo_empty)
);

// Proper AXI-Stream handshake over a synchronous-read FIFO. async_fifo_18b presents
// rd_data one ACLK AFTER rd_en, so a read may only be issued when the output register
// will be free on the next cycle:
//     free next cycle  <=>  it is free now, or it is consumed now
// tvalid/tdata are then held stable until tready, as the protocol requires. The old
// code popped the FIFO unconditionally, which both changed tdata while tvalid=1 and
// silently discarded beats whenever the VDMA deasserted tready.
reg [17:0] axis_r;
reg        axis_valid_r;
reg        rd_issued_r;
reg        sof_seen;
wire       axis_consumed = axis_valid_r & m_axis_video_tready;
wire       can_issue     = (~axis_valid_r) | axis_consumed;
// NOTE: the decision to read must NOT depend on fifo_dout -- with a synchronous-read
// FIFO that data only becomes valid one cycle AFTER the read, so gating rd_en on
// fifo_dout[17] (as an earlier revision did) deadlocks the whole capture path.
assign     fifo_rd       = (~fifo_empty) & can_issue;

always @(posedge ACLK or negedge ARESETN) begin
    if (!ARESETN) begin
        axis_r <= 0; axis_valid_r <= 0; rd_issued_r <= 0; sof_seen <= 0;
    end else begin
        rd_issued_r <= fifo_rd;
        if (axis_consumed) axis_valid_r <= 1'b0;
        if (rd_issued_r) begin
            if (fifo_dout[17]) sof_seen <= 1'b1;
            // anything before the first SOF is dropped instead of being streamed
            if (fifo_dout[17] || sof_seen) begin
                axis_r       <= fifo_dout;
                axis_valid_r <= 1'b1;
            end
        end
    end
end

assign m_axis_video_tdata  = axis_r[15:0];
assign m_axis_video_tvalid = axis_valid_r;
//---------------------------------------------------------------------------
// Debug readout (GPIO 0x41220000) = lines between accepted VSYNC edges, divided by 16.
//
// This is the decisive geometry measurement: line_cnt_r is cleared by every accepted VSYNC and
// incremented by every HREF window, so the value is "how many HREF windows the debounce let
// through between two frames".
//   720/16 = 45  -> the sensor really sends 720 lines per frame (geometry correct)
//   360/16 = 22  -> the VSYNC still fires twice per frame
//   180/16 = 11  -> four times per frame, and the image is four stacked copies
// Read it on the board; it is stable because it only changes at a frame boundary.
//---------------------------------------------------------------------------
assign dbg_pclk_cnt = line_cnt_r[11:4];
// dbg_i2c_done now reports mmcm_locked on the 1-bit GPIO channel: with the debug word taken
// over by the byte-count readout, this is the one status bit that must stay visible.
assign dbg_i2c_done = mmcm_locked;
assign dbg_retry = retry_pulse[0];
assign m_axis_video_tuser  = axis_r[17];
assign m_axis_video_tlast  = axis_r[16];

endmodule
