//=============================================================================
// frame_writer.v -- pack the OV5640 pixel stream and write it straight into DDR.
//
// Why this exists: the AXI VDMA in this design never accepts our AXIS stream as frames.
// With C_USE_S2MM_FSYNC=2 (s2mm_tuser) it reports "FSZ_MORE / SOF LATE" forever even though
// tuser is generated (simm-verified), wired (dedicated net in the implemented netlist) and
// the control register selects the TUser fsync source (CR bit6). With C_USE_S2MM_FSYNC=0
// (free running) the IP cannot be implemented within timing at all. So we do the one thing
// the camera path actually needs ourselves: take each pixel and store it in the frame buffer.
//
// The stream is fully deterministic (cam_top frames it by counting: tlast on the 1280th
// pixel of a line, one tuser per frame, 720 lines then silence until the next VSYNC), so a
// single 32-bit address counter that is reset by tuser is enough.
//
// Throughput check (this module runs on ACLK = FCLK0 = 50 MHz):
//   pixel rate      30 fps * 1280 * 720 = 27.6 Mpixel/s  -> 0.55 pixel per ACLK cycle
//   this writer     accepts 4 pixels per single-beat AXI write (~4-5 cycles) -> ~0.9/cycle
//   8x margin, so tready rarely deasserts and cam_top's FIFO never overflows.
//
// AXI: single-beat INCR writes of 64 bit (4 pixels), wstrb = 0xFF. SIZE=3, LEN=0, BURST=INCR.
// The master is AXI3-compatible on purpose (len is 4 bits) so it can go straight to the
// Zynq S_AXI_HP port without a protocol converter.
//=============================================================================
`timescale 1ns/1ps
module frame_writer #(
    parameter [31:0] FRAME_BASE = 32'h0800_0000
)(
    input  wire        clk,
    input  wire        rstn,

    // pixel stream from cam_top (AXI4-Stream, 16-bit RGB565, tuser=SOF, tlast=last pixel)
    input  wire [15:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tuser,
    input  wire        s_axis_tlast,
    output wire        s_axis_tready,

    // AXI4 write master (single beat bursts)
    output wire [5:0]  m_axi_awid,
    output wire [31:0] m_axi_awaddr,
    output wire [3:0]  m_axi_awlen,
    output wire [2:0]  m_axi_awsize,
    output wire [1:0]  m_axi_awburst,
    output wire [2:0]  m_axi_awprot,
    output wire        m_axi_awvalid,
    input  wire        m_axi_awready,

    output wire [63:0] m_axi_wdata,
    output wire [7:0]  m_axi_wstrb,
    output wire        m_axi_wlast,
    output wire        m_axi_wvalid,
    input  wire        m_axi_wready,

    input  wire [5:0]  m_axi_bid,
    input  wire [1:0]  m_axi_bresp,
    input  wire        m_axi_bvalid,
    output wire        m_axi_bready,

    // observability (readable from Linux via devmem on the debug GPIO)
    output wire [31:0] frames_written,   // increments on every tuser
    output wire [31:0] words_written,    // increments on every accepted AXI beat
    output wire [31:0] last_addr         // address of the most recent write
);
    //--------------------------------------------------------------- pixel packing
    reg [1:0]  px_idx;          // 0..3 within the current 64-bit word
    reg [63:0] word_r;          // word being assembled
    reg [31:0] addr_r;          // next write address
    reg [31:0] fcnt, wcnt;

    //--------------------------------------------------------------- AXI write FSM
    localparam ST_IDLE = 3'd0,   // collecting 4 pixels
               ST_AW   = 3'd1,   // address handshake
               ST_W    = 3'd2,   // data handshake
               ST_B    = 3'd3;   // write response
    reg [2:0]  st;
    reg [31:0] awaddr_r;
    reg [63:0] wdata_r;

    //-------------------------------------------------------------------------------
    // Geometry. Kept as localparams on purpose: adding module parameters would change the
    // Block Design module reference and force the cell to be re-created in the BD.
    //-------------------------------------------------------------------------------
    localparam integer LINE_PX     = 1280;   // RGB565 pixels per line
    localparam integer FRAME_LINES = 720;

    // Accept a pixel only while assembling a word.
    wire accept = s_axis_tvalid & s_axis_tready;
    assign s_axis_tready = (st == ST_IDLE);

    //-------------------------------------------------------------------------------
    // Row-aligned addressing.
    //
    // The previous revision only honoured tuser and ignored tlast, so the frame buffer was a
    // pure pixel stream: any difference between the camera's real line length and the assumed
    // 1280 pixels sheared the image progressively (measured on hardware as strong diagonal
    // banding). Now tlast advances the write pointer to the start of the next row and tuser
    // returns it to the frame base, so the stored geometry is correct no matter what the
    // camera's exact line length is.
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    // Pure sequential rolling write with a self-generated frame boundary.
    //
    // The buffer is a window of FRAME_LINES rows of the camera's line, stored contiguously. The
    // frame boundary cannot come from the camera: measured on hardware, HREF on this board never
    // falls (the debug counter of HREF falling edges reads 0 continuously), so cam_top can never
    // raise tlast or tuser, and vsync_accept never fires either. The write pointer therefore
    // restarts every REAL_FRAME_PX pixels, which is exactly one frame - that keeps the buffer
    // starting on a frame boundary so the host can render a single clean frame.
    //-------------------------------------------------------------------------------
    localparam integer LINE_BYTES    = LINE_PX * 2;   // nominal 1280 RGB565 pixels = 2560 bytes
    localparam [31:0]  FRAME_END     = FRAME_BASE + (FRAME_LINES * LINE_BYTES) - 8;
    // Measured on hardware: the camera's real line is 1025 pixels, so one 720-line frame is
    // 738,000 pixels. The buffer is 921,600 words, so a frame fits with room to spare.
    localparam [31:0]  REAL_FRAME_PX = 32'd738000;

    reg [31:0] row_addr_r;      // unused now, kept so the debug view still decodes
    reg [9:0]  row_idx_r;       // unused now
    reg [11:0] px_in_row_r;     // unused now
    reg [31:0] px_in_frame_r;   // pixels written since the last self-generated frame start
    reg        word_full_r;     // the 64-bit beat being issued already holds s_axis_tlast

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            px_idx <= 2'd0; word_r <= 64'd0; addr_r <= FRAME_BASE;
            st <= ST_IDLE; awaddr_r <= 32'd0; wdata_r <= 64'd0;
            fcnt <= 32'd0; wcnt <= 32'd0;
            px_in_frame_r <= 32'd0;
            row_addr_r <= FRAME_BASE; row_idx_r <= 10'd0;
            px_in_row_r <= 12'd0; word_full_r <= 1'b0;
        end else begin
            case (st)
                ST_IDLE: begin
                    if (accept) begin
                        // tuser marks the first pixel of a frame, so restart the rolling window
                        // there. That keeps the stored picture a single frame instead of an
                        // arbitrary window across the wrap point, which is what the DPU stage
                        // wants. Only the ADDRESS is reset - the word packing below deliberately
                        // continues, because breaking the 4-pixel grouping would shift every
                        // following pixel by a fraction of a beat.
                        if (s_axis_tuser) begin
                            addr_r <= FRAME_BASE;
                            fcnt   <= fcnt + 32'd1;
                        end
                        begin
                            case (px_idx)
                                2'd0: word_r[15:0]  <= s_axis_tdata;
                                2'd1: word_r[31:16] <= s_axis_tdata;
                                2'd2: word_r[47:32] <= s_axis_tdata;
                                2'd3: word_r[63:48] <= s_axis_tdata;
                            endcase
                            if (px_idx == 2'd3) begin
                                // word complete -> start the AXI write
                                awaddr_r <= addr_r;
                                wdata_r  <= {s_axis_tdata, word_r[47:0]};
                                st       <= ST_AW;
                                word_full_r <= s_axis_tlast;
                                //-------------------------------------------------------------------
                                // Sequential write with a self-generated frame boundary. The next
                                // 64-bit word either continues the current frame or restarts at the
                                // frame base once a whole frame's worth of pixels has gone by.
                                //-------------------------------------------------------------------
                                if (px_in_frame_r == REAL_FRAME_PX - 32'd4) begin
                                    px_in_frame_r <= 32'd0;
                                    addr_r        <= FRAME_BASE;
                                    fcnt          <= fcnt + 32'd1;
                                end else begin
                                    px_in_frame_r <= px_in_frame_r + 32'd4;
                                    addr_r <= (addr_r >= FRAME_END) ? FRAME_BASE : (addr_r + 32'd8);
                                end
                            end
                            px_idx <= px_idx + 2'd1;
                        end
                    end
                end

                ST_AW: if (m_axi_awready) st <= ST_W;

                ST_W: begin
                    if (m_axi_wready) begin
                        st  <= ST_B;
                        wcnt <= wcnt + 32'd1;
                    end
                end

                ST_B: begin
                    // single outstanding write: the response must arrive
                    if (m_axi_bvalid) st <= ST_IDLE;
                end

                default: st <= ST_IDLE;
            endcase
        end
    end

    assign m_axi_awid    = 6'd0;
    assign m_axi_awaddr  = awaddr_r;
    assign m_axi_awlen   = 4'd0;          // single beat
    assign m_axi_awsize  = 3'd3;          // 8 bytes
    assign m_axi_awburst = 2'b01;         // INCR
    assign m_axi_awprot  = 3'b000;
    assign m_axi_awvalid = (st == ST_AW);

    assign m_axi_wdata   = wdata_r;
    assign m_axi_wstrb   = 8'hFF;
    assign m_axi_wlast   = 1'b1;
    assign m_axi_wvalid  = (st == ST_W);
    assign m_axi_bready  = (st == ST_B);

    assign frames_written = fcnt;
    assign words_written  = wcnt;
    assign last_addr      = awaddr_r;
endmodule
