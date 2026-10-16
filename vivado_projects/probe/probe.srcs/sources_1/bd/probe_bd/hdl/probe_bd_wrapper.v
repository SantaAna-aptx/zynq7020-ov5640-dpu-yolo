//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
//Date        : Tue Sep 29 18:55:09 2026
//Host        : LAPTOP-7HADCOJD running 64-bit major release  (build 9200)
//Command     : generate_target probe_bd_wrapper.bd
//Design      : probe_bd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module probe_bd_wrapper
   (ACLK,
    ARESETN,
    ch1_drv,
    ch2_i,
    ch2_o,
    ch2_t,
    cnt2_in,
    xclk_en);
  output ACLK;
  output ARESETN;
  input [31:0]ch1_drv;
  input [1:0]ch2_i;
  output [1:0]ch2_o;
  output [1:0]ch2_t;
  input [31:0]cnt2_in;
  output [1:0]xclk_en;

  wire ACLK;
  wire ARESETN;
  wire [31:0]ch1_drv;
  wire [1:0]ch2_i;
  wire [1:0]ch2_o;
  wire [1:0]ch2_t;
  wire [31:0]cnt2_in;
  wire [1:0]xclk_en;

  probe_bd probe_bd_i
       (.ACLK(ACLK),
        .ARESETN(ARESETN),
        .ch1_drv(ch1_drv),
        .ch2_i(ch2_i),
        .ch2_o(ch2_o),
        .ch2_t(ch2_t),
        .cnt2_in(cnt2_in),
        .xclk_en(xclk_en));
endmodule
