// (c) Copyright 1995-2026 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:module_ref:ov5640_cam_top:1.0
// IP Revision: 1

(* X_CORE_INFO = "ov5640_cam_top,Vivado 2019.1" *)
(* CHECK_LICENSE_TYPE = "design_1_cam_top_0,ov5640_cam_top,{}" *)
(* CORE_GENERATION_INFO = "design_1_cam_top_0,ov5640_cam_top,{x_ipProduct=Vivado 2019.1,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=ov5640_cam_top,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,FIFO_DEPTH_LOG=10}" *)
(* IP_DEFINITION_SOURCE = "module_ref" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module design_1_cam_top_0 (
  ACLK,
  ARESETN,
  cmos_pclk,
  cmos_data,
  cmos_vsync,
  cmos_href,
  cmos_xclk,
  cmos_scl,
  cmos_sda_i,
  cmos_sda_o,
  cmos_sda_oe,
  cam_cfg_done,
  dbg_pclk_cnt,
  dbg_i2c_done,
  dbg_retry,
  m_axis_video_tdata,
  m_axis_video_tvalid,
  m_axis_video_tuser,
  m_axis_video_tlast,
  m_axis_video_tready
);

(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME ACLK, ASSOCIATED_BUSIF m_axis_video, ASSOCIATED_RESET ARESETN, FREQ_HZ 50000000, PHASE 0.000, CLK_DOMAIN design_1_ps7_0_FCLK_CLK0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ACLK CLK" *)
input wire ACLK;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME ARESETN, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ARESETN RST" *)
input wire ARESETN;
input wire cmos_pclk;
input wire [7 : 0] cmos_data;
input wire cmos_vsync;
input wire cmos_href;
output wire cmos_xclk;
output wire cmos_scl;
input wire cmos_sda_i;
output wire cmos_sda_o;
output wire cmos_sda_oe;
output wire cam_cfg_done;
output wire [7 : 0] dbg_pclk_cnt;
output wire dbg_i2c_done;
output wire dbg_retry;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TDATA" *)
output wire [15 : 0] m_axis_video_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TVALID" *)
output wire m_axis_video_tvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TUSER" *)
output wire m_axis_video_tuser;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TLAST" *)
output wire m_axis_video_tlast;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axis_video, TDATA_NUM_BYTES 2, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 1, FREQ_HZ 50000000, PHASE 0.000, CLK_DOMAIN design_1_ps7_0_FCLK_CLK0, LAYERED_METADATA undef, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_video TREADY" *)
input wire m_axis_video_tready;

  ov5640_cam_top #(
    .FIFO_DEPTH_LOG(10)
  ) inst (
    .ACLK(ACLK),
    .ARESETN(ARESETN),
    .cmos_pclk(cmos_pclk),
    .cmos_data(cmos_data),
    .cmos_vsync(cmos_vsync),
    .cmos_href(cmos_href),
    .cmos_xclk(cmos_xclk),
    .cmos_scl(cmos_scl),
    .cmos_sda_i(cmos_sda_i),
    .cmos_sda_o(cmos_sda_o),
    .cmos_sda_oe(cmos_sda_oe),
    .cam_cfg_done(cam_cfg_done),
    .dbg_pclk_cnt(dbg_pclk_cnt),
    .dbg_i2c_done(dbg_i2c_done),
    .dbg_retry(dbg_retry),
    .m_axis_video_tdata(m_axis_video_tdata),
    .m_axis_video_tvalid(m_axis_video_tvalid),
    .m_axis_video_tuser(m_axis_video_tuser),
    .m_axis_video_tlast(m_axis_video_tlast),
    .m_axis_video_tready(m_axis_video_tready)
  );
endmodule
