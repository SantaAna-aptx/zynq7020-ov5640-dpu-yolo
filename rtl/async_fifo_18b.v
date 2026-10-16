// async_fifo_18b.v — 标准格雷码指针双时钟 FIFO（BRAM 版本）
// v2: 存储阵列强制 BRAM；存储读/指针更新分离到独立 always 块以允许 BRAM 推断。
// 行为与 v1 等价：rd_data 在 rd_en 有效的下一拍更新（同步读），写优先/满空判断不变。
`timescale 1ns/1ns
module async_fifo_18b #(
    parameter DEPTH = 10,                     // 2^DEPTH 深度
    parameter WIDTH = 18
)(
    input  wire            wr_clk,
    input  wire            wr_rst_n,
    input  wire            wr_en,
    input  wire [WIDTH-1:0] wr_data,
    output wire            wr_full,
    input  wire            rd_clk,
    input  wire            rd_rst_n,
    input  wire            rd_en,
    output reg  [WIDTH-1:0] rd_data,
    output wire            rd_empty
);
localparam PTR_W = DEPTH + 1;

(* ram_style = "block" *)
reg [WIDTH-1:0] mem [0:(1<<DEPTH)-1];
reg [PTR_W-1:0] wptr, wptr_g, rptr_sync1, rptr_sync2;
reg [PTR_W-1:0] rptr, rptr_g, wptr_sync1, wptr_sync2;
wire wr_ok  = wr_en && !wr_full;
wire rd_ok  = rd_en && !rd_empty;

// 存储写口（独立块，无复位 —— BRAM 不需要）
always @(posedge wr_clk)
    if (wr_ok)
        mem[wptr[DEPTH-1:0]] <= wr_data;

// 存储读口（独立块，同步读 = BRAM 输出寄存器；无复位）
always @(posedge rd_clk)
    if (rd_ok)
        rd_data <= mem[rptr[DEPTH-1:0]];

// 写指针（格雷码）
always @(posedge wr_clk or negedge wr_rst_n)
    if (!wr_rst_n) begin wptr <= 0; wptr_g <= 0; end
    else if (wr_ok) begin
        wptr   <= wptr + 1'b1;
        wptr_g <= (wptr + 1'b1) ^ ((wptr + 1'b1) >> 1);
    end

// 读指针（格雷码）
always @(posedge rd_clk or negedge rd_rst_n)
    if (!rd_rst_n) begin rptr <= 0; rptr_g <= 0; end
    else if (rd_ok) begin
        rptr   <= rptr + 1'b1;
        rptr_g <= (rptr + 1'b1) ^ ((rptr + 1'b1) >> 1);
    end

// 跨域同步
// v3 FIX: the two synchroniser chains were clocked by the WRONG domains. `rptr_sync`
// must be clocked by wr_clk (the read pointer is brought into the write domain so that
// wr_full can be computed there) and `wptr_sync` by rd_clk (the write pointer comes into
// the read domain for rd_empty). As written before, wr_full was computed combinationally
// from a read-domain register and drove the BRAM write-enable:
//   * it created a raw clk_fpga_0 -> cmos_pclk_clk path (WNS -9.2 ns, the only failing
//     clock pair in the design), and
//   * the full/empty flags were sampled across domains with no synchroniser at all,
//     which corrupts the flags and silently drops pixels in hardware.
always @(posedge wr_clk or negedge wr_rst_n)
    if (!wr_rst_n) {rptr_sync2, rptr_sync1} <= 0;
    else           {rptr_sync2, rptr_sync1} <= {rptr_sync1, rptr_g};
always @(posedge rd_clk or negedge rd_rst_n)
    if (!rd_rst_n) {wptr_sync2, wptr_sync1} <= 0;
    else           {wptr_sync2, wptr_sync1} <= {wptr_sync1, wptr_g};

assign wr_full  = (wptr_g[PTR_W-1:PTR_W-2] == ~rptr_sync2[PTR_W-1:PTR_W-2]) &&
                  (wptr_g[PTR_W-3:0]      == rptr_sync2[PTR_W-3:0]);
assign rd_empty = (rptr_g == wptr_sync2);

endmodule
