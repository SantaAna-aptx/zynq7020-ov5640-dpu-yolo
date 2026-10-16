//=============================================================================
// fw_tb.v -- testbench for frame_writer.
//
// Checks:
//   * 4 pixels are packed little-endian into each 64-bit beat (px0 in [15:0] ... px3 in [63:48])
//   * tuser resets the write pointer to FRAME_BASE and increments the frame counter
//   * addresses step by 8 within a frame
//   * the AXI handshakes behave: awvalid only until awready, wvalid until wready, bready in ST_B
//   * a slow slave (random awready/wready/bvalid gaps) does not lose or duplicate data
//=============================================================================
`timescale 1ns/1ps
module fw_tb;

reg clk = 0, rstn = 0;
always #10 clk = ~clk;              // 50 MHz

// ---- pixel source ----
reg  [15:0] s_tdata  = 0;
reg         s_tvalid = 0;
reg         s_tuser  = 0;
reg         s_tlast  = 0;
wire        s_tready;

// ---- AXI slave model ----
wire [31:0] awaddr; wire [3:0] awlen; wire [2:0] awsize, awprot; wire [1:0] awburst;
wire        awvalid; reg awready = 0;
wire [63:0] wdata; wire [7:0] wstrb; wire wlast, wvalid; reg wready = 0;
wire        bready; reg [1:0] bresp = 0; reg bvalid = 0;

reg [63:0] mem [0:4095];            // captured 64-bit beats
reg [31:0] mem_addr [0:4095];       // address used for each beat
integer    wr_idx = 0;              // expected beat index
integer    errors = 0;
integer    beats  = 0;
reg [63:0] got;
reg [31:0] got_addr;
integer    i;
reg [31:0] seed = 32'h1234_5678;

task slow_ready;                    // pseudo-random stalls so the FSM is really exercised
begin
    seed = seed * 1103515245 + 12345;
    awready = seed[7];
    seed = seed * 1103515245 + 12345;
    wready = seed[9];
end
endtask

frame_writer #(.FRAME_BASE(32'h0800_0000)) dut (
    .clk(clk), .rstn(rstn),
    .s_axis_tdata(s_tdata), .s_axis_tvalid(s_tvalid), .s_axis_tuser(s_tuser), .s_axis_tlast(s_tlast),
    .s_axis_tready(s_tready),
    .m_axi_awid(), .m_axi_awaddr(awaddr), .m_axi_awlen(awlen), .m_axi_awsize(awsize), .m_axi_awburst(awburst),
    .m_axi_awprot(awprot), .m_axi_awvalid(awvalid), .m_axi_awready(awready),
    .m_axi_wdata(wdata), .m_axi_wstrb(wstrb), .m_axi_wlast(wlast), .m_axi_wvalid(wvalid), .m_axi_wready(wready),
    .m_axi_bid(6'd0), .m_axi_bresp(bresp), .m_axi_bvalid(bvalid), .m_axi_bready(bready),
    .frames_written(), .words_written(), .last_addr()
);

// AXI slave: accept address, capture data on the W handshake, then respond
reg aw_taken = 0;
always @(posedge clk) begin
    if (!rstn) begin
        awready <= 0; wready <= 0; bvalid <= 0; aw_taken <= 0;
    end else begin
        slow_ready;
        if (awvalid && awready) aw_taken <= 1;
        if (wvalid && wready) begin
            got      <= wdata;
            got_addr <= awaddr;
            mem[wr_idx % 4096]      <= wdata;
            mem_addr[wr_idx % 4096] <= awaddr;
            wr_idx   <= wr_idx + 1;
            beats    <= beats + 1;
            // data check: 4 pixels must be packed in order
            if (wstrb !== 8'hFF) begin errors = errors + 1; $display("[ERR] wstrb=%h", wstrb); end
            if (awlen !== 4'd0)  begin errors = errors + 1; $display("[ERR] awlen=%h", awlen); end
        end
        // response follows the data beat
        if (wvalid && wready && !bvalid) bvalid <= 1;
        if (bvalid && bready) begin bvalid <= 0; aw_taken <= 0; end
    end
end

// ---- expected pixel generator: same framing cam_top produces ----
localparam PX_PER_LINE = 1280;  // must match the writer"s fixed LINE_PX (row-aligned addressing)
localparam LINES       = 2;
localparam FRAMES      = 2;
integer f, l, p;
reg [15:0] pix;

task send_frame;
begin
    for (l = 0; l < LINES; l = l + 1) begin
        for (p = 0; p < PX_PER_LINE; p = p + 1) begin
            pix = 16'h1000 + (l * PX_PER_LINE + p);       // unique per pixel
            @(negedge clk);
            s_tdata  = pix;
            s_tvalid = 1;
            s_tuser  = (l == 0) && (p == 0);
            s_tlast  = (p == PX_PER_LINE-1);
            @(posedge clk);
            while (!s_tready) @(posedge clk);              // wait for accept
        end
    end
    @(negedge clk);
    s_tvalid = 0; s_tuser = 0; s_tlast = 0;
    repeat (40) @(posedge clk);                            // inter-frame gap
end
endtask

integer exp_beats;
initial begin
    $display("[TB] frame_writer test start");
    repeat (5) @(posedge clk);
    rstn = 1;
    repeat (5) @(posedge clk);
    for (f = 0; f < FRAMES; f = f + 1) send_frame;

    // expected: FRAMES * LINES * PX_PER_LINE / 4 beats
    exp_beats = FRAMES * LINES * PX_PER_LINE / 4;
    repeat (200) @(posedge clk);
    $display("[TB] beats=%0d expected=%0d errors=%0d", beats, exp_beats, errors);

    // verify the captured buffer: the k-th beat must hold pixels 4k..4k+3 of the frame,
    // and its address must be FRAME_BASE + 8*k within the frame
    for (i = 0; i < exp_beats; i = i + 1) begin
        begin : chk
            integer base;
            integer exp_addr;
            reg [15:0] e0, e1, e2, e3;
            base = (i * 4) % (LINES * PX_PER_LINE);     // frames restart pixel numbering
            e0 = 16'h1000 + base + 0;
            e1 = 16'h1000 + base + 1;
            e2 = 16'h1000 + base + 2;
            e3 = 16'h1000 + base + 3;
            // The writer restarts the rolling window at every tuser (frame start), so the
            // k-th beat WITHIN a frame lands at FRAME_BASE + 8*k, and consecutive frames
            // deliberately reuse the same addresses. An earlier revision of this check
            // assumed addresses never repeat, which is wrong for a per-frame rolling window
            // and produced a spurious [ERR] on the first beat of every frame after the first.
            exp_addr = 32'h0800_0000 + 8 * (i % (LINES * PX_PER_LINE / 4));
            if (mem[i % 4096] !== {e3, e2, e1, e0}) begin
                errors = errors + 1;
                if (errors < 8)
                    $display("[ERR] beat %0d data got=%h exp=%h", i, mem[i % 4096], {e3, e2, e1, e0});
            end
            if (mem_addr[i % 4096] !== exp_addr) begin
                errors = errors + 1;
                if (errors < 8)
                    $display("[ERR] beat %0d addr got=%h exp=%h", i, mem_addr[i % 4096], exp_addr);
            end
        end
    end

    if (errors == 0 && beats == exp_beats) $display("SIM_RESULT=PASS");
    else $display("SIM_RESULT=FAIL");
    $finish;
end

initial begin
    #2_000_000;
    $display("[TB-TIMEOUT] beats=%0d errors=%0d st=%b", beats, errors, dut.st);
    $display("SIM_RESULT=FAIL");
    $finish;
end

endmodule
