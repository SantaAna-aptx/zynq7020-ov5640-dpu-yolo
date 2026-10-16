//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
//Date        : Thu Oct 15 22:38:54 2026
//Host        : LAPTOP-7HADCOJD running 64-bit major release  (build 9200)
//Command     : generate_target design_1.bd
//Design      : design_1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=design_1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=20,numReposBlks=15,numNonXlnxBlks=0,numHierBlks=5,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=3,numPkgbdBlks=0,bdsource=USER,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "design_1.hwdef" *) 
module design_1
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    cmos_data,
    cmos_href,
    cmos_pclk,
    cmos_scl,
    cmos_sda,
    cmos_vsync,
    cmos_xclk);
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR ADDR" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME DDR, AXI_ARBITRATION_SCHEME TDM, BURST_LENGTH 8, CAN_DEBUG false, CAS_LATENCY 11, CAS_WRITE_LATENCY 11, CS_ENABLED true, DATA_MASK_ENABLED true, DATA_WIDTH 8, MEMORY_TYPE COMPONENTS, MEM_ADDR_MAP ROW_COLUMN_BANK, SLOT Single, TIMEPERIOD_PS 1250" *) inout [14:0]DDR_addr;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR BA" *) inout [2:0]DDR_ba;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CAS_N" *) inout DDR_cas_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CK_N" *) inout DDR_ck_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CK_P" *) inout DDR_ck_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CKE" *) inout DDR_cke;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR CS_N" *) inout DDR_cs_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DM" *) inout [3:0]DDR_dm;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DQ" *) inout [31:0]DDR_dq;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DQS_N" *) inout [3:0]DDR_dqs_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR DQS_P" *) inout [3:0]DDR_dqs_p;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR ODT" *) inout DDR_odt;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR RAS_N" *) inout DDR_ras_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR RESET_N" *) inout DDR_reset_n;
  (* X_INTERFACE_INFO = "xilinx.com:interface:ddrx:1.0 DDR WE_N" *) inout DDR_we_n;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO DDR_VRN" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIXED_IO, CAN_DEBUG false" *) inout FIXED_IO_ddr_vrn;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO DDR_VRP" *) inout FIXED_IO_ddr_vrp;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO MIO" *) inout [53:0]FIXED_IO_mio;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO PS_CLK" *) inout FIXED_IO_ps_clk;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO PS_PORB" *) inout FIXED_IO_ps_porb;
  (* X_INTERFACE_INFO = "xilinx.com:display_processing_system7:fixedio:1.0 FIXED_IO PS_SRSTB" *) inout FIXED_IO_ps_srstb;
  input [7:0]cmos_data;
  input cmos_href;
  input cmos_pclk;
  output cmos_scl;
  inout cmos_sda;
  input cmos_vsync;
  output cmos_xclk;

  wire Net;
  wire [31:0]axi_pc_vdma_M_AXI_AWADDR;
  wire [1:0]axi_pc_vdma_M_AXI_AWBURST;
  wire [5:0]axi_pc_vdma_M_AXI_AWID;
  wire [3:0]axi_pc_vdma_M_AXI_AWLEN;
  wire [2:0]axi_pc_vdma_M_AXI_AWPROT;
  wire axi_pc_vdma_M_AXI_AWREADY;
  wire [2:0]axi_pc_vdma_M_AXI_AWSIZE;
  wire axi_pc_vdma_M_AXI_AWVALID;
  wire [5:0]axi_pc_vdma_M_AXI_BID;
  wire axi_pc_vdma_M_AXI_BREADY;
  wire [1:0]axi_pc_vdma_M_AXI_BRESP;
  wire axi_pc_vdma_M_AXI_BVALID;
  wire [63:0]axi_pc_vdma_M_AXI_WDATA;
  wire axi_pc_vdma_M_AXI_WLAST;
  wire axi_pc_vdma_M_AXI_WREADY;
  wire [7:0]axi_pc_vdma_M_AXI_WSTRB;
  wire axi_pc_vdma_M_AXI_WVALID;
  wire [31:0]axi_periph_M00_AXI_ARADDR;
  wire [1:0]axi_periph_M00_AXI_ARBURST;
  wire [3:0]axi_periph_M00_AXI_ARCACHE;
  wire [11:0]axi_periph_M00_AXI_ARID;
  wire [3:0]axi_periph_M00_AXI_ARLEN;
  wire [1:0]axi_periph_M00_AXI_ARLOCK;
  wire [2:0]axi_periph_M00_AXI_ARPROT;
  wire [3:0]axi_periph_M00_AXI_ARQOS;
  wire axi_periph_M00_AXI_ARREADY;
  wire [2:0]axi_periph_M00_AXI_ARSIZE;
  wire axi_periph_M00_AXI_ARVALID;
  wire [31:0]axi_periph_M00_AXI_AWADDR;
  wire [1:0]axi_periph_M00_AXI_AWBURST;
  wire [3:0]axi_periph_M00_AXI_AWCACHE;
  wire [11:0]axi_periph_M00_AXI_AWID;
  wire [3:0]axi_periph_M00_AXI_AWLEN;
  wire [1:0]axi_periph_M00_AXI_AWLOCK;
  wire [2:0]axi_periph_M00_AXI_AWPROT;
  wire [3:0]axi_periph_M00_AXI_AWQOS;
  wire axi_periph_M00_AXI_AWREADY;
  wire [2:0]axi_periph_M00_AXI_AWSIZE;
  wire axi_periph_M00_AXI_AWVALID;
  wire [11:0]axi_periph_M00_AXI_BID;
  wire axi_periph_M00_AXI_BREADY;
  wire [1:0]axi_periph_M00_AXI_BRESP;
  wire axi_periph_M00_AXI_BVALID;
  wire [31:0]axi_periph_M00_AXI_RDATA;
  wire [11:0]axi_periph_M00_AXI_RID;
  wire axi_periph_M00_AXI_RLAST;
  wire axi_periph_M00_AXI_RREADY;
  wire [1:0]axi_periph_M00_AXI_RRESP;
  wire axi_periph_M00_AXI_RVALID;
  wire [31:0]axi_periph_M00_AXI_WDATA;
  wire [11:0]axi_periph_M00_AXI_WID;
  wire axi_periph_M00_AXI_WLAST;
  wire axi_periph_M00_AXI_WREADY;
  wire [3:0]axi_periph_M00_AXI_WSTRB;
  wire axi_periph_M00_AXI_WVALID;
  wire [31:0]axi_periph_M02_AXI_ARADDR;
  wire axi_periph_M02_AXI_ARREADY;
  wire axi_periph_M02_AXI_ARVALID;
  wire [31:0]axi_periph_M02_AXI_AWADDR;
  wire axi_periph_M02_AXI_AWREADY;
  wire axi_periph_M02_AXI_AWVALID;
  wire axi_periph_M02_AXI_BREADY;
  wire [1:0]axi_periph_M02_AXI_BRESP;
  wire axi_periph_M02_AXI_BVALID;
  wire [31:0]axi_periph_M02_AXI_RDATA;
  wire axi_periph_M02_AXI_RREADY;
  wire [1:0]axi_periph_M02_AXI_RRESP;
  wire axi_periph_M02_AXI_RVALID;
  wire [31:0]axi_periph_M02_AXI_WDATA;
  wire axi_periph_M02_AXI_WREADY;
  wire [3:0]axi_periph_M02_AXI_WSTRB;
  wire axi_periph_M02_AXI_WVALID;
  wire [31:0]axi_smc_instr_M00_AXI_ARADDR;
  wire [1:0]axi_smc_instr_M00_AXI_ARBURST;
  wire [3:0]axi_smc_instr_M00_AXI_ARCACHE;
  wire [3:0]axi_smc_instr_M00_AXI_ARLEN;
  wire [1:0]axi_smc_instr_M00_AXI_ARLOCK;
  wire [2:0]axi_smc_instr_M00_AXI_ARPROT;
  wire [3:0]axi_smc_instr_M00_AXI_ARQOS;
  wire axi_smc_instr_M00_AXI_ARREADY;
  wire [2:0]axi_smc_instr_M00_AXI_ARSIZE;
  wire axi_smc_instr_M00_AXI_ARVALID;
  wire [31:0]axi_smc_instr_M00_AXI_AWADDR;
  wire [1:0]axi_smc_instr_M00_AXI_AWBURST;
  wire [3:0]axi_smc_instr_M00_AXI_AWCACHE;
  wire [3:0]axi_smc_instr_M00_AXI_AWLEN;
  wire [1:0]axi_smc_instr_M00_AXI_AWLOCK;
  wire [2:0]axi_smc_instr_M00_AXI_AWPROT;
  wire [3:0]axi_smc_instr_M00_AXI_AWQOS;
  wire axi_smc_instr_M00_AXI_AWREADY;
  wire [2:0]axi_smc_instr_M00_AXI_AWSIZE;
  wire axi_smc_instr_M00_AXI_AWVALID;
  wire axi_smc_instr_M00_AXI_BREADY;
  wire [1:0]axi_smc_instr_M00_AXI_BRESP;
  wire axi_smc_instr_M00_AXI_BVALID;
  wire [63:0]axi_smc_instr_M00_AXI_RDATA;
  wire axi_smc_instr_M00_AXI_RLAST;
  wire axi_smc_instr_M00_AXI_RREADY;
  wire [1:0]axi_smc_instr_M00_AXI_RRESP;
  wire axi_smc_instr_M00_AXI_RVALID;
  wire [63:0]axi_smc_instr_M00_AXI_WDATA;
  wire axi_smc_instr_M00_AXI_WLAST;
  wire axi_smc_instr_M00_AXI_WREADY;
  wire [7:0]axi_smc_instr_M00_AXI_WSTRB;
  wire axi_smc_instr_M00_AXI_WVALID;
  wire cam_top_cmos_scl;
  wire cam_top_cmos_sda_o;
  wire cam_top_cmos_sda_oe;
  wire cam_top_cmos_xclk;
  wire cam_top_dbg_i2c_done;
  wire [7:0]cam_top_dbg_pclk_cnt;
  wire [15:0]cam_top_m_axis_video_TDATA;
  wire cam_top_m_axis_video_TLAST;
  wire cam_top_m_axis_video_TREADY;
  wire cam_top_m_axis_video_TVALID;
  wire cam_top_m_axis_video_tuser;
  wire clk_wiz_0_clk_out2;
  wire clk_wiz_0_clk_out3;
  wire [7:0]cmos_data_1;
  wire cmos_href_1;
  wire cmos_pclk_1;
  wire cmos_vsync_1;
  wire [39:0]dpu_eu_0_DPU0_M_AXI_DATA0_ARADDR;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA0_ARBURST;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_DATA0_ARCACHE;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA0_ARID;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_DATA0_ARLEN;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA0_ARLOCK;
  wire [2:0]dpu_eu_0_DPU0_M_AXI_DATA0_ARPROT;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_DATA0_ARQOS;
  wire dpu_eu_0_DPU0_M_AXI_DATA0_ARREADY;
  wire [2:0]dpu_eu_0_DPU0_M_AXI_DATA0_ARSIZE;
  wire dpu_eu_0_DPU0_M_AXI_DATA0_ARVALID;
  wire [39:0]dpu_eu_0_DPU0_M_AXI_DATA0_AWADDR;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA0_AWBURST;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_DATA0_AWCACHE;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA0_AWID;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_DATA0_AWLEN;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA0_AWLOCK;
  wire [2:0]dpu_eu_0_DPU0_M_AXI_DATA0_AWPROT;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_DATA0_AWQOS;
  wire dpu_eu_0_DPU0_M_AXI_DATA0_AWREADY;
  wire [2:0]dpu_eu_0_DPU0_M_AXI_DATA0_AWSIZE;
  wire dpu_eu_0_DPU0_M_AXI_DATA0_AWVALID;
  wire [5:0]dpu_eu_0_DPU0_M_AXI_DATA0_BID;
  wire dpu_eu_0_DPU0_M_AXI_DATA0_BREADY;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA0_BRESP;
  wire dpu_eu_0_DPU0_M_AXI_DATA0_BVALID;
  wire [63:0]dpu_eu_0_DPU0_M_AXI_DATA0_RDATA;
  wire [5:0]dpu_eu_0_DPU0_M_AXI_DATA0_RID;
  wire dpu_eu_0_DPU0_M_AXI_DATA0_RLAST;
  wire dpu_eu_0_DPU0_M_AXI_DATA0_RREADY;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA0_RRESP;
  wire dpu_eu_0_DPU0_M_AXI_DATA0_RVALID;
  wire [63:0]dpu_eu_0_DPU0_M_AXI_DATA0_WDATA;
  wire [5:0]dpu_eu_0_DPU0_M_AXI_DATA0_WID;
  wire dpu_eu_0_DPU0_M_AXI_DATA0_WLAST;
  wire dpu_eu_0_DPU0_M_AXI_DATA0_WREADY;
  wire [7:0]dpu_eu_0_DPU0_M_AXI_DATA0_WSTRB;
  wire dpu_eu_0_DPU0_M_AXI_DATA0_WVALID;
  wire [39:0]dpu_eu_0_DPU0_M_AXI_DATA1_ARADDR;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA1_ARBURST;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_DATA1_ARCACHE;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA1_ARID;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_DATA1_ARLEN;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA1_ARLOCK;
  wire [2:0]dpu_eu_0_DPU0_M_AXI_DATA1_ARPROT;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_DATA1_ARQOS;
  wire dpu_eu_0_DPU0_M_AXI_DATA1_ARREADY;
  wire [2:0]dpu_eu_0_DPU0_M_AXI_DATA1_ARSIZE;
  wire dpu_eu_0_DPU0_M_AXI_DATA1_ARVALID;
  wire [39:0]dpu_eu_0_DPU0_M_AXI_DATA1_AWADDR;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA1_AWBURST;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_DATA1_AWCACHE;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA1_AWID;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_DATA1_AWLEN;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA1_AWLOCK;
  wire [2:0]dpu_eu_0_DPU0_M_AXI_DATA1_AWPROT;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_DATA1_AWQOS;
  wire dpu_eu_0_DPU0_M_AXI_DATA1_AWREADY;
  wire [2:0]dpu_eu_0_DPU0_M_AXI_DATA1_AWSIZE;
  wire dpu_eu_0_DPU0_M_AXI_DATA1_AWVALID;
  wire [5:0]dpu_eu_0_DPU0_M_AXI_DATA1_BID;
  wire dpu_eu_0_DPU0_M_AXI_DATA1_BREADY;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA1_BRESP;
  wire dpu_eu_0_DPU0_M_AXI_DATA1_BVALID;
  wire [63:0]dpu_eu_0_DPU0_M_AXI_DATA1_RDATA;
  wire [5:0]dpu_eu_0_DPU0_M_AXI_DATA1_RID;
  wire dpu_eu_0_DPU0_M_AXI_DATA1_RLAST;
  wire dpu_eu_0_DPU0_M_AXI_DATA1_RREADY;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_DATA1_RRESP;
  wire dpu_eu_0_DPU0_M_AXI_DATA1_RVALID;
  wire [63:0]dpu_eu_0_DPU0_M_AXI_DATA1_WDATA;
  wire [5:0]dpu_eu_0_DPU0_M_AXI_DATA1_WID;
  wire dpu_eu_0_DPU0_M_AXI_DATA1_WLAST;
  wire dpu_eu_0_DPU0_M_AXI_DATA1_WREADY;
  wire [7:0]dpu_eu_0_DPU0_M_AXI_DATA1_WSTRB;
  wire dpu_eu_0_DPU0_M_AXI_DATA1_WVALID;
  wire [39:0]dpu_eu_0_DPU0_M_AXI_INSTR_ARADDR;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_INSTR_ARBURST;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_INSTR_ARCACHE;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_INSTR_ARID;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_INSTR_ARLEN;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_INSTR_ARLOCK;
  wire [2:0]dpu_eu_0_DPU0_M_AXI_INSTR_ARPROT;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_INSTR_ARQOS;
  wire dpu_eu_0_DPU0_M_AXI_INSTR_ARREADY;
  wire [2:0]dpu_eu_0_DPU0_M_AXI_INSTR_ARSIZE;
  wire dpu_eu_0_DPU0_M_AXI_INSTR_ARVALID;
  wire [39:0]dpu_eu_0_DPU0_M_AXI_INSTR_AWADDR;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_INSTR_AWBURST;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_INSTR_AWCACHE;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_INSTR_AWID;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_INSTR_AWLEN;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_INSTR_AWLOCK;
  wire [2:0]dpu_eu_0_DPU0_M_AXI_INSTR_AWPROT;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_INSTR_AWQOS;
  wire dpu_eu_0_DPU0_M_AXI_INSTR_AWREADY;
  wire [2:0]dpu_eu_0_DPU0_M_AXI_INSTR_AWSIZE;
  wire dpu_eu_0_DPU0_M_AXI_INSTR_AWVALID;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_INSTR_BID;
  wire dpu_eu_0_DPU0_M_AXI_INSTR_BREADY;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_INSTR_BRESP;
  wire dpu_eu_0_DPU0_M_AXI_INSTR_BVALID;
  wire [31:0]dpu_eu_0_DPU0_M_AXI_INSTR_RDATA;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_INSTR_RID;
  wire dpu_eu_0_DPU0_M_AXI_INSTR_RLAST;
  wire dpu_eu_0_DPU0_M_AXI_INSTR_RREADY;
  wire [1:0]dpu_eu_0_DPU0_M_AXI_INSTR_RRESP;
  wire dpu_eu_0_DPU0_M_AXI_INSTR_RVALID;
  wire [31:0]dpu_eu_0_DPU0_M_AXI_INSTR_WDATA;
  wire [5:0]dpu_eu_0_DPU0_M_AXI_INSTR_WID;
  wire dpu_eu_0_DPU0_M_AXI_INSTR_WLAST;
  wire dpu_eu_0_DPU0_M_AXI_INSTR_WREADY;
  wire [3:0]dpu_eu_0_DPU0_M_AXI_INSTR_WSTRB;
  wire dpu_eu_0_DPU0_M_AXI_INSTR_WVALID;
  wire [0:0]dpu_eu_0_dpu_interrupt;
  wire [14:0]ps7_DDR_ADDR;
  wire [2:0]ps7_DDR_BA;
  wire ps7_DDR_CAS_N;
  wire ps7_DDR_CKE;
  wire ps7_DDR_CK_N;
  wire ps7_DDR_CK_P;
  wire ps7_DDR_CS_N;
  wire [3:0]ps7_DDR_DM;
  wire [31:0]ps7_DDR_DQ;
  wire [3:0]ps7_DDR_DQS_N;
  wire [3:0]ps7_DDR_DQS_P;
  wire ps7_DDR_ODT;
  wire ps7_DDR_RAS_N;
  wire ps7_DDR_RESET_N;
  wire ps7_DDR_WE_N;
  wire ps7_FCLK_CLK0;
  wire ps7_FCLK_RESET0_N;
  wire ps7_FIXED_IO_DDR_VRN;
  wire ps7_FIXED_IO_DDR_VRP;
  wire [53:0]ps7_FIXED_IO_MIO;
  wire ps7_FIXED_IO_PS_CLK;
  wire ps7_FIXED_IO_PS_PORB;
  wire ps7_FIXED_IO_PS_SRSTB;
  wire [31:0]ps7_M_AXI_GP0_ARADDR;
  wire [1:0]ps7_M_AXI_GP0_ARBURST;
  wire [3:0]ps7_M_AXI_GP0_ARCACHE;
  wire [11:0]ps7_M_AXI_GP0_ARID;
  wire [3:0]ps7_M_AXI_GP0_ARLEN;
  wire [1:0]ps7_M_AXI_GP0_ARLOCK;
  wire [2:0]ps7_M_AXI_GP0_ARPROT;
  wire [3:0]ps7_M_AXI_GP0_ARQOS;
  wire ps7_M_AXI_GP0_ARREADY;
  wire [2:0]ps7_M_AXI_GP0_ARSIZE;
  wire ps7_M_AXI_GP0_ARVALID;
  wire [31:0]ps7_M_AXI_GP0_AWADDR;
  wire [1:0]ps7_M_AXI_GP0_AWBURST;
  wire [3:0]ps7_M_AXI_GP0_AWCACHE;
  wire [11:0]ps7_M_AXI_GP0_AWID;
  wire [3:0]ps7_M_AXI_GP0_AWLEN;
  wire [1:0]ps7_M_AXI_GP0_AWLOCK;
  wire [2:0]ps7_M_AXI_GP0_AWPROT;
  wire [3:0]ps7_M_AXI_GP0_AWQOS;
  wire ps7_M_AXI_GP0_AWREADY;
  wire [2:0]ps7_M_AXI_GP0_AWSIZE;
  wire ps7_M_AXI_GP0_AWVALID;
  wire [11:0]ps7_M_AXI_GP0_BID;
  wire ps7_M_AXI_GP0_BREADY;
  wire [1:0]ps7_M_AXI_GP0_BRESP;
  wire ps7_M_AXI_GP0_BVALID;
  wire [31:0]ps7_M_AXI_GP0_RDATA;
  wire [11:0]ps7_M_AXI_GP0_RID;
  wire ps7_M_AXI_GP0_RLAST;
  wire ps7_M_AXI_GP0_RREADY;
  wire [1:0]ps7_M_AXI_GP0_RRESP;
  wire ps7_M_AXI_GP0_RVALID;
  wire [31:0]ps7_M_AXI_GP0_WDATA;
  wire [11:0]ps7_M_AXI_GP0_WID;
  wire ps7_M_AXI_GP0_WLAST;
  wire ps7_M_AXI_GP0_WREADY;
  wire [3:0]ps7_M_AXI_GP0_WSTRB;
  wire ps7_M_AXI_GP0_WVALID;
  wire [0:0]rst_100_peripheral_aresetn;
  wire [0:0]rst_150_peripheral_aresetn;
  wire [0:0]rst_300_peripheral_aresetn;
  wire [0:0]rst_cam_peripheral_aresetn;
  wire sda_iobuf_O;

  assign cmos_data_1 = cmos_data[7:0];
  assign cmos_href_1 = cmos_href;
  assign cmos_pclk_1 = cmos_pclk;
  assign cmos_scl = cam_top_cmos_scl;
  assign cmos_vsync_1 = cmos_vsync;
  assign cmos_xclk = cam_top_cmos_xclk;
  design_1_axi_periph_0 axi_periph
       (.ACLK(ps7_FCLK_CLK0),
        .ARESETN(rst_cam_peripheral_aresetn),
        .M00_ACLK(clk_wiz_0_clk_out2),
        .M00_ARESETN(rst_150_peripheral_aresetn),
        .M00_AXI_araddr(axi_periph_M00_AXI_ARADDR),
        .M00_AXI_arburst(axi_periph_M00_AXI_ARBURST),
        .M00_AXI_arcache(axi_periph_M00_AXI_ARCACHE),
        .M00_AXI_arid(axi_periph_M00_AXI_ARID),
        .M00_AXI_arlen(axi_periph_M00_AXI_ARLEN),
        .M00_AXI_arlock(axi_periph_M00_AXI_ARLOCK),
        .M00_AXI_arprot(axi_periph_M00_AXI_ARPROT),
        .M00_AXI_arqos(axi_periph_M00_AXI_ARQOS),
        .M00_AXI_arready(axi_periph_M00_AXI_ARREADY),
        .M00_AXI_arsize(axi_periph_M00_AXI_ARSIZE),
        .M00_AXI_arvalid(axi_periph_M00_AXI_ARVALID),
        .M00_AXI_awaddr(axi_periph_M00_AXI_AWADDR),
        .M00_AXI_awburst(axi_periph_M00_AXI_AWBURST),
        .M00_AXI_awcache(axi_periph_M00_AXI_AWCACHE),
        .M00_AXI_awid(axi_periph_M00_AXI_AWID),
        .M00_AXI_awlen(axi_periph_M00_AXI_AWLEN),
        .M00_AXI_awlock(axi_periph_M00_AXI_AWLOCK),
        .M00_AXI_awprot(axi_periph_M00_AXI_AWPROT),
        .M00_AXI_awqos(axi_periph_M00_AXI_AWQOS),
        .M00_AXI_awready(axi_periph_M00_AXI_AWREADY),
        .M00_AXI_awsize(axi_periph_M00_AXI_AWSIZE),
        .M00_AXI_awvalid(axi_periph_M00_AXI_AWVALID),
        .M00_AXI_bid(axi_periph_M00_AXI_BID),
        .M00_AXI_bready(axi_periph_M00_AXI_BREADY),
        .M00_AXI_bresp(axi_periph_M00_AXI_BRESP),
        .M00_AXI_bvalid(axi_periph_M00_AXI_BVALID),
        .M00_AXI_rdata(axi_periph_M00_AXI_RDATA),
        .M00_AXI_rid(axi_periph_M00_AXI_RID),
        .M00_AXI_rlast(axi_periph_M00_AXI_RLAST),
        .M00_AXI_rready(axi_periph_M00_AXI_RREADY),
        .M00_AXI_rresp(axi_periph_M00_AXI_RRESP),
        .M00_AXI_rvalid(axi_periph_M00_AXI_RVALID),
        .M00_AXI_wdata(axi_periph_M00_AXI_WDATA),
        .M00_AXI_wid(axi_periph_M00_AXI_WID),
        .M00_AXI_wlast(axi_periph_M00_AXI_WLAST),
        .M00_AXI_wready(axi_periph_M00_AXI_WREADY),
        .M00_AXI_wstrb(axi_periph_M00_AXI_WSTRB),
        .M00_AXI_wvalid(axi_periph_M00_AXI_WVALID),
        .M01_ACLK(ps7_FCLK_CLK0),
        .M01_ARESETN(rst_cam_peripheral_aresetn),
        .M01_AXI_arready(1'b0),
        .M01_AXI_awready(1'b0),
        .M01_AXI_bid(1'b0),
        .M01_AXI_bresp(1'b0),
        .M01_AXI_bvalid(1'b0),
        .M01_AXI_rdata(1'b0),
        .M01_AXI_rid(1'b0),
        .M01_AXI_rlast(1'b0),
        .M01_AXI_rresp(1'b0),
        .M01_AXI_rvalid(1'b0),
        .M01_AXI_wready(1'b0),
        .M02_ACLK(ps7_FCLK_CLK0),
        .M02_ARESETN(rst_cam_peripheral_aresetn),
        .M02_AXI_araddr(axi_periph_M02_AXI_ARADDR),
        .M02_AXI_arready(axi_periph_M02_AXI_ARREADY),
        .M02_AXI_arvalid(axi_periph_M02_AXI_ARVALID),
        .M02_AXI_awaddr(axi_periph_M02_AXI_AWADDR),
        .M02_AXI_awready(axi_periph_M02_AXI_AWREADY),
        .M02_AXI_awvalid(axi_periph_M02_AXI_AWVALID),
        .M02_AXI_bready(axi_periph_M02_AXI_BREADY),
        .M02_AXI_bresp(axi_periph_M02_AXI_BRESP),
        .M02_AXI_bvalid(axi_periph_M02_AXI_BVALID),
        .M02_AXI_rdata(axi_periph_M02_AXI_RDATA),
        .M02_AXI_rready(axi_periph_M02_AXI_RREADY),
        .M02_AXI_rresp(axi_periph_M02_AXI_RRESP),
        .M02_AXI_rvalid(axi_periph_M02_AXI_RVALID),
        .M02_AXI_wdata(axi_periph_M02_AXI_WDATA),
        .M02_AXI_wready(axi_periph_M02_AXI_WREADY),
        .M02_AXI_wstrb(axi_periph_M02_AXI_WSTRB),
        .M02_AXI_wvalid(axi_periph_M02_AXI_WVALID),
        .S00_ACLK(ps7_FCLK_CLK0),
        .S00_ARESETN(rst_cam_peripheral_aresetn),
        .S00_AXI_araddr(ps7_M_AXI_GP0_ARADDR),
        .S00_AXI_arburst(ps7_M_AXI_GP0_ARBURST),
        .S00_AXI_arcache(ps7_M_AXI_GP0_ARCACHE),
        .S00_AXI_arid(ps7_M_AXI_GP0_ARID),
        .S00_AXI_arlen(ps7_M_AXI_GP0_ARLEN),
        .S00_AXI_arlock(ps7_M_AXI_GP0_ARLOCK),
        .S00_AXI_arprot(ps7_M_AXI_GP0_ARPROT),
        .S00_AXI_arqos(ps7_M_AXI_GP0_ARQOS),
        .S00_AXI_arready(ps7_M_AXI_GP0_ARREADY),
        .S00_AXI_arsize(ps7_M_AXI_GP0_ARSIZE),
        .S00_AXI_arvalid(ps7_M_AXI_GP0_ARVALID),
        .S00_AXI_awaddr(ps7_M_AXI_GP0_AWADDR),
        .S00_AXI_awburst(ps7_M_AXI_GP0_AWBURST),
        .S00_AXI_awcache(ps7_M_AXI_GP0_AWCACHE),
        .S00_AXI_awid(ps7_M_AXI_GP0_AWID),
        .S00_AXI_awlen(ps7_M_AXI_GP0_AWLEN),
        .S00_AXI_awlock(ps7_M_AXI_GP0_AWLOCK),
        .S00_AXI_awprot(ps7_M_AXI_GP0_AWPROT),
        .S00_AXI_awqos(ps7_M_AXI_GP0_AWQOS),
        .S00_AXI_awready(ps7_M_AXI_GP0_AWREADY),
        .S00_AXI_awsize(ps7_M_AXI_GP0_AWSIZE),
        .S00_AXI_awvalid(ps7_M_AXI_GP0_AWVALID),
        .S00_AXI_bid(ps7_M_AXI_GP0_BID),
        .S00_AXI_bready(ps7_M_AXI_GP0_BREADY),
        .S00_AXI_bresp(ps7_M_AXI_GP0_BRESP),
        .S00_AXI_bvalid(ps7_M_AXI_GP0_BVALID),
        .S00_AXI_rdata(ps7_M_AXI_GP0_RDATA),
        .S00_AXI_rid(ps7_M_AXI_GP0_RID),
        .S00_AXI_rlast(ps7_M_AXI_GP0_RLAST),
        .S00_AXI_rready(ps7_M_AXI_GP0_RREADY),
        .S00_AXI_rresp(ps7_M_AXI_GP0_RRESP),
        .S00_AXI_rvalid(ps7_M_AXI_GP0_RVALID),
        .S00_AXI_wdata(ps7_M_AXI_GP0_WDATA),
        .S00_AXI_wid(ps7_M_AXI_GP0_WID),
        .S00_AXI_wlast(ps7_M_AXI_GP0_WLAST),
        .S00_AXI_wready(ps7_M_AXI_GP0_WREADY),
        .S00_AXI_wstrb(ps7_M_AXI_GP0_WSTRB),
        .S00_AXI_wvalid(ps7_M_AXI_GP0_WVALID));
  design_1_axi_smc_instr_0 axi_smc_instr
       (.M00_AXI_araddr(axi_smc_instr_M00_AXI_ARADDR),
        .M00_AXI_arburst(axi_smc_instr_M00_AXI_ARBURST),
        .M00_AXI_arcache(axi_smc_instr_M00_AXI_ARCACHE),
        .M00_AXI_arlen(axi_smc_instr_M00_AXI_ARLEN),
        .M00_AXI_arlock(axi_smc_instr_M00_AXI_ARLOCK),
        .M00_AXI_arprot(axi_smc_instr_M00_AXI_ARPROT),
        .M00_AXI_arqos(axi_smc_instr_M00_AXI_ARQOS),
        .M00_AXI_arready(axi_smc_instr_M00_AXI_ARREADY),
        .M00_AXI_arsize(axi_smc_instr_M00_AXI_ARSIZE),
        .M00_AXI_arvalid(axi_smc_instr_M00_AXI_ARVALID),
        .M00_AXI_awaddr(axi_smc_instr_M00_AXI_AWADDR),
        .M00_AXI_awburst(axi_smc_instr_M00_AXI_AWBURST),
        .M00_AXI_awcache(axi_smc_instr_M00_AXI_AWCACHE),
        .M00_AXI_awlen(axi_smc_instr_M00_AXI_AWLEN),
        .M00_AXI_awlock(axi_smc_instr_M00_AXI_AWLOCK),
        .M00_AXI_awprot(axi_smc_instr_M00_AXI_AWPROT),
        .M00_AXI_awqos(axi_smc_instr_M00_AXI_AWQOS),
        .M00_AXI_awready(axi_smc_instr_M00_AXI_AWREADY),
        .M00_AXI_awsize(axi_smc_instr_M00_AXI_AWSIZE),
        .M00_AXI_awvalid(axi_smc_instr_M00_AXI_AWVALID),
        .M00_AXI_bready(axi_smc_instr_M00_AXI_BREADY),
        .M00_AXI_bresp(axi_smc_instr_M00_AXI_BRESP),
        .M00_AXI_bvalid(axi_smc_instr_M00_AXI_BVALID),
        .M00_AXI_rdata(axi_smc_instr_M00_AXI_RDATA),
        .M00_AXI_rlast(axi_smc_instr_M00_AXI_RLAST),
        .M00_AXI_rready(axi_smc_instr_M00_AXI_RREADY),
        .M00_AXI_rresp(axi_smc_instr_M00_AXI_RRESP),
        .M00_AXI_rvalid(axi_smc_instr_M00_AXI_RVALID),
        .M00_AXI_wdata(axi_smc_instr_M00_AXI_WDATA),
        .M00_AXI_wlast(axi_smc_instr_M00_AXI_WLAST),
        .M00_AXI_wready(axi_smc_instr_M00_AXI_WREADY),
        .M00_AXI_wstrb(axi_smc_instr_M00_AXI_WSTRB),
        .M00_AXI_wvalid(axi_smc_instr_M00_AXI_WVALID),
        .S00_AXI_araddr(dpu_eu_0_DPU0_M_AXI_INSTR_ARADDR),
        .S00_AXI_arburst(dpu_eu_0_DPU0_M_AXI_INSTR_ARBURST),
        .S00_AXI_arcache(dpu_eu_0_DPU0_M_AXI_INSTR_ARCACHE),
        .S00_AXI_arid(dpu_eu_0_DPU0_M_AXI_INSTR_ARID),
        .S00_AXI_arlen(dpu_eu_0_DPU0_M_AXI_INSTR_ARLEN),
        .S00_AXI_arlock(dpu_eu_0_DPU0_M_AXI_INSTR_ARLOCK),
        .S00_AXI_arprot(dpu_eu_0_DPU0_M_AXI_INSTR_ARPROT),
        .S00_AXI_arqos(dpu_eu_0_DPU0_M_AXI_INSTR_ARQOS),
        .S00_AXI_arready(dpu_eu_0_DPU0_M_AXI_INSTR_ARREADY),
        .S00_AXI_arsize(dpu_eu_0_DPU0_M_AXI_INSTR_ARSIZE),
        .S00_AXI_arvalid(dpu_eu_0_DPU0_M_AXI_INSTR_ARVALID),
        .S00_AXI_awaddr(dpu_eu_0_DPU0_M_AXI_INSTR_AWADDR),
        .S00_AXI_awburst(dpu_eu_0_DPU0_M_AXI_INSTR_AWBURST),
        .S00_AXI_awcache(dpu_eu_0_DPU0_M_AXI_INSTR_AWCACHE),
        .S00_AXI_awid(dpu_eu_0_DPU0_M_AXI_INSTR_AWID),
        .S00_AXI_awlen(dpu_eu_0_DPU0_M_AXI_INSTR_AWLEN),
        .S00_AXI_awlock(dpu_eu_0_DPU0_M_AXI_INSTR_AWLOCK),
        .S00_AXI_awprot(dpu_eu_0_DPU0_M_AXI_INSTR_AWPROT),
        .S00_AXI_awqos(dpu_eu_0_DPU0_M_AXI_INSTR_AWQOS),
        .S00_AXI_awready(dpu_eu_0_DPU0_M_AXI_INSTR_AWREADY),
        .S00_AXI_awsize(dpu_eu_0_DPU0_M_AXI_INSTR_AWSIZE),
        .S00_AXI_awvalid(dpu_eu_0_DPU0_M_AXI_INSTR_AWVALID),
        .S00_AXI_bid(dpu_eu_0_DPU0_M_AXI_INSTR_BID),
        .S00_AXI_bready(dpu_eu_0_DPU0_M_AXI_INSTR_BREADY),
        .S00_AXI_bresp(dpu_eu_0_DPU0_M_AXI_INSTR_BRESP),
        .S00_AXI_bvalid(dpu_eu_0_DPU0_M_AXI_INSTR_BVALID),
        .S00_AXI_rdata(dpu_eu_0_DPU0_M_AXI_INSTR_RDATA),
        .S00_AXI_rid(dpu_eu_0_DPU0_M_AXI_INSTR_RID),
        .S00_AXI_rlast(dpu_eu_0_DPU0_M_AXI_INSTR_RLAST),
        .S00_AXI_rready(dpu_eu_0_DPU0_M_AXI_INSTR_RREADY),
        .S00_AXI_rresp(dpu_eu_0_DPU0_M_AXI_INSTR_RRESP),
        .S00_AXI_rvalid(dpu_eu_0_DPU0_M_AXI_INSTR_RVALID),
        .S00_AXI_wdata(dpu_eu_0_DPU0_M_AXI_INSTR_WDATA),
        .S00_AXI_wid(dpu_eu_0_DPU0_M_AXI_INSTR_WID[1:0]),
        .S00_AXI_wlast(dpu_eu_0_DPU0_M_AXI_INSTR_WLAST),
        .S00_AXI_wready(dpu_eu_0_DPU0_M_AXI_INSTR_WREADY),
        .S00_AXI_wstrb(dpu_eu_0_DPU0_M_AXI_INSTR_WSTRB),
        .S00_AXI_wvalid(dpu_eu_0_DPU0_M_AXI_INSTR_WVALID),
        .aclk(clk_wiz_0_clk_out2),
        .aresetn(rst_150_peripheral_aresetn));
  design_1_cam_top_0 cam_top
       (.ACLK(ps7_FCLK_CLK0),
        .ARESETN(rst_cam_peripheral_aresetn),
        .cmos_data(cmos_data_1),
        .cmos_href(cmos_href_1),
        .cmos_pclk(cmos_pclk_1),
        .cmos_scl(cam_top_cmos_scl),
        .cmos_sda_i(sda_iobuf_O),
        .cmos_sda_o(cam_top_cmos_sda_o),
        .cmos_sda_oe(cam_top_cmos_sda_oe),
        .cmos_vsync(cmos_vsync_1),
        .cmos_xclk(cam_top_cmos_xclk),
        .dbg_i2c_done(cam_top_dbg_i2c_done),
        .dbg_pclk_cnt(cam_top_dbg_pclk_cnt),
        .m_axis_video_tdata(cam_top_m_axis_video_TDATA),
        .m_axis_video_tlast(cam_top_m_axis_video_TLAST),
        .m_axis_video_tready(cam_top_m_axis_video_TREADY),
        .m_axis_video_tuser(cam_top_m_axis_video_tuser),
        .m_axis_video_tvalid(cam_top_m_axis_video_TVALID));
  design_1_clk_wiz_0_0 clk_wiz_0
       (.clk_in1(ps7_FCLK_CLK0),
        .clk_out2(clk_wiz_0_clk_out2),
        .clk_out3(clk_wiz_0_clk_out3),
        .reset(1'b0));
  design_1_dbg_gpio_0 dbg_gpio
       (.gpio2_io_i(cam_top_dbg_i2c_done),
        .gpio_io_i(cam_top_dbg_pclk_cnt),
        .s_axi_aclk(ps7_FCLK_CLK0),
        .s_axi_araddr(axi_periph_M02_AXI_ARADDR[8:0]),
        .s_axi_aresetn(rst_cam_peripheral_aresetn),
        .s_axi_arready(axi_periph_M02_AXI_ARREADY),
        .s_axi_arvalid(axi_periph_M02_AXI_ARVALID),
        .s_axi_awaddr(axi_periph_M02_AXI_AWADDR[8:0]),
        .s_axi_awready(axi_periph_M02_AXI_AWREADY),
        .s_axi_awvalid(axi_periph_M02_AXI_AWVALID),
        .s_axi_bready(axi_periph_M02_AXI_BREADY),
        .s_axi_bresp(axi_periph_M02_AXI_BRESP),
        .s_axi_bvalid(axi_periph_M02_AXI_BVALID),
        .s_axi_rdata(axi_periph_M02_AXI_RDATA),
        .s_axi_rready(axi_periph_M02_AXI_RREADY),
        .s_axi_rresp(axi_periph_M02_AXI_RRESP),
        .s_axi_rvalid(axi_periph_M02_AXI_RVALID),
        .s_axi_wdata(axi_periph_M02_AXI_WDATA),
        .s_axi_wready(axi_periph_M02_AXI_WREADY),
        .s_axi_wstrb(axi_periph_M02_AXI_WSTRB),
        .s_axi_wvalid(axi_periph_M02_AXI_WVALID));
  design_1_dpu_eu_0_0 dpu_eu_0
       (.dpu0_m_axi_data0_araddr(dpu_eu_0_DPU0_M_AXI_DATA0_ARADDR),
        .dpu0_m_axi_data0_arburst(dpu_eu_0_DPU0_M_AXI_DATA0_ARBURST),
        .dpu0_m_axi_data0_arcache(dpu_eu_0_DPU0_M_AXI_DATA0_ARCACHE),
        .dpu0_m_axi_data0_arid(dpu_eu_0_DPU0_M_AXI_DATA0_ARID),
        .dpu0_m_axi_data0_arlen(dpu_eu_0_DPU0_M_AXI_DATA0_ARLEN),
        .dpu0_m_axi_data0_arlock(dpu_eu_0_DPU0_M_AXI_DATA0_ARLOCK),
        .dpu0_m_axi_data0_arprot(dpu_eu_0_DPU0_M_AXI_DATA0_ARPROT),
        .dpu0_m_axi_data0_arqos(dpu_eu_0_DPU0_M_AXI_DATA0_ARQOS),
        .dpu0_m_axi_data0_arready(dpu_eu_0_DPU0_M_AXI_DATA0_ARREADY),
        .dpu0_m_axi_data0_arsize(dpu_eu_0_DPU0_M_AXI_DATA0_ARSIZE),
        .dpu0_m_axi_data0_arvalid(dpu_eu_0_DPU0_M_AXI_DATA0_ARVALID),
        .dpu0_m_axi_data0_awaddr(dpu_eu_0_DPU0_M_AXI_DATA0_AWADDR),
        .dpu0_m_axi_data0_awburst(dpu_eu_0_DPU0_M_AXI_DATA0_AWBURST),
        .dpu0_m_axi_data0_awcache(dpu_eu_0_DPU0_M_AXI_DATA0_AWCACHE),
        .dpu0_m_axi_data0_awid(dpu_eu_0_DPU0_M_AXI_DATA0_AWID),
        .dpu0_m_axi_data0_awlen(dpu_eu_0_DPU0_M_AXI_DATA0_AWLEN),
        .dpu0_m_axi_data0_awlock(dpu_eu_0_DPU0_M_AXI_DATA0_AWLOCK),
        .dpu0_m_axi_data0_awprot(dpu_eu_0_DPU0_M_AXI_DATA0_AWPROT),
        .dpu0_m_axi_data0_awqos(dpu_eu_0_DPU0_M_AXI_DATA0_AWQOS),
        .dpu0_m_axi_data0_awready(dpu_eu_0_DPU0_M_AXI_DATA0_AWREADY),
        .dpu0_m_axi_data0_awsize(dpu_eu_0_DPU0_M_AXI_DATA0_AWSIZE),
        .dpu0_m_axi_data0_awvalid(dpu_eu_0_DPU0_M_AXI_DATA0_AWVALID),
        .dpu0_m_axi_data0_bid(dpu_eu_0_DPU0_M_AXI_DATA0_BID),
        .dpu0_m_axi_data0_bready(dpu_eu_0_DPU0_M_AXI_DATA0_BREADY),
        .dpu0_m_axi_data0_bresp(dpu_eu_0_DPU0_M_AXI_DATA0_BRESP),
        .dpu0_m_axi_data0_bvalid(dpu_eu_0_DPU0_M_AXI_DATA0_BVALID),
        .dpu0_m_axi_data0_rdata(dpu_eu_0_DPU0_M_AXI_DATA0_RDATA),
        .dpu0_m_axi_data0_rid(dpu_eu_0_DPU0_M_AXI_DATA0_RID),
        .dpu0_m_axi_data0_rlast(dpu_eu_0_DPU0_M_AXI_DATA0_RLAST),
        .dpu0_m_axi_data0_rready(dpu_eu_0_DPU0_M_AXI_DATA0_RREADY),
        .dpu0_m_axi_data0_rresp(dpu_eu_0_DPU0_M_AXI_DATA0_RRESP),
        .dpu0_m_axi_data0_rvalid(dpu_eu_0_DPU0_M_AXI_DATA0_RVALID),
        .dpu0_m_axi_data0_wdata(dpu_eu_0_DPU0_M_AXI_DATA0_WDATA),
        .dpu0_m_axi_data0_wid(dpu_eu_0_DPU0_M_AXI_DATA0_WID),
        .dpu0_m_axi_data0_wlast(dpu_eu_0_DPU0_M_AXI_DATA0_WLAST),
        .dpu0_m_axi_data0_wready(dpu_eu_0_DPU0_M_AXI_DATA0_WREADY),
        .dpu0_m_axi_data0_wstrb(dpu_eu_0_DPU0_M_AXI_DATA0_WSTRB),
        .dpu0_m_axi_data0_wvalid(dpu_eu_0_DPU0_M_AXI_DATA0_WVALID),
        .dpu0_m_axi_data1_araddr(dpu_eu_0_DPU0_M_AXI_DATA1_ARADDR),
        .dpu0_m_axi_data1_arburst(dpu_eu_0_DPU0_M_AXI_DATA1_ARBURST),
        .dpu0_m_axi_data1_arcache(dpu_eu_0_DPU0_M_AXI_DATA1_ARCACHE),
        .dpu0_m_axi_data1_arid(dpu_eu_0_DPU0_M_AXI_DATA1_ARID),
        .dpu0_m_axi_data1_arlen(dpu_eu_0_DPU0_M_AXI_DATA1_ARLEN),
        .dpu0_m_axi_data1_arlock(dpu_eu_0_DPU0_M_AXI_DATA1_ARLOCK),
        .dpu0_m_axi_data1_arprot(dpu_eu_0_DPU0_M_AXI_DATA1_ARPROT),
        .dpu0_m_axi_data1_arqos(dpu_eu_0_DPU0_M_AXI_DATA1_ARQOS),
        .dpu0_m_axi_data1_arready(dpu_eu_0_DPU0_M_AXI_DATA1_ARREADY),
        .dpu0_m_axi_data1_arsize(dpu_eu_0_DPU0_M_AXI_DATA1_ARSIZE),
        .dpu0_m_axi_data1_arvalid(dpu_eu_0_DPU0_M_AXI_DATA1_ARVALID),
        .dpu0_m_axi_data1_awaddr(dpu_eu_0_DPU0_M_AXI_DATA1_AWADDR),
        .dpu0_m_axi_data1_awburst(dpu_eu_0_DPU0_M_AXI_DATA1_AWBURST),
        .dpu0_m_axi_data1_awcache(dpu_eu_0_DPU0_M_AXI_DATA1_AWCACHE),
        .dpu0_m_axi_data1_awid(dpu_eu_0_DPU0_M_AXI_DATA1_AWID),
        .dpu0_m_axi_data1_awlen(dpu_eu_0_DPU0_M_AXI_DATA1_AWLEN),
        .dpu0_m_axi_data1_awlock(dpu_eu_0_DPU0_M_AXI_DATA1_AWLOCK),
        .dpu0_m_axi_data1_awprot(dpu_eu_0_DPU0_M_AXI_DATA1_AWPROT),
        .dpu0_m_axi_data1_awqos(dpu_eu_0_DPU0_M_AXI_DATA1_AWQOS),
        .dpu0_m_axi_data1_awready(dpu_eu_0_DPU0_M_AXI_DATA1_AWREADY),
        .dpu0_m_axi_data1_awsize(dpu_eu_0_DPU0_M_AXI_DATA1_AWSIZE),
        .dpu0_m_axi_data1_awvalid(dpu_eu_0_DPU0_M_AXI_DATA1_AWVALID),
        .dpu0_m_axi_data1_bid(dpu_eu_0_DPU0_M_AXI_DATA1_BID),
        .dpu0_m_axi_data1_bready(dpu_eu_0_DPU0_M_AXI_DATA1_BREADY),
        .dpu0_m_axi_data1_bresp(dpu_eu_0_DPU0_M_AXI_DATA1_BRESP),
        .dpu0_m_axi_data1_bvalid(dpu_eu_0_DPU0_M_AXI_DATA1_BVALID),
        .dpu0_m_axi_data1_rdata(dpu_eu_0_DPU0_M_AXI_DATA1_RDATA),
        .dpu0_m_axi_data1_rid(dpu_eu_0_DPU0_M_AXI_DATA1_RID),
        .dpu0_m_axi_data1_rlast(dpu_eu_0_DPU0_M_AXI_DATA1_RLAST),
        .dpu0_m_axi_data1_rready(dpu_eu_0_DPU0_M_AXI_DATA1_RREADY),
        .dpu0_m_axi_data1_rresp(dpu_eu_0_DPU0_M_AXI_DATA1_RRESP),
        .dpu0_m_axi_data1_rvalid(dpu_eu_0_DPU0_M_AXI_DATA1_RVALID),
        .dpu0_m_axi_data1_wdata(dpu_eu_0_DPU0_M_AXI_DATA1_WDATA),
        .dpu0_m_axi_data1_wid(dpu_eu_0_DPU0_M_AXI_DATA1_WID),
        .dpu0_m_axi_data1_wlast(dpu_eu_0_DPU0_M_AXI_DATA1_WLAST),
        .dpu0_m_axi_data1_wready(dpu_eu_0_DPU0_M_AXI_DATA1_WREADY),
        .dpu0_m_axi_data1_wstrb(dpu_eu_0_DPU0_M_AXI_DATA1_WSTRB),
        .dpu0_m_axi_data1_wvalid(dpu_eu_0_DPU0_M_AXI_DATA1_WVALID),
        .dpu0_m_axi_instr_araddr(dpu_eu_0_DPU0_M_AXI_INSTR_ARADDR),
        .dpu0_m_axi_instr_arburst(dpu_eu_0_DPU0_M_AXI_INSTR_ARBURST),
        .dpu0_m_axi_instr_arcache(dpu_eu_0_DPU0_M_AXI_INSTR_ARCACHE),
        .dpu0_m_axi_instr_arid(dpu_eu_0_DPU0_M_AXI_INSTR_ARID),
        .dpu0_m_axi_instr_arlen(dpu_eu_0_DPU0_M_AXI_INSTR_ARLEN),
        .dpu0_m_axi_instr_arlock(dpu_eu_0_DPU0_M_AXI_INSTR_ARLOCK),
        .dpu0_m_axi_instr_arprot(dpu_eu_0_DPU0_M_AXI_INSTR_ARPROT),
        .dpu0_m_axi_instr_arqos(dpu_eu_0_DPU0_M_AXI_INSTR_ARQOS),
        .dpu0_m_axi_instr_arready(dpu_eu_0_DPU0_M_AXI_INSTR_ARREADY),
        .dpu0_m_axi_instr_arsize(dpu_eu_0_DPU0_M_AXI_INSTR_ARSIZE),
        .dpu0_m_axi_instr_arvalid(dpu_eu_0_DPU0_M_AXI_INSTR_ARVALID),
        .dpu0_m_axi_instr_awaddr(dpu_eu_0_DPU0_M_AXI_INSTR_AWADDR),
        .dpu0_m_axi_instr_awburst(dpu_eu_0_DPU0_M_AXI_INSTR_AWBURST),
        .dpu0_m_axi_instr_awcache(dpu_eu_0_DPU0_M_AXI_INSTR_AWCACHE),
        .dpu0_m_axi_instr_awid(dpu_eu_0_DPU0_M_AXI_INSTR_AWID),
        .dpu0_m_axi_instr_awlen(dpu_eu_0_DPU0_M_AXI_INSTR_AWLEN),
        .dpu0_m_axi_instr_awlock(dpu_eu_0_DPU0_M_AXI_INSTR_AWLOCK),
        .dpu0_m_axi_instr_awprot(dpu_eu_0_DPU0_M_AXI_INSTR_AWPROT),
        .dpu0_m_axi_instr_awqos(dpu_eu_0_DPU0_M_AXI_INSTR_AWQOS),
        .dpu0_m_axi_instr_awready(dpu_eu_0_DPU0_M_AXI_INSTR_AWREADY),
        .dpu0_m_axi_instr_awsize(dpu_eu_0_DPU0_M_AXI_INSTR_AWSIZE),
        .dpu0_m_axi_instr_awvalid(dpu_eu_0_DPU0_M_AXI_INSTR_AWVALID),
        .dpu0_m_axi_instr_bid({1'b0,1'b0,1'b0,1'b0,dpu_eu_0_DPU0_M_AXI_INSTR_BID}),
        .dpu0_m_axi_instr_bready(dpu_eu_0_DPU0_M_AXI_INSTR_BREADY),
        .dpu0_m_axi_instr_bresp(dpu_eu_0_DPU0_M_AXI_INSTR_BRESP),
        .dpu0_m_axi_instr_bvalid(dpu_eu_0_DPU0_M_AXI_INSTR_BVALID),
        .dpu0_m_axi_instr_rdata(dpu_eu_0_DPU0_M_AXI_INSTR_RDATA),
        .dpu0_m_axi_instr_rid({1'b0,1'b0,1'b0,1'b0,dpu_eu_0_DPU0_M_AXI_INSTR_RID}),
        .dpu0_m_axi_instr_rlast(dpu_eu_0_DPU0_M_AXI_INSTR_RLAST),
        .dpu0_m_axi_instr_rready(dpu_eu_0_DPU0_M_AXI_INSTR_RREADY),
        .dpu0_m_axi_instr_rresp(dpu_eu_0_DPU0_M_AXI_INSTR_RRESP),
        .dpu0_m_axi_instr_rvalid(dpu_eu_0_DPU0_M_AXI_INSTR_RVALID),
        .dpu0_m_axi_instr_wdata(dpu_eu_0_DPU0_M_AXI_INSTR_WDATA),
        .dpu0_m_axi_instr_wid(dpu_eu_0_DPU0_M_AXI_INSTR_WID),
        .dpu0_m_axi_instr_wlast(dpu_eu_0_DPU0_M_AXI_INSTR_WLAST),
        .dpu0_m_axi_instr_wready(dpu_eu_0_DPU0_M_AXI_INSTR_WREADY),
        .dpu0_m_axi_instr_wstrb(dpu_eu_0_DPU0_M_AXI_INSTR_WSTRB),
        .dpu0_m_axi_instr_wvalid(dpu_eu_0_DPU0_M_AXI_INSTR_WVALID),
        .dpu_2x_clk(clk_wiz_0_clk_out3),
        .dpu_2x_resetn(rst_300_peripheral_aresetn),
        .dpu_interrupt(dpu_eu_0_dpu_interrupt),
        .m_axi_dpu_aclk(clk_wiz_0_clk_out2),
        .m_axi_dpu_aresetn(rst_150_peripheral_aresetn),
        .s_axi_araddr(axi_periph_M00_AXI_ARADDR),
        .s_axi_arburst(axi_periph_M00_AXI_ARBURST),
        .s_axi_arcache(axi_periph_M00_AXI_ARCACHE),
        .s_axi_arid(axi_periph_M00_AXI_ARID),
        .s_axi_arlen(axi_periph_M00_AXI_ARLEN),
        .s_axi_arlock(axi_periph_M00_AXI_ARLOCK),
        .s_axi_arprot(axi_periph_M00_AXI_ARPROT),
        .s_axi_arqos(axi_periph_M00_AXI_ARQOS),
        .s_axi_arready(axi_periph_M00_AXI_ARREADY),
        .s_axi_arregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arsize(axi_periph_M00_AXI_ARSIZE),
        .s_axi_arvalid(axi_periph_M00_AXI_ARVALID),
        .s_axi_awaddr(axi_periph_M00_AXI_AWADDR),
        .s_axi_awburst(axi_periph_M00_AXI_AWBURST),
        .s_axi_awcache(axi_periph_M00_AXI_AWCACHE),
        .s_axi_awid(axi_periph_M00_AXI_AWID),
        .s_axi_awlen(axi_periph_M00_AXI_AWLEN),
        .s_axi_awlock(axi_periph_M00_AXI_AWLOCK),
        .s_axi_awprot(axi_periph_M00_AXI_AWPROT),
        .s_axi_awqos(axi_periph_M00_AXI_AWQOS),
        .s_axi_awready(axi_periph_M00_AXI_AWREADY),
        .s_axi_awregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awsize(axi_periph_M00_AXI_AWSIZE),
        .s_axi_awvalid(axi_periph_M00_AXI_AWVALID),
        .s_axi_bid(axi_periph_M00_AXI_BID),
        .s_axi_bready(axi_periph_M00_AXI_BREADY),
        .s_axi_bresp(axi_periph_M00_AXI_BRESP),
        .s_axi_bvalid(axi_periph_M00_AXI_BVALID),
        .s_axi_rdata(axi_periph_M00_AXI_RDATA),
        .s_axi_rid(axi_periph_M00_AXI_RID),
        .s_axi_rlast(axi_periph_M00_AXI_RLAST),
        .s_axi_rready(axi_periph_M00_AXI_RREADY),
        .s_axi_rresp(axi_periph_M00_AXI_RRESP),
        .s_axi_rvalid(axi_periph_M00_AXI_RVALID),
        .s_axi_wdata(axi_periph_M00_AXI_WDATA),
        .s_axi_wid(axi_periph_M00_AXI_WID),
        .s_axi_wlast(axi_periph_M00_AXI_WLAST),
        .s_axi_wready(axi_periph_M00_AXI_WREADY),
        .s_axi_wstrb(axi_periph_M00_AXI_WSTRB),
        .s_axi_wvalid(axi_periph_M00_AXI_WVALID));
  design_1_frame_writer_0_0 frame_writer_0
       (.clk(ps7_FCLK_CLK0),
        .m_axi_awaddr(axi_pc_vdma_M_AXI_AWADDR),
        .m_axi_awburst(axi_pc_vdma_M_AXI_AWBURST),
        .m_axi_awid(axi_pc_vdma_M_AXI_AWID),
        .m_axi_awlen(axi_pc_vdma_M_AXI_AWLEN),
        .m_axi_awprot(axi_pc_vdma_M_AXI_AWPROT),
        .m_axi_awready(axi_pc_vdma_M_AXI_AWREADY),
        .m_axi_awsize(axi_pc_vdma_M_AXI_AWSIZE),
        .m_axi_awvalid(axi_pc_vdma_M_AXI_AWVALID),
        .m_axi_bid(axi_pc_vdma_M_AXI_BID),
        .m_axi_bready(axi_pc_vdma_M_AXI_BREADY),
        .m_axi_bresp(axi_pc_vdma_M_AXI_BRESP),
        .m_axi_bvalid(axi_pc_vdma_M_AXI_BVALID),
        .m_axi_wdata(axi_pc_vdma_M_AXI_WDATA),
        .m_axi_wlast(axi_pc_vdma_M_AXI_WLAST),
        .m_axi_wready(axi_pc_vdma_M_AXI_WREADY),
        .m_axi_wstrb(axi_pc_vdma_M_AXI_WSTRB),
        .m_axi_wvalid(axi_pc_vdma_M_AXI_WVALID),
        .rstn(rst_cam_peripheral_aresetn),
        .s_axis_tdata(cam_top_m_axis_video_TDATA),
        .s_axis_tlast(cam_top_m_axis_video_TLAST),
        .s_axis_tready(cam_top_m_axis_video_TREADY),
        .s_axis_tuser(1'b0),
        .s_axis_tvalid(cam_top_m_axis_video_TVALID));
  design_1_ps7_0 ps7
       (.DDR_Addr(DDR_addr[14:0]),
        .DDR_BankAddr(DDR_ba[2:0]),
        .DDR_CAS_n(DDR_cas_n),
        .DDR_CKE(DDR_cke),
        .DDR_CS_n(DDR_cs_n),
        .DDR_Clk(DDR_ck_p),
        .DDR_Clk_n(DDR_ck_n),
        .DDR_DM(DDR_dm[3:0]),
        .DDR_DQ(DDR_dq[31:0]),
        .DDR_DQS(DDR_dqs_p[3:0]),
        .DDR_DQS_n(DDR_dqs_n[3:0]),
        .DDR_DRSTB(DDR_reset_n),
        .DDR_ODT(DDR_odt),
        .DDR_RAS_n(DDR_ras_n),
        .DDR_VRN(FIXED_IO_ddr_vrn),
        .DDR_VRP(FIXED_IO_ddr_vrp),
        .DDR_WEB(DDR_we_n),
        .ENET0_EXT_INTIN(1'b0),
        .ENET0_GMII_COL(1'b0),
        .ENET0_GMII_CRS(1'b0),
        .ENET0_GMII_RXD({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .ENET0_GMII_RX_CLK(1'b0),
        .ENET0_GMII_RX_DV(1'b0),
        .ENET0_GMII_RX_ER(1'b0),
        .ENET0_GMII_TX_CLK(1'b0),
        .FCLK_CLK0(ps7_FCLK_CLK0),
        .FCLK_RESET0_N(ps7_FCLK_RESET0_N),
        .IRQ_F2P(dpu_eu_0_dpu_interrupt),
        .MIO(FIXED_IO_mio[53:0]),
        .M_AXI_GP0_ACLK(ps7_FCLK_CLK0),
        .M_AXI_GP0_ARADDR(ps7_M_AXI_GP0_ARADDR),
        .M_AXI_GP0_ARBURST(ps7_M_AXI_GP0_ARBURST),
        .M_AXI_GP0_ARCACHE(ps7_M_AXI_GP0_ARCACHE),
        .M_AXI_GP0_ARID(ps7_M_AXI_GP0_ARID),
        .M_AXI_GP0_ARLEN(ps7_M_AXI_GP0_ARLEN),
        .M_AXI_GP0_ARLOCK(ps7_M_AXI_GP0_ARLOCK),
        .M_AXI_GP0_ARPROT(ps7_M_AXI_GP0_ARPROT),
        .M_AXI_GP0_ARQOS(ps7_M_AXI_GP0_ARQOS),
        .M_AXI_GP0_ARREADY(ps7_M_AXI_GP0_ARREADY),
        .M_AXI_GP0_ARSIZE(ps7_M_AXI_GP0_ARSIZE),
        .M_AXI_GP0_ARVALID(ps7_M_AXI_GP0_ARVALID),
        .M_AXI_GP0_AWADDR(ps7_M_AXI_GP0_AWADDR),
        .M_AXI_GP0_AWBURST(ps7_M_AXI_GP0_AWBURST),
        .M_AXI_GP0_AWCACHE(ps7_M_AXI_GP0_AWCACHE),
        .M_AXI_GP0_AWID(ps7_M_AXI_GP0_AWID),
        .M_AXI_GP0_AWLEN(ps7_M_AXI_GP0_AWLEN),
        .M_AXI_GP0_AWLOCK(ps7_M_AXI_GP0_AWLOCK),
        .M_AXI_GP0_AWPROT(ps7_M_AXI_GP0_AWPROT),
        .M_AXI_GP0_AWQOS(ps7_M_AXI_GP0_AWQOS),
        .M_AXI_GP0_AWREADY(ps7_M_AXI_GP0_AWREADY),
        .M_AXI_GP0_AWSIZE(ps7_M_AXI_GP0_AWSIZE),
        .M_AXI_GP0_AWVALID(ps7_M_AXI_GP0_AWVALID),
        .M_AXI_GP0_BID(ps7_M_AXI_GP0_BID),
        .M_AXI_GP0_BREADY(ps7_M_AXI_GP0_BREADY),
        .M_AXI_GP0_BRESP(ps7_M_AXI_GP0_BRESP),
        .M_AXI_GP0_BVALID(ps7_M_AXI_GP0_BVALID),
        .M_AXI_GP0_RDATA(ps7_M_AXI_GP0_RDATA),
        .M_AXI_GP0_RID(ps7_M_AXI_GP0_RID),
        .M_AXI_GP0_RLAST(ps7_M_AXI_GP0_RLAST),
        .M_AXI_GP0_RREADY(ps7_M_AXI_GP0_RREADY),
        .M_AXI_GP0_RRESP(ps7_M_AXI_GP0_RRESP),
        .M_AXI_GP0_RVALID(ps7_M_AXI_GP0_RVALID),
        .M_AXI_GP0_WDATA(ps7_M_AXI_GP0_WDATA),
        .M_AXI_GP0_WID(ps7_M_AXI_GP0_WID),
        .M_AXI_GP0_WLAST(ps7_M_AXI_GP0_WLAST),
        .M_AXI_GP0_WREADY(ps7_M_AXI_GP0_WREADY),
        .M_AXI_GP0_WSTRB(ps7_M_AXI_GP0_WSTRB),
        .M_AXI_GP0_WVALID(ps7_M_AXI_GP0_WVALID),
        .PS_CLK(FIXED_IO_ps_clk),
        .PS_PORB(FIXED_IO_ps_porb),
        .PS_SRSTB(FIXED_IO_ps_srstb),
        .S_AXI_HP0_ACLK(clk_wiz_0_clk_out2),
        .S_AXI_HP0_ARADDR(dpu_eu_0_DPU0_M_AXI_DATA0_ARADDR[31:0]),
        .S_AXI_HP0_ARBURST(dpu_eu_0_DPU0_M_AXI_DATA0_ARBURST),
        .S_AXI_HP0_ARCACHE(dpu_eu_0_DPU0_M_AXI_DATA0_ARCACHE),
        .S_AXI_HP0_ARID({1'b0,1'b0,1'b0,1'b0,dpu_eu_0_DPU0_M_AXI_DATA0_ARID}),
        .S_AXI_HP0_ARLEN(dpu_eu_0_DPU0_M_AXI_DATA0_ARLEN),
        .S_AXI_HP0_ARLOCK(dpu_eu_0_DPU0_M_AXI_DATA0_ARLOCK),
        .S_AXI_HP0_ARPROT(dpu_eu_0_DPU0_M_AXI_DATA0_ARPROT),
        .S_AXI_HP0_ARQOS(dpu_eu_0_DPU0_M_AXI_DATA0_ARQOS),
        .S_AXI_HP0_ARREADY(dpu_eu_0_DPU0_M_AXI_DATA0_ARREADY),
        .S_AXI_HP0_ARSIZE(dpu_eu_0_DPU0_M_AXI_DATA0_ARSIZE),
        .S_AXI_HP0_ARVALID(dpu_eu_0_DPU0_M_AXI_DATA0_ARVALID),
        .S_AXI_HP0_AWADDR(dpu_eu_0_DPU0_M_AXI_DATA0_AWADDR[31:0]),
        .S_AXI_HP0_AWBURST(dpu_eu_0_DPU0_M_AXI_DATA0_AWBURST),
        .S_AXI_HP0_AWCACHE(dpu_eu_0_DPU0_M_AXI_DATA0_AWCACHE),
        .S_AXI_HP0_AWID({1'b0,1'b0,1'b0,1'b0,dpu_eu_0_DPU0_M_AXI_DATA0_AWID}),
        .S_AXI_HP0_AWLEN(dpu_eu_0_DPU0_M_AXI_DATA0_AWLEN),
        .S_AXI_HP0_AWLOCK(dpu_eu_0_DPU0_M_AXI_DATA0_AWLOCK),
        .S_AXI_HP0_AWPROT(dpu_eu_0_DPU0_M_AXI_DATA0_AWPROT),
        .S_AXI_HP0_AWQOS(dpu_eu_0_DPU0_M_AXI_DATA0_AWQOS),
        .S_AXI_HP0_AWREADY(dpu_eu_0_DPU0_M_AXI_DATA0_AWREADY),
        .S_AXI_HP0_AWSIZE(dpu_eu_0_DPU0_M_AXI_DATA0_AWSIZE),
        .S_AXI_HP0_AWVALID(dpu_eu_0_DPU0_M_AXI_DATA0_AWVALID),
        .S_AXI_HP0_BID(dpu_eu_0_DPU0_M_AXI_DATA0_BID),
        .S_AXI_HP0_BREADY(dpu_eu_0_DPU0_M_AXI_DATA0_BREADY),
        .S_AXI_HP0_BRESP(dpu_eu_0_DPU0_M_AXI_DATA0_BRESP),
        .S_AXI_HP0_BVALID(dpu_eu_0_DPU0_M_AXI_DATA0_BVALID),
        .S_AXI_HP0_RDATA(dpu_eu_0_DPU0_M_AXI_DATA0_RDATA),
        .S_AXI_HP0_RDISSUECAP1_EN(1'b0),
        .S_AXI_HP0_RID(dpu_eu_0_DPU0_M_AXI_DATA0_RID),
        .S_AXI_HP0_RLAST(dpu_eu_0_DPU0_M_AXI_DATA0_RLAST),
        .S_AXI_HP0_RREADY(dpu_eu_0_DPU0_M_AXI_DATA0_RREADY),
        .S_AXI_HP0_RRESP(dpu_eu_0_DPU0_M_AXI_DATA0_RRESP),
        .S_AXI_HP0_RVALID(dpu_eu_0_DPU0_M_AXI_DATA0_RVALID),
        .S_AXI_HP0_WDATA(dpu_eu_0_DPU0_M_AXI_DATA0_WDATA),
        .S_AXI_HP0_WID(dpu_eu_0_DPU0_M_AXI_DATA0_WID),
        .S_AXI_HP0_WLAST(dpu_eu_0_DPU0_M_AXI_DATA0_WLAST),
        .S_AXI_HP0_WREADY(dpu_eu_0_DPU0_M_AXI_DATA0_WREADY),
        .S_AXI_HP0_WRISSUECAP1_EN(1'b0),
        .S_AXI_HP0_WSTRB(dpu_eu_0_DPU0_M_AXI_DATA0_WSTRB),
        .S_AXI_HP0_WVALID(dpu_eu_0_DPU0_M_AXI_DATA0_WVALID),
        .S_AXI_HP1_ACLK(clk_wiz_0_clk_out2),
        .S_AXI_HP1_ARADDR(dpu_eu_0_DPU0_M_AXI_DATA1_ARADDR[31:0]),
        .S_AXI_HP1_ARBURST(dpu_eu_0_DPU0_M_AXI_DATA1_ARBURST),
        .S_AXI_HP1_ARCACHE(dpu_eu_0_DPU0_M_AXI_DATA1_ARCACHE),
        .S_AXI_HP1_ARID({1'b0,1'b0,1'b0,1'b0,dpu_eu_0_DPU0_M_AXI_DATA1_ARID}),
        .S_AXI_HP1_ARLEN(dpu_eu_0_DPU0_M_AXI_DATA1_ARLEN),
        .S_AXI_HP1_ARLOCK(dpu_eu_0_DPU0_M_AXI_DATA1_ARLOCK),
        .S_AXI_HP1_ARPROT(dpu_eu_0_DPU0_M_AXI_DATA1_ARPROT),
        .S_AXI_HP1_ARQOS(dpu_eu_0_DPU0_M_AXI_DATA1_ARQOS),
        .S_AXI_HP1_ARREADY(dpu_eu_0_DPU0_M_AXI_DATA1_ARREADY),
        .S_AXI_HP1_ARSIZE(dpu_eu_0_DPU0_M_AXI_DATA1_ARSIZE),
        .S_AXI_HP1_ARVALID(dpu_eu_0_DPU0_M_AXI_DATA1_ARVALID),
        .S_AXI_HP1_AWADDR(dpu_eu_0_DPU0_M_AXI_DATA1_AWADDR[31:0]),
        .S_AXI_HP1_AWBURST(dpu_eu_0_DPU0_M_AXI_DATA1_AWBURST),
        .S_AXI_HP1_AWCACHE(dpu_eu_0_DPU0_M_AXI_DATA1_AWCACHE),
        .S_AXI_HP1_AWID({1'b0,1'b0,1'b0,1'b0,dpu_eu_0_DPU0_M_AXI_DATA1_AWID}),
        .S_AXI_HP1_AWLEN(dpu_eu_0_DPU0_M_AXI_DATA1_AWLEN),
        .S_AXI_HP1_AWLOCK(dpu_eu_0_DPU0_M_AXI_DATA1_AWLOCK),
        .S_AXI_HP1_AWPROT(dpu_eu_0_DPU0_M_AXI_DATA1_AWPROT),
        .S_AXI_HP1_AWQOS(dpu_eu_0_DPU0_M_AXI_DATA1_AWQOS),
        .S_AXI_HP1_AWREADY(dpu_eu_0_DPU0_M_AXI_DATA1_AWREADY),
        .S_AXI_HP1_AWSIZE(dpu_eu_0_DPU0_M_AXI_DATA1_AWSIZE),
        .S_AXI_HP1_AWVALID(dpu_eu_0_DPU0_M_AXI_DATA1_AWVALID),
        .S_AXI_HP1_BID(dpu_eu_0_DPU0_M_AXI_DATA1_BID),
        .S_AXI_HP1_BREADY(dpu_eu_0_DPU0_M_AXI_DATA1_BREADY),
        .S_AXI_HP1_BRESP(dpu_eu_0_DPU0_M_AXI_DATA1_BRESP),
        .S_AXI_HP1_BVALID(dpu_eu_0_DPU0_M_AXI_DATA1_BVALID),
        .S_AXI_HP1_RDATA(dpu_eu_0_DPU0_M_AXI_DATA1_RDATA),
        .S_AXI_HP1_RDISSUECAP1_EN(1'b0),
        .S_AXI_HP1_RID(dpu_eu_0_DPU0_M_AXI_DATA1_RID),
        .S_AXI_HP1_RLAST(dpu_eu_0_DPU0_M_AXI_DATA1_RLAST),
        .S_AXI_HP1_RREADY(dpu_eu_0_DPU0_M_AXI_DATA1_RREADY),
        .S_AXI_HP1_RRESP(dpu_eu_0_DPU0_M_AXI_DATA1_RRESP),
        .S_AXI_HP1_RVALID(dpu_eu_0_DPU0_M_AXI_DATA1_RVALID),
        .S_AXI_HP1_WDATA(dpu_eu_0_DPU0_M_AXI_DATA1_WDATA),
        .S_AXI_HP1_WID(dpu_eu_0_DPU0_M_AXI_DATA1_WID),
        .S_AXI_HP1_WLAST(dpu_eu_0_DPU0_M_AXI_DATA1_WLAST),
        .S_AXI_HP1_WREADY(dpu_eu_0_DPU0_M_AXI_DATA1_WREADY),
        .S_AXI_HP1_WRISSUECAP1_EN(1'b0),
        .S_AXI_HP1_WSTRB(dpu_eu_0_DPU0_M_AXI_DATA1_WSTRB),
        .S_AXI_HP1_WVALID(dpu_eu_0_DPU0_M_AXI_DATA1_WVALID),
        .S_AXI_HP2_ACLK(clk_wiz_0_clk_out2),
        .S_AXI_HP2_ARADDR(axi_smc_instr_M00_AXI_ARADDR),
        .S_AXI_HP2_ARBURST(axi_smc_instr_M00_AXI_ARBURST),
        .S_AXI_HP2_ARCACHE(axi_smc_instr_M00_AXI_ARCACHE),
        .S_AXI_HP2_ARID({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP2_ARLEN(axi_smc_instr_M00_AXI_ARLEN),
        .S_AXI_HP2_ARLOCK(axi_smc_instr_M00_AXI_ARLOCK),
        .S_AXI_HP2_ARPROT(axi_smc_instr_M00_AXI_ARPROT),
        .S_AXI_HP2_ARQOS(axi_smc_instr_M00_AXI_ARQOS),
        .S_AXI_HP2_ARREADY(axi_smc_instr_M00_AXI_ARREADY),
        .S_AXI_HP2_ARSIZE(axi_smc_instr_M00_AXI_ARSIZE),
        .S_AXI_HP2_ARVALID(axi_smc_instr_M00_AXI_ARVALID),
        .S_AXI_HP2_AWADDR(axi_smc_instr_M00_AXI_AWADDR),
        .S_AXI_HP2_AWBURST(axi_smc_instr_M00_AXI_AWBURST),
        .S_AXI_HP2_AWCACHE(axi_smc_instr_M00_AXI_AWCACHE),
        .S_AXI_HP2_AWID({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP2_AWLEN(axi_smc_instr_M00_AXI_AWLEN),
        .S_AXI_HP2_AWLOCK(axi_smc_instr_M00_AXI_AWLOCK),
        .S_AXI_HP2_AWPROT(axi_smc_instr_M00_AXI_AWPROT),
        .S_AXI_HP2_AWQOS(axi_smc_instr_M00_AXI_AWQOS),
        .S_AXI_HP2_AWREADY(axi_smc_instr_M00_AXI_AWREADY),
        .S_AXI_HP2_AWSIZE(axi_smc_instr_M00_AXI_AWSIZE),
        .S_AXI_HP2_AWVALID(axi_smc_instr_M00_AXI_AWVALID),
        .S_AXI_HP2_BREADY(axi_smc_instr_M00_AXI_BREADY),
        .S_AXI_HP2_BRESP(axi_smc_instr_M00_AXI_BRESP),
        .S_AXI_HP2_BVALID(axi_smc_instr_M00_AXI_BVALID),
        .S_AXI_HP2_RDATA(axi_smc_instr_M00_AXI_RDATA),
        .S_AXI_HP2_RDISSUECAP1_EN(1'b0),
        .S_AXI_HP2_RLAST(axi_smc_instr_M00_AXI_RLAST),
        .S_AXI_HP2_RREADY(axi_smc_instr_M00_AXI_RREADY),
        .S_AXI_HP2_RRESP(axi_smc_instr_M00_AXI_RRESP),
        .S_AXI_HP2_RVALID(axi_smc_instr_M00_AXI_RVALID),
        .S_AXI_HP2_WDATA(axi_smc_instr_M00_AXI_WDATA),
        .S_AXI_HP2_WID({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP2_WLAST(axi_smc_instr_M00_AXI_WLAST),
        .S_AXI_HP2_WREADY(axi_smc_instr_M00_AXI_WREADY),
        .S_AXI_HP2_WRISSUECAP1_EN(1'b0),
        .S_AXI_HP2_WSTRB(axi_smc_instr_M00_AXI_WSTRB),
        .S_AXI_HP2_WVALID(axi_smc_instr_M00_AXI_WVALID),
        .S_AXI_HP3_ACLK(ps7_FCLK_CLK0),
        .S_AXI_HP3_ARADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP3_ARBURST({1'b0,1'b1}),
        .S_AXI_HP3_ARCACHE({1'b0,1'b0,1'b1,1'b1}),
        .S_AXI_HP3_ARID({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP3_ARLEN({1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP3_ARLOCK({1'b0,1'b0}),
        .S_AXI_HP3_ARPROT({1'b0,1'b0,1'b0}),
        .S_AXI_HP3_ARQOS({1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP3_ARSIZE({1'b0,1'b1,1'b1}),
        .S_AXI_HP3_ARVALID(1'b0),
        .S_AXI_HP3_AWADDR(axi_pc_vdma_M_AXI_AWADDR),
        .S_AXI_HP3_AWBURST(axi_pc_vdma_M_AXI_AWBURST),
        .S_AXI_HP3_AWCACHE({1'b0,1'b0,1'b1,1'b1}),
        .S_AXI_HP3_AWID(axi_pc_vdma_M_AXI_AWID),
        .S_AXI_HP3_AWLEN(axi_pc_vdma_M_AXI_AWLEN),
        .S_AXI_HP3_AWLOCK({1'b0,1'b0}),
        .S_AXI_HP3_AWPROT(axi_pc_vdma_M_AXI_AWPROT),
        .S_AXI_HP3_AWQOS({1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP3_AWREADY(axi_pc_vdma_M_AXI_AWREADY),
        .S_AXI_HP3_AWSIZE(axi_pc_vdma_M_AXI_AWSIZE),
        .S_AXI_HP3_AWVALID(axi_pc_vdma_M_AXI_AWVALID),
        .S_AXI_HP3_BID(axi_pc_vdma_M_AXI_BID),
        .S_AXI_HP3_BREADY(axi_pc_vdma_M_AXI_BREADY),
        .S_AXI_HP3_BRESP(axi_pc_vdma_M_AXI_BRESP),
        .S_AXI_HP3_BVALID(axi_pc_vdma_M_AXI_BVALID),
        .S_AXI_HP3_RDISSUECAP1_EN(1'b0),
        .S_AXI_HP3_RREADY(1'b0),
        .S_AXI_HP3_WDATA(axi_pc_vdma_M_AXI_WDATA),
        .S_AXI_HP3_WID({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP3_WLAST(axi_pc_vdma_M_AXI_WLAST),
        .S_AXI_HP3_WREADY(axi_pc_vdma_M_AXI_WREADY),
        .S_AXI_HP3_WRISSUECAP1_EN(1'b0),
        .S_AXI_HP3_WSTRB(axi_pc_vdma_M_AXI_WSTRB),
        .S_AXI_HP3_WVALID(axi_pc_vdma_M_AXI_WVALID),
        .USB0_VBUS_PWRFAULT(1'b0));
  design_1_rst_100_0 rst_100
       (.aux_reset_in(1'b1),
        .dcm_locked(1'b1),
        .ext_reset_in(ps7_FCLK_RESET0_N),
        .mb_debug_sys_rst(1'b0),
        .peripheral_aresetn(rst_100_peripheral_aresetn),
        .slowest_sync_clk(ps7_FCLK_CLK0));
  design_1_rst_150_0 rst_150
       (.aux_reset_in(1'b1),
        .dcm_locked(1'b1),
        .ext_reset_in(ps7_FCLK_RESET0_N),
        .mb_debug_sys_rst(1'b0),
        .peripheral_aresetn(rst_150_peripheral_aresetn),
        .slowest_sync_clk(clk_wiz_0_clk_out2));
  design_1_rst_300_0 rst_300
       (.aux_reset_in(1'b1),
        .dcm_locked(1'b1),
        .ext_reset_in(ps7_FCLK_RESET0_N),
        .mb_debug_sys_rst(1'b0),
        .peripheral_aresetn(rst_300_peripheral_aresetn),
        .slowest_sync_clk(clk_wiz_0_clk_out3));
  design_1_rst_cam_0 rst_cam
       (.aux_reset_in(1'b1),
        .dcm_locked(1'b1),
        .ext_reset_in(ps7_FCLK_RESET0_N),
        .mb_debug_sys_rst(1'b0),
        .peripheral_aresetn(rst_cam_peripheral_aresetn),
        .slowest_sync_clk(ps7_FCLK_CLK0));
  design_1_sda_iobuf_0 sda_iobuf
       (.I(cam_top_cmos_sda_o),
        .IO(cmos_sda),
        .O(sda_iobuf_O),
        .T(cam_top_cmos_sda_oe));
endmodule

module design_1_axi_periph_0
   (ACLK,
    ARESETN,
    M00_ACLK,
    M00_ARESETN,
    M00_AXI_araddr,
    M00_AXI_arburst,
    M00_AXI_arcache,
    M00_AXI_arid,
    M00_AXI_arlen,
    M00_AXI_arlock,
    M00_AXI_arprot,
    M00_AXI_arqos,
    M00_AXI_arready,
    M00_AXI_arsize,
    M00_AXI_arvalid,
    M00_AXI_awaddr,
    M00_AXI_awburst,
    M00_AXI_awcache,
    M00_AXI_awid,
    M00_AXI_awlen,
    M00_AXI_awlock,
    M00_AXI_awprot,
    M00_AXI_awqos,
    M00_AXI_awready,
    M00_AXI_awsize,
    M00_AXI_awvalid,
    M00_AXI_bid,
    M00_AXI_bready,
    M00_AXI_bresp,
    M00_AXI_bvalid,
    M00_AXI_rdata,
    M00_AXI_rid,
    M00_AXI_rlast,
    M00_AXI_rready,
    M00_AXI_rresp,
    M00_AXI_rvalid,
    M00_AXI_wdata,
    M00_AXI_wid,
    M00_AXI_wlast,
    M00_AXI_wready,
    M00_AXI_wstrb,
    M00_AXI_wvalid,
    M01_ACLK,
    M01_ARESETN,
    M01_AXI_araddr,
    M01_AXI_arburst,
    M01_AXI_arcache,
    M01_AXI_arid,
    M01_AXI_arlen,
    M01_AXI_arlock,
    M01_AXI_arprot,
    M01_AXI_arqos,
    M01_AXI_arready,
    M01_AXI_arsize,
    M01_AXI_arvalid,
    M01_AXI_awaddr,
    M01_AXI_awburst,
    M01_AXI_awcache,
    M01_AXI_awid,
    M01_AXI_awlen,
    M01_AXI_awlock,
    M01_AXI_awprot,
    M01_AXI_awqos,
    M01_AXI_awready,
    M01_AXI_awsize,
    M01_AXI_awvalid,
    M01_AXI_bid,
    M01_AXI_bready,
    M01_AXI_bresp,
    M01_AXI_bvalid,
    M01_AXI_rdata,
    M01_AXI_rid,
    M01_AXI_rlast,
    M01_AXI_rready,
    M01_AXI_rresp,
    M01_AXI_rvalid,
    M01_AXI_wdata,
    M01_AXI_wid,
    M01_AXI_wlast,
    M01_AXI_wready,
    M01_AXI_wstrb,
    M01_AXI_wvalid,
    M02_ACLK,
    M02_ARESETN,
    M02_AXI_araddr,
    M02_AXI_arready,
    M02_AXI_arvalid,
    M02_AXI_awaddr,
    M02_AXI_awready,
    M02_AXI_awvalid,
    M02_AXI_bready,
    M02_AXI_bresp,
    M02_AXI_bvalid,
    M02_AXI_rdata,
    M02_AXI_rready,
    M02_AXI_rresp,
    M02_AXI_rvalid,
    M02_AXI_wdata,
    M02_AXI_wready,
    M02_AXI_wstrb,
    M02_AXI_wvalid,
    S00_ACLK,
    S00_ARESETN,
    S00_AXI_araddr,
    S00_AXI_arburst,
    S00_AXI_arcache,
    S00_AXI_arid,
    S00_AXI_arlen,
    S00_AXI_arlock,
    S00_AXI_arprot,
    S00_AXI_arqos,
    S00_AXI_arready,
    S00_AXI_arsize,
    S00_AXI_arvalid,
    S00_AXI_awaddr,
    S00_AXI_awburst,
    S00_AXI_awcache,
    S00_AXI_awid,
    S00_AXI_awlen,
    S00_AXI_awlock,
    S00_AXI_awprot,
    S00_AXI_awqos,
    S00_AXI_awready,
    S00_AXI_awsize,
    S00_AXI_awvalid,
    S00_AXI_bid,
    S00_AXI_bready,
    S00_AXI_bresp,
    S00_AXI_bvalid,
    S00_AXI_rdata,
    S00_AXI_rid,
    S00_AXI_rlast,
    S00_AXI_rready,
    S00_AXI_rresp,
    S00_AXI_rvalid,
    S00_AXI_wdata,
    S00_AXI_wid,
    S00_AXI_wlast,
    S00_AXI_wready,
    S00_AXI_wstrb,
    S00_AXI_wvalid);
  input ACLK;
  input ARESETN;
  input M00_ACLK;
  input M00_ARESETN;
  output [31:0]M00_AXI_araddr;
  output [1:0]M00_AXI_arburst;
  output [3:0]M00_AXI_arcache;
  output [11:0]M00_AXI_arid;
  output [3:0]M00_AXI_arlen;
  output [1:0]M00_AXI_arlock;
  output [2:0]M00_AXI_arprot;
  output [3:0]M00_AXI_arqos;
  input M00_AXI_arready;
  output [2:0]M00_AXI_arsize;
  output M00_AXI_arvalid;
  output [31:0]M00_AXI_awaddr;
  output [1:0]M00_AXI_awburst;
  output [3:0]M00_AXI_awcache;
  output [11:0]M00_AXI_awid;
  output [3:0]M00_AXI_awlen;
  output [1:0]M00_AXI_awlock;
  output [2:0]M00_AXI_awprot;
  output [3:0]M00_AXI_awqos;
  input M00_AXI_awready;
  output [2:0]M00_AXI_awsize;
  output M00_AXI_awvalid;
  input [11:0]M00_AXI_bid;
  output M00_AXI_bready;
  input [1:0]M00_AXI_bresp;
  input M00_AXI_bvalid;
  input [31:0]M00_AXI_rdata;
  input [11:0]M00_AXI_rid;
  input M00_AXI_rlast;
  output M00_AXI_rready;
  input [1:0]M00_AXI_rresp;
  input M00_AXI_rvalid;
  output [31:0]M00_AXI_wdata;
  output [11:0]M00_AXI_wid;
  output M00_AXI_wlast;
  input M00_AXI_wready;
  output [3:0]M00_AXI_wstrb;
  output M00_AXI_wvalid;
  input M01_ACLK;
  input M01_ARESETN;
  output M01_AXI_araddr;
  output M01_AXI_arburst;
  output M01_AXI_arcache;
  output M01_AXI_arid;
  output M01_AXI_arlen;
  output M01_AXI_arlock;
  output M01_AXI_arprot;
  output M01_AXI_arqos;
  input M01_AXI_arready;
  output M01_AXI_arsize;
  output M01_AXI_arvalid;
  output M01_AXI_awaddr;
  output M01_AXI_awburst;
  output M01_AXI_awcache;
  output M01_AXI_awid;
  output M01_AXI_awlen;
  output M01_AXI_awlock;
  output M01_AXI_awprot;
  output M01_AXI_awqos;
  input M01_AXI_awready;
  output M01_AXI_awsize;
  output M01_AXI_awvalid;
  input M01_AXI_bid;
  output M01_AXI_bready;
  input M01_AXI_bresp;
  input M01_AXI_bvalid;
  input M01_AXI_rdata;
  input M01_AXI_rid;
  input M01_AXI_rlast;
  output M01_AXI_rready;
  input M01_AXI_rresp;
  input M01_AXI_rvalid;
  output M01_AXI_wdata;
  output M01_AXI_wid;
  output M01_AXI_wlast;
  input M01_AXI_wready;
  output M01_AXI_wstrb;
  output M01_AXI_wvalid;
  input M02_ACLK;
  input M02_ARESETN;
  output [31:0]M02_AXI_araddr;
  input M02_AXI_arready;
  output M02_AXI_arvalid;
  output [31:0]M02_AXI_awaddr;
  input M02_AXI_awready;
  output M02_AXI_awvalid;
  output M02_AXI_bready;
  input [1:0]M02_AXI_bresp;
  input M02_AXI_bvalid;
  input [31:0]M02_AXI_rdata;
  output M02_AXI_rready;
  input [1:0]M02_AXI_rresp;
  input M02_AXI_rvalid;
  output [31:0]M02_AXI_wdata;
  input M02_AXI_wready;
  output [3:0]M02_AXI_wstrb;
  output M02_AXI_wvalid;
  input S00_ACLK;
  input S00_ARESETN;
  input [31:0]S00_AXI_araddr;
  input [1:0]S00_AXI_arburst;
  input [3:0]S00_AXI_arcache;
  input [11:0]S00_AXI_arid;
  input [3:0]S00_AXI_arlen;
  input [1:0]S00_AXI_arlock;
  input [2:0]S00_AXI_arprot;
  input [3:0]S00_AXI_arqos;
  output S00_AXI_arready;
  input [2:0]S00_AXI_arsize;
  input S00_AXI_arvalid;
  input [31:0]S00_AXI_awaddr;
  input [1:0]S00_AXI_awburst;
  input [3:0]S00_AXI_awcache;
  input [11:0]S00_AXI_awid;
  input [3:0]S00_AXI_awlen;
  input [1:0]S00_AXI_awlock;
  input [2:0]S00_AXI_awprot;
  input [3:0]S00_AXI_awqos;
  output S00_AXI_awready;
  input [2:0]S00_AXI_awsize;
  input S00_AXI_awvalid;
  output [11:0]S00_AXI_bid;
  input S00_AXI_bready;
  output [1:0]S00_AXI_bresp;
  output S00_AXI_bvalid;
  output [31:0]S00_AXI_rdata;
  output [11:0]S00_AXI_rid;
  output S00_AXI_rlast;
  input S00_AXI_rready;
  output [1:0]S00_AXI_rresp;
  output S00_AXI_rvalid;
  input [31:0]S00_AXI_wdata;
  input [11:0]S00_AXI_wid;
  input S00_AXI_wlast;
  output S00_AXI_wready;
  input [3:0]S00_AXI_wstrb;
  input S00_AXI_wvalid;

  wire M00_ACLK_1;
  wire M00_ARESETN_1;
  wire M01_ACLK_1;
  wire M01_ARESETN_1;
  wire M02_ACLK_1;
  wire M02_ARESETN_1;
  wire S00_ACLK_1;
  wire S00_ARESETN_1;
  wire axi_periph_ACLK_net;
  wire axi_periph_ARESETN_net;
  wire [31:0]axi_periph_to_s00_couplers_ARADDR;
  wire [1:0]axi_periph_to_s00_couplers_ARBURST;
  wire [3:0]axi_periph_to_s00_couplers_ARCACHE;
  wire [11:0]axi_periph_to_s00_couplers_ARID;
  wire [3:0]axi_periph_to_s00_couplers_ARLEN;
  wire [1:0]axi_periph_to_s00_couplers_ARLOCK;
  wire [2:0]axi_periph_to_s00_couplers_ARPROT;
  wire [3:0]axi_periph_to_s00_couplers_ARQOS;
  wire axi_periph_to_s00_couplers_ARREADY;
  wire [2:0]axi_periph_to_s00_couplers_ARSIZE;
  wire axi_periph_to_s00_couplers_ARVALID;
  wire [31:0]axi_periph_to_s00_couplers_AWADDR;
  wire [1:0]axi_periph_to_s00_couplers_AWBURST;
  wire [3:0]axi_periph_to_s00_couplers_AWCACHE;
  wire [11:0]axi_periph_to_s00_couplers_AWID;
  wire [3:0]axi_periph_to_s00_couplers_AWLEN;
  wire [1:0]axi_periph_to_s00_couplers_AWLOCK;
  wire [2:0]axi_periph_to_s00_couplers_AWPROT;
  wire [3:0]axi_periph_to_s00_couplers_AWQOS;
  wire axi_periph_to_s00_couplers_AWREADY;
  wire [2:0]axi_periph_to_s00_couplers_AWSIZE;
  wire axi_periph_to_s00_couplers_AWVALID;
  wire [11:0]axi_periph_to_s00_couplers_BID;
  wire axi_periph_to_s00_couplers_BREADY;
  wire [1:0]axi_periph_to_s00_couplers_BRESP;
  wire axi_periph_to_s00_couplers_BVALID;
  wire [31:0]axi_periph_to_s00_couplers_RDATA;
  wire [11:0]axi_periph_to_s00_couplers_RID;
  wire axi_periph_to_s00_couplers_RLAST;
  wire axi_periph_to_s00_couplers_RREADY;
  wire [1:0]axi_periph_to_s00_couplers_RRESP;
  wire axi_periph_to_s00_couplers_RVALID;
  wire [31:0]axi_periph_to_s00_couplers_WDATA;
  wire [11:0]axi_periph_to_s00_couplers_WID;
  wire axi_periph_to_s00_couplers_WLAST;
  wire axi_periph_to_s00_couplers_WREADY;
  wire [3:0]axi_periph_to_s00_couplers_WSTRB;
  wire axi_periph_to_s00_couplers_WVALID;
  wire [31:0]m00_couplers_to_axi_periph_ARADDR;
  wire [1:0]m00_couplers_to_axi_periph_ARBURST;
  wire [3:0]m00_couplers_to_axi_periph_ARCACHE;
  wire [11:0]m00_couplers_to_axi_periph_ARID;
  wire [3:0]m00_couplers_to_axi_periph_ARLEN;
  wire [1:0]m00_couplers_to_axi_periph_ARLOCK;
  wire [2:0]m00_couplers_to_axi_periph_ARPROT;
  wire [3:0]m00_couplers_to_axi_periph_ARQOS;
  wire m00_couplers_to_axi_periph_ARREADY;
  wire [2:0]m00_couplers_to_axi_periph_ARSIZE;
  wire m00_couplers_to_axi_periph_ARVALID;
  wire [31:0]m00_couplers_to_axi_periph_AWADDR;
  wire [1:0]m00_couplers_to_axi_periph_AWBURST;
  wire [3:0]m00_couplers_to_axi_periph_AWCACHE;
  wire [11:0]m00_couplers_to_axi_periph_AWID;
  wire [3:0]m00_couplers_to_axi_periph_AWLEN;
  wire [1:0]m00_couplers_to_axi_periph_AWLOCK;
  wire [2:0]m00_couplers_to_axi_periph_AWPROT;
  wire [3:0]m00_couplers_to_axi_periph_AWQOS;
  wire m00_couplers_to_axi_periph_AWREADY;
  wire [2:0]m00_couplers_to_axi_periph_AWSIZE;
  wire m00_couplers_to_axi_periph_AWVALID;
  wire [11:0]m00_couplers_to_axi_periph_BID;
  wire m00_couplers_to_axi_periph_BREADY;
  wire [1:0]m00_couplers_to_axi_periph_BRESP;
  wire m00_couplers_to_axi_periph_BVALID;
  wire [31:0]m00_couplers_to_axi_periph_RDATA;
  wire [11:0]m00_couplers_to_axi_periph_RID;
  wire m00_couplers_to_axi_periph_RLAST;
  wire m00_couplers_to_axi_periph_RREADY;
  wire [1:0]m00_couplers_to_axi_periph_RRESP;
  wire m00_couplers_to_axi_periph_RVALID;
  wire [31:0]m00_couplers_to_axi_periph_WDATA;
  wire [11:0]m00_couplers_to_axi_periph_WID;
  wire m00_couplers_to_axi_periph_WLAST;
  wire m00_couplers_to_axi_periph_WREADY;
  wire [3:0]m00_couplers_to_axi_periph_WSTRB;
  wire m00_couplers_to_axi_periph_WVALID;
  wire m01_couplers_to_axi_periph_ARADDR;
  wire m01_couplers_to_axi_periph_ARBURST;
  wire m01_couplers_to_axi_periph_ARCACHE;
  wire m01_couplers_to_axi_periph_ARID;
  wire m01_couplers_to_axi_periph_ARLEN;
  wire m01_couplers_to_axi_periph_ARLOCK;
  wire m01_couplers_to_axi_periph_ARPROT;
  wire m01_couplers_to_axi_periph_ARQOS;
  wire m01_couplers_to_axi_periph_ARREADY;
  wire m01_couplers_to_axi_periph_ARSIZE;
  wire m01_couplers_to_axi_periph_ARVALID;
  wire m01_couplers_to_axi_periph_AWADDR;
  wire m01_couplers_to_axi_periph_AWBURST;
  wire m01_couplers_to_axi_periph_AWCACHE;
  wire m01_couplers_to_axi_periph_AWID;
  wire m01_couplers_to_axi_periph_AWLEN;
  wire m01_couplers_to_axi_periph_AWLOCK;
  wire m01_couplers_to_axi_periph_AWPROT;
  wire m01_couplers_to_axi_periph_AWQOS;
  wire m01_couplers_to_axi_periph_AWREADY;
  wire m01_couplers_to_axi_periph_AWSIZE;
  wire m01_couplers_to_axi_periph_AWVALID;
  wire m01_couplers_to_axi_periph_BID;
  wire m01_couplers_to_axi_periph_BREADY;
  wire m01_couplers_to_axi_periph_BRESP;
  wire m01_couplers_to_axi_periph_BVALID;
  wire m01_couplers_to_axi_periph_RDATA;
  wire m01_couplers_to_axi_periph_RID;
  wire m01_couplers_to_axi_periph_RLAST;
  wire m01_couplers_to_axi_periph_RREADY;
  wire m01_couplers_to_axi_periph_RRESP;
  wire m01_couplers_to_axi_periph_RVALID;
  wire m01_couplers_to_axi_periph_WDATA;
  wire m01_couplers_to_axi_periph_WID;
  wire m01_couplers_to_axi_periph_WLAST;
  wire m01_couplers_to_axi_periph_WREADY;
  wire m01_couplers_to_axi_periph_WSTRB;
  wire m01_couplers_to_axi_periph_WVALID;
  wire [31:0]m02_couplers_to_axi_periph_ARADDR;
  wire m02_couplers_to_axi_periph_ARREADY;
  wire m02_couplers_to_axi_periph_ARVALID;
  wire [31:0]m02_couplers_to_axi_periph_AWADDR;
  wire m02_couplers_to_axi_periph_AWREADY;
  wire m02_couplers_to_axi_periph_AWVALID;
  wire m02_couplers_to_axi_periph_BREADY;
  wire [1:0]m02_couplers_to_axi_periph_BRESP;
  wire m02_couplers_to_axi_periph_BVALID;
  wire [31:0]m02_couplers_to_axi_periph_RDATA;
  wire m02_couplers_to_axi_periph_RREADY;
  wire [1:0]m02_couplers_to_axi_periph_RRESP;
  wire m02_couplers_to_axi_periph_RVALID;
  wire [31:0]m02_couplers_to_axi_periph_WDATA;
  wire m02_couplers_to_axi_periph_WREADY;
  wire [3:0]m02_couplers_to_axi_periph_WSTRB;
  wire m02_couplers_to_axi_periph_WVALID;
  wire [31:0]s00_couplers_to_xbar_ARADDR;
  wire [1:0]s00_couplers_to_xbar_ARBURST;
  wire [3:0]s00_couplers_to_xbar_ARCACHE;
  wire [11:0]s00_couplers_to_xbar_ARID;
  wire [3:0]s00_couplers_to_xbar_ARLEN;
  wire [1:0]s00_couplers_to_xbar_ARLOCK;
  wire [2:0]s00_couplers_to_xbar_ARPROT;
  wire [3:0]s00_couplers_to_xbar_ARQOS;
  wire [0:0]s00_couplers_to_xbar_ARREADY;
  wire [2:0]s00_couplers_to_xbar_ARSIZE;
  wire s00_couplers_to_xbar_ARVALID;
  wire [31:0]s00_couplers_to_xbar_AWADDR;
  wire [1:0]s00_couplers_to_xbar_AWBURST;
  wire [3:0]s00_couplers_to_xbar_AWCACHE;
  wire [11:0]s00_couplers_to_xbar_AWID;
  wire [3:0]s00_couplers_to_xbar_AWLEN;
  wire [1:0]s00_couplers_to_xbar_AWLOCK;
  wire [2:0]s00_couplers_to_xbar_AWPROT;
  wire [3:0]s00_couplers_to_xbar_AWQOS;
  wire [0:0]s00_couplers_to_xbar_AWREADY;
  wire [2:0]s00_couplers_to_xbar_AWSIZE;
  wire s00_couplers_to_xbar_AWVALID;
  wire [11:0]s00_couplers_to_xbar_BID;
  wire s00_couplers_to_xbar_BREADY;
  wire [1:0]s00_couplers_to_xbar_BRESP;
  wire [0:0]s00_couplers_to_xbar_BVALID;
  wire [31:0]s00_couplers_to_xbar_RDATA;
  wire [11:0]s00_couplers_to_xbar_RID;
  wire [0:0]s00_couplers_to_xbar_RLAST;
  wire s00_couplers_to_xbar_RREADY;
  wire [1:0]s00_couplers_to_xbar_RRESP;
  wire [0:0]s00_couplers_to_xbar_RVALID;
  wire [31:0]s00_couplers_to_xbar_WDATA;
  wire [11:0]s00_couplers_to_xbar_WID;
  wire s00_couplers_to_xbar_WLAST;
  wire [0:0]s00_couplers_to_xbar_WREADY;
  wire [3:0]s00_couplers_to_xbar_WSTRB;
  wire s00_couplers_to_xbar_WVALID;
  wire [31:0]xbar_to_m00_couplers_ARADDR;
  wire [1:0]xbar_to_m00_couplers_ARBURST;
  wire [3:0]xbar_to_m00_couplers_ARCACHE;
  wire [11:0]xbar_to_m00_couplers_ARID;
  wire [3:0]xbar_to_m00_couplers_ARLEN;
  wire [1:0]xbar_to_m00_couplers_ARLOCK;
  wire [2:0]xbar_to_m00_couplers_ARPROT;
  wire [3:0]xbar_to_m00_couplers_ARQOS;
  wire xbar_to_m00_couplers_ARREADY;
  wire [2:0]xbar_to_m00_couplers_ARSIZE;
  wire [0:0]xbar_to_m00_couplers_ARVALID;
  wire [31:0]xbar_to_m00_couplers_AWADDR;
  wire [1:0]xbar_to_m00_couplers_AWBURST;
  wire [3:0]xbar_to_m00_couplers_AWCACHE;
  wire [11:0]xbar_to_m00_couplers_AWID;
  wire [3:0]xbar_to_m00_couplers_AWLEN;
  wire [1:0]xbar_to_m00_couplers_AWLOCK;
  wire [2:0]xbar_to_m00_couplers_AWPROT;
  wire [3:0]xbar_to_m00_couplers_AWQOS;
  wire xbar_to_m00_couplers_AWREADY;
  wire [2:0]xbar_to_m00_couplers_AWSIZE;
  wire [0:0]xbar_to_m00_couplers_AWVALID;
  wire [11:0]xbar_to_m00_couplers_BID;
  wire [0:0]xbar_to_m00_couplers_BREADY;
  wire [1:0]xbar_to_m00_couplers_BRESP;
  wire xbar_to_m00_couplers_BVALID;
  wire [31:0]xbar_to_m00_couplers_RDATA;
  wire [11:0]xbar_to_m00_couplers_RID;
  wire xbar_to_m00_couplers_RLAST;
  wire [0:0]xbar_to_m00_couplers_RREADY;
  wire [1:0]xbar_to_m00_couplers_RRESP;
  wire xbar_to_m00_couplers_RVALID;
  wire [31:0]xbar_to_m00_couplers_WDATA;
  wire [11:0]xbar_to_m00_couplers_WID;
  wire [0:0]xbar_to_m00_couplers_WLAST;
  wire xbar_to_m00_couplers_WREADY;
  wire [3:0]xbar_to_m00_couplers_WSTRB;
  wire [0:0]xbar_to_m00_couplers_WVALID;
  wire [63:32]xbar_to_m01_couplers_ARADDR;
  wire [3:2]xbar_to_m01_couplers_ARBURST;
  wire [7:4]xbar_to_m01_couplers_ARCACHE;
  wire [23:12]xbar_to_m01_couplers_ARID;
  wire [7:4]xbar_to_m01_couplers_ARLEN;
  wire [3:2]xbar_to_m01_couplers_ARLOCK;
  wire [5:3]xbar_to_m01_couplers_ARPROT;
  wire [7:4]xbar_to_m01_couplers_ARQOS;
  wire xbar_to_m01_couplers_ARREADY;
  wire [5:3]xbar_to_m01_couplers_ARSIZE;
  wire [1:1]xbar_to_m01_couplers_ARVALID;
  wire [63:32]xbar_to_m01_couplers_AWADDR;
  wire [3:2]xbar_to_m01_couplers_AWBURST;
  wire [7:4]xbar_to_m01_couplers_AWCACHE;
  wire [23:12]xbar_to_m01_couplers_AWID;
  wire [7:4]xbar_to_m01_couplers_AWLEN;
  wire [3:2]xbar_to_m01_couplers_AWLOCK;
  wire [5:3]xbar_to_m01_couplers_AWPROT;
  wire [7:4]xbar_to_m01_couplers_AWQOS;
  wire xbar_to_m01_couplers_AWREADY;
  wire [5:3]xbar_to_m01_couplers_AWSIZE;
  wire [1:1]xbar_to_m01_couplers_AWVALID;
  wire xbar_to_m01_couplers_BID;
  wire [1:1]xbar_to_m01_couplers_BREADY;
  wire xbar_to_m01_couplers_BRESP;
  wire xbar_to_m01_couplers_BVALID;
  wire xbar_to_m01_couplers_RDATA;
  wire xbar_to_m01_couplers_RID;
  wire xbar_to_m01_couplers_RLAST;
  wire [1:1]xbar_to_m01_couplers_RREADY;
  wire xbar_to_m01_couplers_RRESP;
  wire xbar_to_m01_couplers_RVALID;
  wire [63:32]xbar_to_m01_couplers_WDATA;
  wire [23:12]xbar_to_m01_couplers_WID;
  wire [1:1]xbar_to_m01_couplers_WLAST;
  wire xbar_to_m01_couplers_WREADY;
  wire [7:4]xbar_to_m01_couplers_WSTRB;
  wire [1:1]xbar_to_m01_couplers_WVALID;
  wire [95:64]xbar_to_m02_couplers_ARADDR;
  wire [5:4]xbar_to_m02_couplers_ARBURST;
  wire [11:8]xbar_to_m02_couplers_ARCACHE;
  wire [35:24]xbar_to_m02_couplers_ARID;
  wire [11:8]xbar_to_m02_couplers_ARLEN;
  wire [5:4]xbar_to_m02_couplers_ARLOCK;
  wire [8:6]xbar_to_m02_couplers_ARPROT;
  wire [11:8]xbar_to_m02_couplers_ARQOS;
  wire xbar_to_m02_couplers_ARREADY;
  wire [8:6]xbar_to_m02_couplers_ARSIZE;
  wire [2:2]xbar_to_m02_couplers_ARVALID;
  wire [95:64]xbar_to_m02_couplers_AWADDR;
  wire [5:4]xbar_to_m02_couplers_AWBURST;
  wire [11:8]xbar_to_m02_couplers_AWCACHE;
  wire [35:24]xbar_to_m02_couplers_AWID;
  wire [11:8]xbar_to_m02_couplers_AWLEN;
  wire [5:4]xbar_to_m02_couplers_AWLOCK;
  wire [8:6]xbar_to_m02_couplers_AWPROT;
  wire [11:8]xbar_to_m02_couplers_AWQOS;
  wire xbar_to_m02_couplers_AWREADY;
  wire [8:6]xbar_to_m02_couplers_AWSIZE;
  wire [2:2]xbar_to_m02_couplers_AWVALID;
  wire [11:0]xbar_to_m02_couplers_BID;
  wire [2:2]xbar_to_m02_couplers_BREADY;
  wire [1:0]xbar_to_m02_couplers_BRESP;
  wire xbar_to_m02_couplers_BVALID;
  wire [31:0]xbar_to_m02_couplers_RDATA;
  wire [11:0]xbar_to_m02_couplers_RID;
  wire xbar_to_m02_couplers_RLAST;
  wire [2:2]xbar_to_m02_couplers_RREADY;
  wire [1:0]xbar_to_m02_couplers_RRESP;
  wire xbar_to_m02_couplers_RVALID;
  wire [95:64]xbar_to_m02_couplers_WDATA;
  wire [35:24]xbar_to_m02_couplers_WID;
  wire [2:2]xbar_to_m02_couplers_WLAST;
  wire xbar_to_m02_couplers_WREADY;
  wire [11:8]xbar_to_m02_couplers_WSTRB;
  wire [2:2]xbar_to_m02_couplers_WVALID;

  assign M00_ACLK_1 = M00_ACLK;
  assign M00_ARESETN_1 = M00_ARESETN;
  assign M00_AXI_araddr[31:0] = m00_couplers_to_axi_periph_ARADDR;
  assign M00_AXI_arburst[1:0] = m00_couplers_to_axi_periph_ARBURST;
  assign M00_AXI_arcache[3:0] = m00_couplers_to_axi_periph_ARCACHE;
  assign M00_AXI_arid[11:0] = m00_couplers_to_axi_periph_ARID;
  assign M00_AXI_arlen[3:0] = m00_couplers_to_axi_periph_ARLEN;
  assign M00_AXI_arlock[1:0] = m00_couplers_to_axi_periph_ARLOCK;
  assign M00_AXI_arprot[2:0] = m00_couplers_to_axi_periph_ARPROT;
  assign M00_AXI_arqos[3:0] = m00_couplers_to_axi_periph_ARQOS;
  assign M00_AXI_arsize[2:0] = m00_couplers_to_axi_periph_ARSIZE;
  assign M00_AXI_arvalid = m00_couplers_to_axi_periph_ARVALID;
  assign M00_AXI_awaddr[31:0] = m00_couplers_to_axi_periph_AWADDR;
  assign M00_AXI_awburst[1:0] = m00_couplers_to_axi_periph_AWBURST;
  assign M00_AXI_awcache[3:0] = m00_couplers_to_axi_periph_AWCACHE;
  assign M00_AXI_awid[11:0] = m00_couplers_to_axi_periph_AWID;
  assign M00_AXI_awlen[3:0] = m00_couplers_to_axi_periph_AWLEN;
  assign M00_AXI_awlock[1:0] = m00_couplers_to_axi_periph_AWLOCK;
  assign M00_AXI_awprot[2:0] = m00_couplers_to_axi_periph_AWPROT;
  assign M00_AXI_awqos[3:0] = m00_couplers_to_axi_periph_AWQOS;
  assign M00_AXI_awsize[2:0] = m00_couplers_to_axi_periph_AWSIZE;
  assign M00_AXI_awvalid = m00_couplers_to_axi_periph_AWVALID;
  assign M00_AXI_bready = m00_couplers_to_axi_periph_BREADY;
  assign M00_AXI_rready = m00_couplers_to_axi_periph_RREADY;
  assign M00_AXI_wdata[31:0] = m00_couplers_to_axi_periph_WDATA;
  assign M00_AXI_wid[11:0] = m00_couplers_to_axi_periph_WID;
  assign M00_AXI_wlast = m00_couplers_to_axi_periph_WLAST;
  assign M00_AXI_wstrb[3:0] = m00_couplers_to_axi_periph_WSTRB;
  assign M00_AXI_wvalid = m00_couplers_to_axi_periph_WVALID;
  assign M01_ACLK_1 = M01_ACLK;
  assign M01_ARESETN_1 = M01_ARESETN;
  assign M01_AXI_araddr = m01_couplers_to_axi_periph_ARADDR;
  assign M01_AXI_arburst = m01_couplers_to_axi_periph_ARBURST;
  assign M01_AXI_arcache = m01_couplers_to_axi_periph_ARCACHE;
  assign M01_AXI_arid = m01_couplers_to_axi_periph_ARID;
  assign M01_AXI_arlen = m01_couplers_to_axi_periph_ARLEN;
  assign M01_AXI_arlock = m01_couplers_to_axi_periph_ARLOCK;
  assign M01_AXI_arprot = m01_couplers_to_axi_periph_ARPROT;
  assign M01_AXI_arqos = m01_couplers_to_axi_periph_ARQOS;
  assign M01_AXI_arsize = m01_couplers_to_axi_periph_ARSIZE;
  assign M01_AXI_arvalid = m01_couplers_to_axi_periph_ARVALID;
  assign M01_AXI_awaddr = m01_couplers_to_axi_periph_AWADDR;
  assign M01_AXI_awburst = m01_couplers_to_axi_periph_AWBURST;
  assign M01_AXI_awcache = m01_couplers_to_axi_periph_AWCACHE;
  assign M01_AXI_awid = m01_couplers_to_axi_periph_AWID;
  assign M01_AXI_awlen = m01_couplers_to_axi_periph_AWLEN;
  assign M01_AXI_awlock = m01_couplers_to_axi_periph_AWLOCK;
  assign M01_AXI_awprot = m01_couplers_to_axi_periph_AWPROT;
  assign M01_AXI_awqos = m01_couplers_to_axi_periph_AWQOS;
  assign M01_AXI_awsize = m01_couplers_to_axi_periph_AWSIZE;
  assign M01_AXI_awvalid = m01_couplers_to_axi_periph_AWVALID;
  assign M01_AXI_bready = m01_couplers_to_axi_periph_BREADY;
  assign M01_AXI_rready = m01_couplers_to_axi_periph_RREADY;
  assign M01_AXI_wdata = m01_couplers_to_axi_periph_WDATA;
  assign M01_AXI_wid = m01_couplers_to_axi_periph_WID;
  assign M01_AXI_wlast = m01_couplers_to_axi_periph_WLAST;
  assign M01_AXI_wstrb = m01_couplers_to_axi_periph_WSTRB;
  assign M01_AXI_wvalid = m01_couplers_to_axi_periph_WVALID;
  assign M02_ACLK_1 = M02_ACLK;
  assign M02_ARESETN_1 = M02_ARESETN;
  assign M02_AXI_araddr[31:0] = m02_couplers_to_axi_periph_ARADDR;
  assign M02_AXI_arvalid = m02_couplers_to_axi_periph_ARVALID;
  assign M02_AXI_awaddr[31:0] = m02_couplers_to_axi_periph_AWADDR;
  assign M02_AXI_awvalid = m02_couplers_to_axi_periph_AWVALID;
  assign M02_AXI_bready = m02_couplers_to_axi_periph_BREADY;
  assign M02_AXI_rready = m02_couplers_to_axi_periph_RREADY;
  assign M02_AXI_wdata[31:0] = m02_couplers_to_axi_periph_WDATA;
  assign M02_AXI_wstrb[3:0] = m02_couplers_to_axi_periph_WSTRB;
  assign M02_AXI_wvalid = m02_couplers_to_axi_periph_WVALID;
  assign S00_ACLK_1 = S00_ACLK;
  assign S00_ARESETN_1 = S00_ARESETN;
  assign S00_AXI_arready = axi_periph_to_s00_couplers_ARREADY;
  assign S00_AXI_awready = axi_periph_to_s00_couplers_AWREADY;
  assign S00_AXI_bid[11:0] = axi_periph_to_s00_couplers_BID;
  assign S00_AXI_bresp[1:0] = axi_periph_to_s00_couplers_BRESP;
  assign S00_AXI_bvalid = axi_periph_to_s00_couplers_BVALID;
  assign S00_AXI_rdata[31:0] = axi_periph_to_s00_couplers_RDATA;
  assign S00_AXI_rid[11:0] = axi_periph_to_s00_couplers_RID;
  assign S00_AXI_rlast = axi_periph_to_s00_couplers_RLAST;
  assign S00_AXI_rresp[1:0] = axi_periph_to_s00_couplers_RRESP;
  assign S00_AXI_rvalid = axi_periph_to_s00_couplers_RVALID;
  assign S00_AXI_wready = axi_periph_to_s00_couplers_WREADY;
  assign axi_periph_ACLK_net = ACLK;
  assign axi_periph_ARESETN_net = ARESETN;
  assign axi_periph_to_s00_couplers_ARADDR = S00_AXI_araddr[31:0];
  assign axi_periph_to_s00_couplers_ARBURST = S00_AXI_arburst[1:0];
  assign axi_periph_to_s00_couplers_ARCACHE = S00_AXI_arcache[3:0];
  assign axi_periph_to_s00_couplers_ARID = S00_AXI_arid[11:0];
  assign axi_periph_to_s00_couplers_ARLEN = S00_AXI_arlen[3:0];
  assign axi_periph_to_s00_couplers_ARLOCK = S00_AXI_arlock[1:0];
  assign axi_periph_to_s00_couplers_ARPROT = S00_AXI_arprot[2:0];
  assign axi_periph_to_s00_couplers_ARQOS = S00_AXI_arqos[3:0];
  assign axi_periph_to_s00_couplers_ARSIZE = S00_AXI_arsize[2:0];
  assign axi_periph_to_s00_couplers_ARVALID = S00_AXI_arvalid;
  assign axi_periph_to_s00_couplers_AWADDR = S00_AXI_awaddr[31:0];
  assign axi_periph_to_s00_couplers_AWBURST = S00_AXI_awburst[1:0];
  assign axi_periph_to_s00_couplers_AWCACHE = S00_AXI_awcache[3:0];
  assign axi_periph_to_s00_couplers_AWID = S00_AXI_awid[11:0];
  assign axi_periph_to_s00_couplers_AWLEN = S00_AXI_awlen[3:0];
  assign axi_periph_to_s00_couplers_AWLOCK = S00_AXI_awlock[1:0];
  assign axi_periph_to_s00_couplers_AWPROT = S00_AXI_awprot[2:0];
  assign axi_periph_to_s00_couplers_AWQOS = S00_AXI_awqos[3:0];
  assign axi_periph_to_s00_couplers_AWSIZE = S00_AXI_awsize[2:0];
  assign axi_periph_to_s00_couplers_AWVALID = S00_AXI_awvalid;
  assign axi_periph_to_s00_couplers_BREADY = S00_AXI_bready;
  assign axi_periph_to_s00_couplers_RREADY = S00_AXI_rready;
  assign axi_periph_to_s00_couplers_WDATA = S00_AXI_wdata[31:0];
  assign axi_periph_to_s00_couplers_WID = S00_AXI_wid[11:0];
  assign axi_periph_to_s00_couplers_WLAST = S00_AXI_wlast;
  assign axi_periph_to_s00_couplers_WSTRB = S00_AXI_wstrb[3:0];
  assign axi_periph_to_s00_couplers_WVALID = S00_AXI_wvalid;
  assign m00_couplers_to_axi_periph_ARREADY = M00_AXI_arready;
  assign m00_couplers_to_axi_periph_AWREADY = M00_AXI_awready;
  assign m00_couplers_to_axi_periph_BID = M00_AXI_bid[11:0];
  assign m00_couplers_to_axi_periph_BRESP = M00_AXI_bresp[1:0];
  assign m00_couplers_to_axi_periph_BVALID = M00_AXI_bvalid;
  assign m00_couplers_to_axi_periph_RDATA = M00_AXI_rdata[31:0];
  assign m00_couplers_to_axi_periph_RID = M00_AXI_rid[11:0];
  assign m00_couplers_to_axi_periph_RLAST = M00_AXI_rlast;
  assign m00_couplers_to_axi_periph_RRESP = M00_AXI_rresp[1:0];
  assign m00_couplers_to_axi_periph_RVALID = M00_AXI_rvalid;
  assign m00_couplers_to_axi_periph_WREADY = M00_AXI_wready;
  assign m01_couplers_to_axi_periph_ARREADY = M01_AXI_arready;
  assign m01_couplers_to_axi_periph_AWREADY = M01_AXI_awready;
  assign m01_couplers_to_axi_periph_BID = M01_AXI_bid;
  assign m01_couplers_to_axi_periph_BRESP = M01_AXI_bresp;
  assign m01_couplers_to_axi_periph_BVALID = M01_AXI_bvalid;
  assign m01_couplers_to_axi_periph_RDATA = M01_AXI_rdata;
  assign m01_couplers_to_axi_periph_RID = M01_AXI_rid;
  assign m01_couplers_to_axi_periph_RLAST = M01_AXI_rlast;
  assign m01_couplers_to_axi_periph_RRESP = M01_AXI_rresp;
  assign m01_couplers_to_axi_periph_RVALID = M01_AXI_rvalid;
  assign m01_couplers_to_axi_periph_WREADY = M01_AXI_wready;
  assign m02_couplers_to_axi_periph_ARREADY = M02_AXI_arready;
  assign m02_couplers_to_axi_periph_AWREADY = M02_AXI_awready;
  assign m02_couplers_to_axi_periph_BRESP = M02_AXI_bresp[1:0];
  assign m02_couplers_to_axi_periph_BVALID = M02_AXI_bvalid;
  assign m02_couplers_to_axi_periph_RDATA = M02_AXI_rdata[31:0];
  assign m02_couplers_to_axi_periph_RRESP = M02_AXI_rresp[1:0];
  assign m02_couplers_to_axi_periph_RVALID = M02_AXI_rvalid;
  assign m02_couplers_to_axi_periph_WREADY = M02_AXI_wready;
  m00_couplers_imp_1PZPB4E m00_couplers
       (.M_ACLK(M00_ACLK_1),
        .M_ARESETN(M00_ARESETN_1),
        .M_AXI_araddr(m00_couplers_to_axi_periph_ARADDR),
        .M_AXI_arburst(m00_couplers_to_axi_periph_ARBURST),
        .M_AXI_arcache(m00_couplers_to_axi_periph_ARCACHE),
        .M_AXI_arid(m00_couplers_to_axi_periph_ARID),
        .M_AXI_arlen(m00_couplers_to_axi_periph_ARLEN),
        .M_AXI_arlock(m00_couplers_to_axi_periph_ARLOCK),
        .M_AXI_arprot(m00_couplers_to_axi_periph_ARPROT),
        .M_AXI_arqos(m00_couplers_to_axi_periph_ARQOS),
        .M_AXI_arready(m00_couplers_to_axi_periph_ARREADY),
        .M_AXI_arsize(m00_couplers_to_axi_periph_ARSIZE),
        .M_AXI_arvalid(m00_couplers_to_axi_periph_ARVALID),
        .M_AXI_awaddr(m00_couplers_to_axi_periph_AWADDR),
        .M_AXI_awburst(m00_couplers_to_axi_periph_AWBURST),
        .M_AXI_awcache(m00_couplers_to_axi_periph_AWCACHE),
        .M_AXI_awid(m00_couplers_to_axi_periph_AWID),
        .M_AXI_awlen(m00_couplers_to_axi_periph_AWLEN),
        .M_AXI_awlock(m00_couplers_to_axi_periph_AWLOCK),
        .M_AXI_awprot(m00_couplers_to_axi_periph_AWPROT),
        .M_AXI_awqos(m00_couplers_to_axi_periph_AWQOS),
        .M_AXI_awready(m00_couplers_to_axi_periph_AWREADY),
        .M_AXI_awsize(m00_couplers_to_axi_periph_AWSIZE),
        .M_AXI_awvalid(m00_couplers_to_axi_periph_AWVALID),
        .M_AXI_bid(m00_couplers_to_axi_periph_BID),
        .M_AXI_bready(m00_couplers_to_axi_periph_BREADY),
        .M_AXI_bresp(m00_couplers_to_axi_periph_BRESP),
        .M_AXI_bvalid(m00_couplers_to_axi_periph_BVALID),
        .M_AXI_rdata(m00_couplers_to_axi_periph_RDATA),
        .M_AXI_rid(m00_couplers_to_axi_periph_RID),
        .M_AXI_rlast(m00_couplers_to_axi_periph_RLAST),
        .M_AXI_rready(m00_couplers_to_axi_periph_RREADY),
        .M_AXI_rresp(m00_couplers_to_axi_periph_RRESP),
        .M_AXI_rvalid(m00_couplers_to_axi_periph_RVALID),
        .M_AXI_wdata(m00_couplers_to_axi_periph_WDATA),
        .M_AXI_wid(m00_couplers_to_axi_periph_WID),
        .M_AXI_wlast(m00_couplers_to_axi_periph_WLAST),
        .M_AXI_wready(m00_couplers_to_axi_periph_WREADY),
        .M_AXI_wstrb(m00_couplers_to_axi_periph_WSTRB),
        .M_AXI_wvalid(m00_couplers_to_axi_periph_WVALID),
        .S_ACLK(axi_periph_ACLK_net),
        .S_ARESETN(axi_periph_ARESETN_net),
        .S_AXI_araddr(xbar_to_m00_couplers_ARADDR),
        .S_AXI_arburst(xbar_to_m00_couplers_ARBURST),
        .S_AXI_arcache(xbar_to_m00_couplers_ARCACHE),
        .S_AXI_arid(xbar_to_m00_couplers_ARID),
        .S_AXI_arlen(xbar_to_m00_couplers_ARLEN),
        .S_AXI_arlock(xbar_to_m00_couplers_ARLOCK),
        .S_AXI_arprot(xbar_to_m00_couplers_ARPROT),
        .S_AXI_arqos(xbar_to_m00_couplers_ARQOS),
        .S_AXI_arready(xbar_to_m00_couplers_ARREADY),
        .S_AXI_arsize(xbar_to_m00_couplers_ARSIZE),
        .S_AXI_arvalid(xbar_to_m00_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m00_couplers_AWADDR),
        .S_AXI_awburst(xbar_to_m00_couplers_AWBURST),
        .S_AXI_awcache(xbar_to_m00_couplers_AWCACHE),
        .S_AXI_awid(xbar_to_m00_couplers_AWID),
        .S_AXI_awlen(xbar_to_m00_couplers_AWLEN),
        .S_AXI_awlock(xbar_to_m00_couplers_AWLOCK),
        .S_AXI_awprot(xbar_to_m00_couplers_AWPROT),
        .S_AXI_awqos(xbar_to_m00_couplers_AWQOS),
        .S_AXI_awready(xbar_to_m00_couplers_AWREADY),
        .S_AXI_awsize(xbar_to_m00_couplers_AWSIZE),
        .S_AXI_awvalid(xbar_to_m00_couplers_AWVALID),
        .S_AXI_bid(xbar_to_m00_couplers_BID),
        .S_AXI_bready(xbar_to_m00_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m00_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m00_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m00_couplers_RDATA),
        .S_AXI_rid(xbar_to_m00_couplers_RID),
        .S_AXI_rlast(xbar_to_m00_couplers_RLAST),
        .S_AXI_rready(xbar_to_m00_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m00_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m00_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m00_couplers_WDATA),
        .S_AXI_wid(xbar_to_m00_couplers_WID),
        .S_AXI_wlast(xbar_to_m00_couplers_WLAST),
        .S_AXI_wready(xbar_to_m00_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m00_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m00_couplers_WVALID));
  m01_couplers_imp_DDWJU7 m01_couplers
       (.M_ACLK(M01_ACLK_1),
        .M_ARESETN(M01_ARESETN_1),
        .M_AXI_araddr(m01_couplers_to_axi_periph_ARADDR),
        .M_AXI_arburst(m01_couplers_to_axi_periph_ARBURST),
        .M_AXI_arcache(m01_couplers_to_axi_periph_ARCACHE),
        .M_AXI_arid(m01_couplers_to_axi_periph_ARID),
        .M_AXI_arlen(m01_couplers_to_axi_periph_ARLEN),
        .M_AXI_arlock(m01_couplers_to_axi_periph_ARLOCK),
        .M_AXI_arprot(m01_couplers_to_axi_periph_ARPROT),
        .M_AXI_arqos(m01_couplers_to_axi_periph_ARQOS),
        .M_AXI_arready(m01_couplers_to_axi_periph_ARREADY),
        .M_AXI_arsize(m01_couplers_to_axi_periph_ARSIZE),
        .M_AXI_arvalid(m01_couplers_to_axi_periph_ARVALID),
        .M_AXI_awaddr(m01_couplers_to_axi_periph_AWADDR),
        .M_AXI_awburst(m01_couplers_to_axi_periph_AWBURST),
        .M_AXI_awcache(m01_couplers_to_axi_periph_AWCACHE),
        .M_AXI_awid(m01_couplers_to_axi_periph_AWID),
        .M_AXI_awlen(m01_couplers_to_axi_periph_AWLEN),
        .M_AXI_awlock(m01_couplers_to_axi_periph_AWLOCK),
        .M_AXI_awprot(m01_couplers_to_axi_periph_AWPROT),
        .M_AXI_awqos(m01_couplers_to_axi_periph_AWQOS),
        .M_AXI_awready(m01_couplers_to_axi_periph_AWREADY),
        .M_AXI_awsize(m01_couplers_to_axi_periph_AWSIZE),
        .M_AXI_awvalid(m01_couplers_to_axi_periph_AWVALID),
        .M_AXI_bid(m01_couplers_to_axi_periph_BID),
        .M_AXI_bready(m01_couplers_to_axi_periph_BREADY),
        .M_AXI_bresp(m01_couplers_to_axi_periph_BRESP),
        .M_AXI_bvalid(m01_couplers_to_axi_periph_BVALID),
        .M_AXI_rdata(m01_couplers_to_axi_periph_RDATA),
        .M_AXI_rid(m01_couplers_to_axi_periph_RID),
        .M_AXI_rlast(m01_couplers_to_axi_periph_RLAST),
        .M_AXI_rready(m01_couplers_to_axi_periph_RREADY),
        .M_AXI_rresp(m01_couplers_to_axi_periph_RRESP),
        .M_AXI_rvalid(m01_couplers_to_axi_periph_RVALID),
        .M_AXI_wdata(m01_couplers_to_axi_periph_WDATA),
        .M_AXI_wid(m01_couplers_to_axi_periph_WID),
        .M_AXI_wlast(m01_couplers_to_axi_periph_WLAST),
        .M_AXI_wready(m01_couplers_to_axi_periph_WREADY),
        .M_AXI_wstrb(m01_couplers_to_axi_periph_WSTRB),
        .M_AXI_wvalid(m01_couplers_to_axi_periph_WVALID),
        .S_ACLK(axi_periph_ACLK_net),
        .S_ARESETN(axi_periph_ARESETN_net),
        .S_AXI_araddr(xbar_to_m01_couplers_ARADDR[32]),
        .S_AXI_arburst(xbar_to_m01_couplers_ARBURST[2]),
        .S_AXI_arcache(xbar_to_m01_couplers_ARCACHE[4]),
        .S_AXI_arid(xbar_to_m01_couplers_ARID[12]),
        .S_AXI_arlen(xbar_to_m01_couplers_ARLEN[4]),
        .S_AXI_arlock(xbar_to_m01_couplers_ARLOCK[2]),
        .S_AXI_arprot(xbar_to_m01_couplers_ARPROT[3]),
        .S_AXI_arqos(xbar_to_m01_couplers_ARQOS[4]),
        .S_AXI_arready(xbar_to_m01_couplers_ARREADY),
        .S_AXI_arsize(xbar_to_m01_couplers_ARSIZE[3]),
        .S_AXI_arvalid(xbar_to_m01_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m01_couplers_AWADDR[32]),
        .S_AXI_awburst(xbar_to_m01_couplers_AWBURST[2]),
        .S_AXI_awcache(xbar_to_m01_couplers_AWCACHE[4]),
        .S_AXI_awid(xbar_to_m01_couplers_AWID[12]),
        .S_AXI_awlen(xbar_to_m01_couplers_AWLEN[4]),
        .S_AXI_awlock(xbar_to_m01_couplers_AWLOCK[2]),
        .S_AXI_awprot(xbar_to_m01_couplers_AWPROT[3]),
        .S_AXI_awqos(xbar_to_m01_couplers_AWQOS[4]),
        .S_AXI_awready(xbar_to_m01_couplers_AWREADY),
        .S_AXI_awsize(xbar_to_m01_couplers_AWSIZE[3]),
        .S_AXI_awvalid(xbar_to_m01_couplers_AWVALID),
        .S_AXI_bid(xbar_to_m01_couplers_BID),
        .S_AXI_bready(xbar_to_m01_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m01_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m01_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m01_couplers_RDATA),
        .S_AXI_rid(xbar_to_m01_couplers_RID),
        .S_AXI_rlast(xbar_to_m01_couplers_RLAST),
        .S_AXI_rready(xbar_to_m01_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m01_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m01_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m01_couplers_WDATA[32]),
        .S_AXI_wid(xbar_to_m01_couplers_WID[12]),
        .S_AXI_wlast(xbar_to_m01_couplers_WLAST),
        .S_AXI_wready(xbar_to_m01_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m01_couplers_WSTRB[4]),
        .S_AXI_wvalid(xbar_to_m01_couplers_WVALID));
  m02_couplers_imp_1OOQK25 m02_couplers
       (.M_ACLK(M02_ACLK_1),
        .M_ARESETN(M02_ARESETN_1),
        .M_AXI_araddr(m02_couplers_to_axi_periph_ARADDR),
        .M_AXI_arready(m02_couplers_to_axi_periph_ARREADY),
        .M_AXI_arvalid(m02_couplers_to_axi_periph_ARVALID),
        .M_AXI_awaddr(m02_couplers_to_axi_periph_AWADDR),
        .M_AXI_awready(m02_couplers_to_axi_periph_AWREADY),
        .M_AXI_awvalid(m02_couplers_to_axi_periph_AWVALID),
        .M_AXI_bready(m02_couplers_to_axi_periph_BREADY),
        .M_AXI_bresp(m02_couplers_to_axi_periph_BRESP),
        .M_AXI_bvalid(m02_couplers_to_axi_periph_BVALID),
        .M_AXI_rdata(m02_couplers_to_axi_periph_RDATA),
        .M_AXI_rready(m02_couplers_to_axi_periph_RREADY),
        .M_AXI_rresp(m02_couplers_to_axi_periph_RRESP),
        .M_AXI_rvalid(m02_couplers_to_axi_periph_RVALID),
        .M_AXI_wdata(m02_couplers_to_axi_periph_WDATA),
        .M_AXI_wready(m02_couplers_to_axi_periph_WREADY),
        .M_AXI_wstrb(m02_couplers_to_axi_periph_WSTRB),
        .M_AXI_wvalid(m02_couplers_to_axi_periph_WVALID),
        .S_ACLK(axi_periph_ACLK_net),
        .S_ARESETN(axi_periph_ARESETN_net),
        .S_AXI_araddr(xbar_to_m02_couplers_ARADDR),
        .S_AXI_arburst(xbar_to_m02_couplers_ARBURST),
        .S_AXI_arcache(xbar_to_m02_couplers_ARCACHE),
        .S_AXI_arid(xbar_to_m02_couplers_ARID),
        .S_AXI_arlen(xbar_to_m02_couplers_ARLEN),
        .S_AXI_arlock(xbar_to_m02_couplers_ARLOCK),
        .S_AXI_arprot(xbar_to_m02_couplers_ARPROT),
        .S_AXI_arqos(xbar_to_m02_couplers_ARQOS),
        .S_AXI_arready(xbar_to_m02_couplers_ARREADY),
        .S_AXI_arsize(xbar_to_m02_couplers_ARSIZE),
        .S_AXI_arvalid(xbar_to_m02_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m02_couplers_AWADDR),
        .S_AXI_awburst(xbar_to_m02_couplers_AWBURST),
        .S_AXI_awcache(xbar_to_m02_couplers_AWCACHE),
        .S_AXI_awid(xbar_to_m02_couplers_AWID),
        .S_AXI_awlen(xbar_to_m02_couplers_AWLEN),
        .S_AXI_awlock(xbar_to_m02_couplers_AWLOCK),
        .S_AXI_awprot(xbar_to_m02_couplers_AWPROT),
        .S_AXI_awqos(xbar_to_m02_couplers_AWQOS),
        .S_AXI_awready(xbar_to_m02_couplers_AWREADY),
        .S_AXI_awsize(xbar_to_m02_couplers_AWSIZE),
        .S_AXI_awvalid(xbar_to_m02_couplers_AWVALID),
        .S_AXI_bid(xbar_to_m02_couplers_BID),
        .S_AXI_bready(xbar_to_m02_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m02_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m02_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m02_couplers_RDATA),
        .S_AXI_rid(xbar_to_m02_couplers_RID),
        .S_AXI_rlast(xbar_to_m02_couplers_RLAST),
        .S_AXI_rready(xbar_to_m02_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m02_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m02_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m02_couplers_WDATA),
        .S_AXI_wid(xbar_to_m02_couplers_WID),
        .S_AXI_wlast(xbar_to_m02_couplers_WLAST),
        .S_AXI_wready(xbar_to_m02_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m02_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m02_couplers_WVALID));
  s00_couplers_imp_AMT4UK s00_couplers
       (.M_ACLK(axi_periph_ACLK_net),
        .M_ARESETN(axi_periph_ARESETN_net),
        .M_AXI_araddr(s00_couplers_to_xbar_ARADDR),
        .M_AXI_arburst(s00_couplers_to_xbar_ARBURST),
        .M_AXI_arcache(s00_couplers_to_xbar_ARCACHE),
        .M_AXI_arid(s00_couplers_to_xbar_ARID),
        .M_AXI_arlen(s00_couplers_to_xbar_ARLEN),
        .M_AXI_arlock(s00_couplers_to_xbar_ARLOCK),
        .M_AXI_arprot(s00_couplers_to_xbar_ARPROT),
        .M_AXI_arqos(s00_couplers_to_xbar_ARQOS),
        .M_AXI_arready(s00_couplers_to_xbar_ARREADY),
        .M_AXI_arsize(s00_couplers_to_xbar_ARSIZE),
        .M_AXI_arvalid(s00_couplers_to_xbar_ARVALID),
        .M_AXI_awaddr(s00_couplers_to_xbar_AWADDR),
        .M_AXI_awburst(s00_couplers_to_xbar_AWBURST),
        .M_AXI_awcache(s00_couplers_to_xbar_AWCACHE),
        .M_AXI_awid(s00_couplers_to_xbar_AWID),
        .M_AXI_awlen(s00_couplers_to_xbar_AWLEN),
        .M_AXI_awlock(s00_couplers_to_xbar_AWLOCK),
        .M_AXI_awprot(s00_couplers_to_xbar_AWPROT),
        .M_AXI_awqos(s00_couplers_to_xbar_AWQOS),
        .M_AXI_awready(s00_couplers_to_xbar_AWREADY),
        .M_AXI_awsize(s00_couplers_to_xbar_AWSIZE),
        .M_AXI_awvalid(s00_couplers_to_xbar_AWVALID),
        .M_AXI_bid(s00_couplers_to_xbar_BID),
        .M_AXI_bready(s00_couplers_to_xbar_BREADY),
        .M_AXI_bresp(s00_couplers_to_xbar_BRESP),
        .M_AXI_bvalid(s00_couplers_to_xbar_BVALID),
        .M_AXI_rdata(s00_couplers_to_xbar_RDATA),
        .M_AXI_rid(s00_couplers_to_xbar_RID),
        .M_AXI_rlast(s00_couplers_to_xbar_RLAST),
        .M_AXI_rready(s00_couplers_to_xbar_RREADY),
        .M_AXI_rresp(s00_couplers_to_xbar_RRESP),
        .M_AXI_rvalid(s00_couplers_to_xbar_RVALID),
        .M_AXI_wdata(s00_couplers_to_xbar_WDATA),
        .M_AXI_wid(s00_couplers_to_xbar_WID),
        .M_AXI_wlast(s00_couplers_to_xbar_WLAST),
        .M_AXI_wready(s00_couplers_to_xbar_WREADY),
        .M_AXI_wstrb(s00_couplers_to_xbar_WSTRB),
        .M_AXI_wvalid(s00_couplers_to_xbar_WVALID),
        .S_ACLK(S00_ACLK_1),
        .S_ARESETN(S00_ARESETN_1),
        .S_AXI_araddr(axi_periph_to_s00_couplers_ARADDR),
        .S_AXI_arburst(axi_periph_to_s00_couplers_ARBURST),
        .S_AXI_arcache(axi_periph_to_s00_couplers_ARCACHE),
        .S_AXI_arid(axi_periph_to_s00_couplers_ARID),
        .S_AXI_arlen(axi_periph_to_s00_couplers_ARLEN),
        .S_AXI_arlock(axi_periph_to_s00_couplers_ARLOCK),
        .S_AXI_arprot(axi_periph_to_s00_couplers_ARPROT),
        .S_AXI_arqos(axi_periph_to_s00_couplers_ARQOS),
        .S_AXI_arready(axi_periph_to_s00_couplers_ARREADY),
        .S_AXI_arsize(axi_periph_to_s00_couplers_ARSIZE),
        .S_AXI_arvalid(axi_periph_to_s00_couplers_ARVALID),
        .S_AXI_awaddr(axi_periph_to_s00_couplers_AWADDR),
        .S_AXI_awburst(axi_periph_to_s00_couplers_AWBURST),
        .S_AXI_awcache(axi_periph_to_s00_couplers_AWCACHE),
        .S_AXI_awid(axi_periph_to_s00_couplers_AWID),
        .S_AXI_awlen(axi_periph_to_s00_couplers_AWLEN),
        .S_AXI_awlock(axi_periph_to_s00_couplers_AWLOCK),
        .S_AXI_awprot(axi_periph_to_s00_couplers_AWPROT),
        .S_AXI_awqos(axi_periph_to_s00_couplers_AWQOS),
        .S_AXI_awready(axi_periph_to_s00_couplers_AWREADY),
        .S_AXI_awsize(axi_periph_to_s00_couplers_AWSIZE),
        .S_AXI_awvalid(axi_periph_to_s00_couplers_AWVALID),
        .S_AXI_bid(axi_periph_to_s00_couplers_BID),
        .S_AXI_bready(axi_periph_to_s00_couplers_BREADY),
        .S_AXI_bresp(axi_periph_to_s00_couplers_BRESP),
        .S_AXI_bvalid(axi_periph_to_s00_couplers_BVALID),
        .S_AXI_rdata(axi_periph_to_s00_couplers_RDATA),
        .S_AXI_rid(axi_periph_to_s00_couplers_RID),
        .S_AXI_rlast(axi_periph_to_s00_couplers_RLAST),
        .S_AXI_rready(axi_periph_to_s00_couplers_RREADY),
        .S_AXI_rresp(axi_periph_to_s00_couplers_RRESP),
        .S_AXI_rvalid(axi_periph_to_s00_couplers_RVALID),
        .S_AXI_wdata(axi_periph_to_s00_couplers_WDATA),
        .S_AXI_wid(axi_periph_to_s00_couplers_WID),
        .S_AXI_wlast(axi_periph_to_s00_couplers_WLAST),
        .S_AXI_wready(axi_periph_to_s00_couplers_WREADY),
        .S_AXI_wstrb(axi_periph_to_s00_couplers_WSTRB),
        .S_AXI_wvalid(axi_periph_to_s00_couplers_WVALID));
  design_1_xbar_0 xbar
       (.aclk(axi_periph_ACLK_net),
        .aresetn(axi_periph_ARESETN_net),
        .m_axi_araddr({xbar_to_m02_couplers_ARADDR,xbar_to_m01_couplers_ARADDR,xbar_to_m00_couplers_ARADDR}),
        .m_axi_arburst({xbar_to_m02_couplers_ARBURST,xbar_to_m01_couplers_ARBURST,xbar_to_m00_couplers_ARBURST}),
        .m_axi_arcache({xbar_to_m02_couplers_ARCACHE,xbar_to_m01_couplers_ARCACHE,xbar_to_m00_couplers_ARCACHE}),
        .m_axi_arid({xbar_to_m02_couplers_ARID,xbar_to_m01_couplers_ARID,xbar_to_m00_couplers_ARID}),
        .m_axi_arlen({xbar_to_m02_couplers_ARLEN,xbar_to_m01_couplers_ARLEN,xbar_to_m00_couplers_ARLEN}),
        .m_axi_arlock({xbar_to_m02_couplers_ARLOCK,xbar_to_m01_couplers_ARLOCK,xbar_to_m00_couplers_ARLOCK}),
        .m_axi_arprot({xbar_to_m02_couplers_ARPROT,xbar_to_m01_couplers_ARPROT,xbar_to_m00_couplers_ARPROT}),
        .m_axi_arqos({xbar_to_m02_couplers_ARQOS,xbar_to_m01_couplers_ARQOS,xbar_to_m00_couplers_ARQOS}),
        .m_axi_arready({xbar_to_m02_couplers_ARREADY,xbar_to_m01_couplers_ARREADY,xbar_to_m00_couplers_ARREADY}),
        .m_axi_arsize({xbar_to_m02_couplers_ARSIZE,xbar_to_m01_couplers_ARSIZE,xbar_to_m00_couplers_ARSIZE}),
        .m_axi_arvalid({xbar_to_m02_couplers_ARVALID,xbar_to_m01_couplers_ARVALID,xbar_to_m00_couplers_ARVALID}),
        .m_axi_awaddr({xbar_to_m02_couplers_AWADDR,xbar_to_m01_couplers_AWADDR,xbar_to_m00_couplers_AWADDR}),
        .m_axi_awburst({xbar_to_m02_couplers_AWBURST,xbar_to_m01_couplers_AWBURST,xbar_to_m00_couplers_AWBURST}),
        .m_axi_awcache({xbar_to_m02_couplers_AWCACHE,xbar_to_m01_couplers_AWCACHE,xbar_to_m00_couplers_AWCACHE}),
        .m_axi_awid({xbar_to_m02_couplers_AWID,xbar_to_m01_couplers_AWID,xbar_to_m00_couplers_AWID}),
        .m_axi_awlen({xbar_to_m02_couplers_AWLEN,xbar_to_m01_couplers_AWLEN,xbar_to_m00_couplers_AWLEN}),
        .m_axi_awlock({xbar_to_m02_couplers_AWLOCK,xbar_to_m01_couplers_AWLOCK,xbar_to_m00_couplers_AWLOCK}),
        .m_axi_awprot({xbar_to_m02_couplers_AWPROT,xbar_to_m01_couplers_AWPROT,xbar_to_m00_couplers_AWPROT}),
        .m_axi_awqos({xbar_to_m02_couplers_AWQOS,xbar_to_m01_couplers_AWQOS,xbar_to_m00_couplers_AWQOS}),
        .m_axi_awready({xbar_to_m02_couplers_AWREADY,xbar_to_m01_couplers_AWREADY,xbar_to_m00_couplers_AWREADY}),
        .m_axi_awsize({xbar_to_m02_couplers_AWSIZE,xbar_to_m01_couplers_AWSIZE,xbar_to_m00_couplers_AWSIZE}),
        .m_axi_awvalid({xbar_to_m02_couplers_AWVALID,xbar_to_m01_couplers_AWVALID,xbar_to_m00_couplers_AWVALID}),
        .m_axi_bid({xbar_to_m02_couplers_BID,xbar_to_m01_couplers_BID,xbar_to_m01_couplers_BID,xbar_to_m01_couplers_BID,xbar_to_m01_couplers_BID,xbar_to_m01_couplers_BID,xbar_to_m01_couplers_BID,xbar_to_m01_couplers_BID,xbar_to_m01_couplers_BID,xbar_to_m01_couplers_BID,xbar_to_m01_couplers_BID,xbar_to_m01_couplers_BID,xbar_to_m01_couplers_BID,xbar_to_m00_couplers_BID}),
        .m_axi_bready({xbar_to_m02_couplers_BREADY,xbar_to_m01_couplers_BREADY,xbar_to_m00_couplers_BREADY}),
        .m_axi_bresp({xbar_to_m02_couplers_BRESP,xbar_to_m01_couplers_BRESP,xbar_to_m01_couplers_BRESP,xbar_to_m00_couplers_BRESP}),
        .m_axi_bvalid({xbar_to_m02_couplers_BVALID,xbar_to_m01_couplers_BVALID,xbar_to_m00_couplers_BVALID}),
        .m_axi_rdata({xbar_to_m02_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m01_couplers_RDATA,xbar_to_m00_couplers_RDATA}),
        .m_axi_rid({xbar_to_m02_couplers_RID,xbar_to_m01_couplers_RID,xbar_to_m01_couplers_RID,xbar_to_m01_couplers_RID,xbar_to_m01_couplers_RID,xbar_to_m01_couplers_RID,xbar_to_m01_couplers_RID,xbar_to_m01_couplers_RID,xbar_to_m01_couplers_RID,xbar_to_m01_couplers_RID,xbar_to_m01_couplers_RID,xbar_to_m01_couplers_RID,xbar_to_m01_couplers_RID,xbar_to_m00_couplers_RID}),
        .m_axi_rlast({xbar_to_m02_couplers_RLAST,xbar_to_m01_couplers_RLAST,xbar_to_m00_couplers_RLAST}),
        .m_axi_rready({xbar_to_m02_couplers_RREADY,xbar_to_m01_couplers_RREADY,xbar_to_m00_couplers_RREADY}),
        .m_axi_rresp({xbar_to_m02_couplers_RRESP,xbar_to_m01_couplers_RRESP,xbar_to_m01_couplers_RRESP,xbar_to_m00_couplers_RRESP}),
        .m_axi_rvalid({xbar_to_m02_couplers_RVALID,xbar_to_m01_couplers_RVALID,xbar_to_m00_couplers_RVALID}),
        .m_axi_wdata({xbar_to_m02_couplers_WDATA,xbar_to_m01_couplers_WDATA,xbar_to_m00_couplers_WDATA}),
        .m_axi_wid({xbar_to_m02_couplers_WID,xbar_to_m01_couplers_WID,xbar_to_m00_couplers_WID}),
        .m_axi_wlast({xbar_to_m02_couplers_WLAST,xbar_to_m01_couplers_WLAST,xbar_to_m00_couplers_WLAST}),
        .m_axi_wready({xbar_to_m02_couplers_WREADY,xbar_to_m01_couplers_WREADY,xbar_to_m00_couplers_WREADY}),
        .m_axi_wstrb({xbar_to_m02_couplers_WSTRB,xbar_to_m01_couplers_WSTRB,xbar_to_m00_couplers_WSTRB}),
        .m_axi_wvalid({xbar_to_m02_couplers_WVALID,xbar_to_m01_couplers_WVALID,xbar_to_m00_couplers_WVALID}),
        .s_axi_araddr(s00_couplers_to_xbar_ARADDR),
        .s_axi_arburst(s00_couplers_to_xbar_ARBURST),
        .s_axi_arcache(s00_couplers_to_xbar_ARCACHE),
        .s_axi_arid(s00_couplers_to_xbar_ARID),
        .s_axi_arlen(s00_couplers_to_xbar_ARLEN),
        .s_axi_arlock(s00_couplers_to_xbar_ARLOCK),
        .s_axi_arprot(s00_couplers_to_xbar_ARPROT),
        .s_axi_arqos(s00_couplers_to_xbar_ARQOS),
        .s_axi_arready(s00_couplers_to_xbar_ARREADY),
        .s_axi_arsize(s00_couplers_to_xbar_ARSIZE),
        .s_axi_arvalid(s00_couplers_to_xbar_ARVALID),
        .s_axi_awaddr(s00_couplers_to_xbar_AWADDR),
        .s_axi_awburst(s00_couplers_to_xbar_AWBURST),
        .s_axi_awcache(s00_couplers_to_xbar_AWCACHE),
        .s_axi_awid(s00_couplers_to_xbar_AWID),
        .s_axi_awlen(s00_couplers_to_xbar_AWLEN),
        .s_axi_awlock(s00_couplers_to_xbar_AWLOCK),
        .s_axi_awprot(s00_couplers_to_xbar_AWPROT),
        .s_axi_awqos(s00_couplers_to_xbar_AWQOS),
        .s_axi_awready(s00_couplers_to_xbar_AWREADY),
        .s_axi_awsize(s00_couplers_to_xbar_AWSIZE),
        .s_axi_awvalid(s00_couplers_to_xbar_AWVALID),
        .s_axi_bid(s00_couplers_to_xbar_BID),
        .s_axi_bready(s00_couplers_to_xbar_BREADY),
        .s_axi_bresp(s00_couplers_to_xbar_BRESP),
        .s_axi_bvalid(s00_couplers_to_xbar_BVALID),
        .s_axi_rdata(s00_couplers_to_xbar_RDATA),
        .s_axi_rid(s00_couplers_to_xbar_RID),
        .s_axi_rlast(s00_couplers_to_xbar_RLAST),
        .s_axi_rready(s00_couplers_to_xbar_RREADY),
        .s_axi_rresp(s00_couplers_to_xbar_RRESP),
        .s_axi_rvalid(s00_couplers_to_xbar_RVALID),
        .s_axi_wdata(s00_couplers_to_xbar_WDATA),
        .s_axi_wid(s00_couplers_to_xbar_WID),
        .s_axi_wlast(s00_couplers_to_xbar_WLAST),
        .s_axi_wready(s00_couplers_to_xbar_WREADY),
        .s_axi_wstrb(s00_couplers_to_xbar_WSTRB),
        .s_axi_wvalid(s00_couplers_to_xbar_WVALID));
endmodule

module m00_couplers_imp_1PZPB4E
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arburst,
    M_AXI_arcache,
    M_AXI_arid,
    M_AXI_arlen,
    M_AXI_arlock,
    M_AXI_arprot,
    M_AXI_arqos,
    M_AXI_arready,
    M_AXI_arsize,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awburst,
    M_AXI_awcache,
    M_AXI_awid,
    M_AXI_awlen,
    M_AXI_awlock,
    M_AXI_awprot,
    M_AXI_awqos,
    M_AXI_awready,
    M_AXI_awsize,
    M_AXI_awvalid,
    M_AXI_bid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rid,
    M_AXI_rlast,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wid,
    M_AXI_wlast,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arcache,
    S_AXI_arid,
    S_AXI_arlen,
    S_AXI_arlock,
    S_AXI_arprot,
    S_AXI_arqos,
    S_AXI_arready,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awid,
    S_AXI_awlen,
    S_AXI_awlock,
    S_AXI_awprot,
    S_AXI_awqos,
    S_AXI_awready,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rid,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wid,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [1:0]M_AXI_arburst;
  output [3:0]M_AXI_arcache;
  output [11:0]M_AXI_arid;
  output [3:0]M_AXI_arlen;
  output [1:0]M_AXI_arlock;
  output [2:0]M_AXI_arprot;
  output [3:0]M_AXI_arqos;
  input M_AXI_arready;
  output [2:0]M_AXI_arsize;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  output [1:0]M_AXI_awburst;
  output [3:0]M_AXI_awcache;
  output [11:0]M_AXI_awid;
  output [3:0]M_AXI_awlen;
  output [1:0]M_AXI_awlock;
  output [2:0]M_AXI_awprot;
  output [3:0]M_AXI_awqos;
  input M_AXI_awready;
  output [2:0]M_AXI_awsize;
  output M_AXI_awvalid;
  input [11:0]M_AXI_bid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  input [11:0]M_AXI_rid;
  input M_AXI_rlast;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  output [11:0]M_AXI_wid;
  output M_AXI_wlast;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [1:0]S_AXI_arburst;
  input [3:0]S_AXI_arcache;
  input [11:0]S_AXI_arid;
  input [3:0]S_AXI_arlen;
  input [1:0]S_AXI_arlock;
  input [2:0]S_AXI_arprot;
  input [3:0]S_AXI_arqos;
  output S_AXI_arready;
  input [2:0]S_AXI_arsize;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [1:0]S_AXI_awburst;
  input [3:0]S_AXI_awcache;
  input [11:0]S_AXI_awid;
  input [3:0]S_AXI_awlen;
  input [1:0]S_AXI_awlock;
  input [2:0]S_AXI_awprot;
  input [3:0]S_AXI_awqos;
  output S_AXI_awready;
  input [2:0]S_AXI_awsize;
  input S_AXI_awvalid;
  output [11:0]S_AXI_bid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  output [11:0]S_AXI_rid;
  output S_AXI_rlast;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  input [11:0]S_AXI_wid;
  input S_AXI_wlast;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire M_ACLK_1;
  wire M_ARESETN_1;
  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_cc_to_m00_couplers_ARADDR;
  wire [1:0]auto_cc_to_m00_couplers_ARBURST;
  wire [3:0]auto_cc_to_m00_couplers_ARCACHE;
  wire [11:0]auto_cc_to_m00_couplers_ARID;
  wire [3:0]auto_cc_to_m00_couplers_ARLEN;
  wire [1:0]auto_cc_to_m00_couplers_ARLOCK;
  wire [2:0]auto_cc_to_m00_couplers_ARPROT;
  wire [3:0]auto_cc_to_m00_couplers_ARQOS;
  wire auto_cc_to_m00_couplers_ARREADY;
  wire [2:0]auto_cc_to_m00_couplers_ARSIZE;
  wire auto_cc_to_m00_couplers_ARVALID;
  wire [31:0]auto_cc_to_m00_couplers_AWADDR;
  wire [1:0]auto_cc_to_m00_couplers_AWBURST;
  wire [3:0]auto_cc_to_m00_couplers_AWCACHE;
  wire [11:0]auto_cc_to_m00_couplers_AWID;
  wire [3:0]auto_cc_to_m00_couplers_AWLEN;
  wire [1:0]auto_cc_to_m00_couplers_AWLOCK;
  wire [2:0]auto_cc_to_m00_couplers_AWPROT;
  wire [3:0]auto_cc_to_m00_couplers_AWQOS;
  wire auto_cc_to_m00_couplers_AWREADY;
  wire [2:0]auto_cc_to_m00_couplers_AWSIZE;
  wire auto_cc_to_m00_couplers_AWVALID;
  wire [11:0]auto_cc_to_m00_couplers_BID;
  wire auto_cc_to_m00_couplers_BREADY;
  wire [1:0]auto_cc_to_m00_couplers_BRESP;
  wire auto_cc_to_m00_couplers_BVALID;
  wire [31:0]auto_cc_to_m00_couplers_RDATA;
  wire [11:0]auto_cc_to_m00_couplers_RID;
  wire auto_cc_to_m00_couplers_RLAST;
  wire auto_cc_to_m00_couplers_RREADY;
  wire [1:0]auto_cc_to_m00_couplers_RRESP;
  wire auto_cc_to_m00_couplers_RVALID;
  wire [31:0]auto_cc_to_m00_couplers_WDATA;
  wire [11:0]auto_cc_to_m00_couplers_WID;
  wire auto_cc_to_m00_couplers_WLAST;
  wire auto_cc_to_m00_couplers_WREADY;
  wire [3:0]auto_cc_to_m00_couplers_WSTRB;
  wire auto_cc_to_m00_couplers_WVALID;
  wire [31:0]m00_couplers_to_auto_cc_ARADDR;
  wire [1:0]m00_couplers_to_auto_cc_ARBURST;
  wire [3:0]m00_couplers_to_auto_cc_ARCACHE;
  wire [11:0]m00_couplers_to_auto_cc_ARID;
  wire [3:0]m00_couplers_to_auto_cc_ARLEN;
  wire [1:0]m00_couplers_to_auto_cc_ARLOCK;
  wire [2:0]m00_couplers_to_auto_cc_ARPROT;
  wire [3:0]m00_couplers_to_auto_cc_ARQOS;
  wire m00_couplers_to_auto_cc_ARREADY;
  wire [2:0]m00_couplers_to_auto_cc_ARSIZE;
  wire m00_couplers_to_auto_cc_ARVALID;
  wire [31:0]m00_couplers_to_auto_cc_AWADDR;
  wire [1:0]m00_couplers_to_auto_cc_AWBURST;
  wire [3:0]m00_couplers_to_auto_cc_AWCACHE;
  wire [11:0]m00_couplers_to_auto_cc_AWID;
  wire [3:0]m00_couplers_to_auto_cc_AWLEN;
  wire [1:0]m00_couplers_to_auto_cc_AWLOCK;
  wire [2:0]m00_couplers_to_auto_cc_AWPROT;
  wire [3:0]m00_couplers_to_auto_cc_AWQOS;
  wire m00_couplers_to_auto_cc_AWREADY;
  wire [2:0]m00_couplers_to_auto_cc_AWSIZE;
  wire m00_couplers_to_auto_cc_AWVALID;
  wire [11:0]m00_couplers_to_auto_cc_BID;
  wire m00_couplers_to_auto_cc_BREADY;
  wire [1:0]m00_couplers_to_auto_cc_BRESP;
  wire m00_couplers_to_auto_cc_BVALID;
  wire [31:0]m00_couplers_to_auto_cc_RDATA;
  wire [11:0]m00_couplers_to_auto_cc_RID;
  wire m00_couplers_to_auto_cc_RLAST;
  wire m00_couplers_to_auto_cc_RREADY;
  wire [1:0]m00_couplers_to_auto_cc_RRESP;
  wire m00_couplers_to_auto_cc_RVALID;
  wire [31:0]m00_couplers_to_auto_cc_WDATA;
  wire [11:0]m00_couplers_to_auto_cc_WID;
  wire m00_couplers_to_auto_cc_WLAST;
  wire m00_couplers_to_auto_cc_WREADY;
  wire [3:0]m00_couplers_to_auto_cc_WSTRB;
  wire m00_couplers_to_auto_cc_WVALID;

  assign M_ACLK_1 = M_ACLK;
  assign M_ARESETN_1 = M_ARESETN;
  assign M_AXI_araddr[31:0] = auto_cc_to_m00_couplers_ARADDR;
  assign M_AXI_arburst[1:0] = auto_cc_to_m00_couplers_ARBURST;
  assign M_AXI_arcache[3:0] = auto_cc_to_m00_couplers_ARCACHE;
  assign M_AXI_arid[11:0] = auto_cc_to_m00_couplers_ARID;
  assign M_AXI_arlen[3:0] = auto_cc_to_m00_couplers_ARLEN;
  assign M_AXI_arlock[1:0] = auto_cc_to_m00_couplers_ARLOCK;
  assign M_AXI_arprot[2:0] = auto_cc_to_m00_couplers_ARPROT;
  assign M_AXI_arqos[3:0] = auto_cc_to_m00_couplers_ARQOS;
  assign M_AXI_arsize[2:0] = auto_cc_to_m00_couplers_ARSIZE;
  assign M_AXI_arvalid = auto_cc_to_m00_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = auto_cc_to_m00_couplers_AWADDR;
  assign M_AXI_awburst[1:0] = auto_cc_to_m00_couplers_AWBURST;
  assign M_AXI_awcache[3:0] = auto_cc_to_m00_couplers_AWCACHE;
  assign M_AXI_awid[11:0] = auto_cc_to_m00_couplers_AWID;
  assign M_AXI_awlen[3:0] = auto_cc_to_m00_couplers_AWLEN;
  assign M_AXI_awlock[1:0] = auto_cc_to_m00_couplers_AWLOCK;
  assign M_AXI_awprot[2:0] = auto_cc_to_m00_couplers_AWPROT;
  assign M_AXI_awqos[3:0] = auto_cc_to_m00_couplers_AWQOS;
  assign M_AXI_awsize[2:0] = auto_cc_to_m00_couplers_AWSIZE;
  assign M_AXI_awvalid = auto_cc_to_m00_couplers_AWVALID;
  assign M_AXI_bready = auto_cc_to_m00_couplers_BREADY;
  assign M_AXI_rready = auto_cc_to_m00_couplers_RREADY;
  assign M_AXI_wdata[31:0] = auto_cc_to_m00_couplers_WDATA;
  assign M_AXI_wid[11:0] = auto_cc_to_m00_couplers_WID;
  assign M_AXI_wlast = auto_cc_to_m00_couplers_WLAST;
  assign M_AXI_wstrb[3:0] = auto_cc_to_m00_couplers_WSTRB;
  assign M_AXI_wvalid = auto_cc_to_m00_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = m00_couplers_to_auto_cc_ARREADY;
  assign S_AXI_awready = m00_couplers_to_auto_cc_AWREADY;
  assign S_AXI_bid[11:0] = m00_couplers_to_auto_cc_BID;
  assign S_AXI_bresp[1:0] = m00_couplers_to_auto_cc_BRESP;
  assign S_AXI_bvalid = m00_couplers_to_auto_cc_BVALID;
  assign S_AXI_rdata[31:0] = m00_couplers_to_auto_cc_RDATA;
  assign S_AXI_rid[11:0] = m00_couplers_to_auto_cc_RID;
  assign S_AXI_rlast = m00_couplers_to_auto_cc_RLAST;
  assign S_AXI_rresp[1:0] = m00_couplers_to_auto_cc_RRESP;
  assign S_AXI_rvalid = m00_couplers_to_auto_cc_RVALID;
  assign S_AXI_wready = m00_couplers_to_auto_cc_WREADY;
  assign auto_cc_to_m00_couplers_ARREADY = M_AXI_arready;
  assign auto_cc_to_m00_couplers_AWREADY = M_AXI_awready;
  assign auto_cc_to_m00_couplers_BID = M_AXI_bid[11:0];
  assign auto_cc_to_m00_couplers_BRESP = M_AXI_bresp[1:0];
  assign auto_cc_to_m00_couplers_BVALID = M_AXI_bvalid;
  assign auto_cc_to_m00_couplers_RDATA = M_AXI_rdata[31:0];
  assign auto_cc_to_m00_couplers_RID = M_AXI_rid[11:0];
  assign auto_cc_to_m00_couplers_RLAST = M_AXI_rlast;
  assign auto_cc_to_m00_couplers_RRESP = M_AXI_rresp[1:0];
  assign auto_cc_to_m00_couplers_RVALID = M_AXI_rvalid;
  assign auto_cc_to_m00_couplers_WREADY = M_AXI_wready;
  assign m00_couplers_to_auto_cc_ARADDR = S_AXI_araddr[31:0];
  assign m00_couplers_to_auto_cc_ARBURST = S_AXI_arburst[1:0];
  assign m00_couplers_to_auto_cc_ARCACHE = S_AXI_arcache[3:0];
  assign m00_couplers_to_auto_cc_ARID = S_AXI_arid[11:0];
  assign m00_couplers_to_auto_cc_ARLEN = S_AXI_arlen[3:0];
  assign m00_couplers_to_auto_cc_ARLOCK = S_AXI_arlock[1:0];
  assign m00_couplers_to_auto_cc_ARPROT = S_AXI_arprot[2:0];
  assign m00_couplers_to_auto_cc_ARQOS = S_AXI_arqos[3:0];
  assign m00_couplers_to_auto_cc_ARSIZE = S_AXI_arsize[2:0];
  assign m00_couplers_to_auto_cc_ARVALID = S_AXI_arvalid;
  assign m00_couplers_to_auto_cc_AWADDR = S_AXI_awaddr[31:0];
  assign m00_couplers_to_auto_cc_AWBURST = S_AXI_awburst[1:0];
  assign m00_couplers_to_auto_cc_AWCACHE = S_AXI_awcache[3:0];
  assign m00_couplers_to_auto_cc_AWID = S_AXI_awid[11:0];
  assign m00_couplers_to_auto_cc_AWLEN = S_AXI_awlen[3:0];
  assign m00_couplers_to_auto_cc_AWLOCK = S_AXI_awlock[1:0];
  assign m00_couplers_to_auto_cc_AWPROT = S_AXI_awprot[2:0];
  assign m00_couplers_to_auto_cc_AWQOS = S_AXI_awqos[3:0];
  assign m00_couplers_to_auto_cc_AWSIZE = S_AXI_awsize[2:0];
  assign m00_couplers_to_auto_cc_AWVALID = S_AXI_awvalid;
  assign m00_couplers_to_auto_cc_BREADY = S_AXI_bready;
  assign m00_couplers_to_auto_cc_RREADY = S_AXI_rready;
  assign m00_couplers_to_auto_cc_WDATA = S_AXI_wdata[31:0];
  assign m00_couplers_to_auto_cc_WID = S_AXI_wid[11:0];
  assign m00_couplers_to_auto_cc_WLAST = S_AXI_wlast;
  assign m00_couplers_to_auto_cc_WSTRB = S_AXI_wstrb[3:0];
  assign m00_couplers_to_auto_cc_WVALID = S_AXI_wvalid;
  design_1_auto_cc_0 auto_cc
       (.m_axi_aclk(M_ACLK_1),
        .m_axi_araddr(auto_cc_to_m00_couplers_ARADDR),
        .m_axi_arburst(auto_cc_to_m00_couplers_ARBURST),
        .m_axi_arcache(auto_cc_to_m00_couplers_ARCACHE),
        .m_axi_aresetn(M_ARESETN_1),
        .m_axi_arid(auto_cc_to_m00_couplers_ARID),
        .m_axi_arlen(auto_cc_to_m00_couplers_ARLEN),
        .m_axi_arlock(auto_cc_to_m00_couplers_ARLOCK),
        .m_axi_arprot(auto_cc_to_m00_couplers_ARPROT),
        .m_axi_arqos(auto_cc_to_m00_couplers_ARQOS),
        .m_axi_arready(auto_cc_to_m00_couplers_ARREADY),
        .m_axi_arsize(auto_cc_to_m00_couplers_ARSIZE),
        .m_axi_arvalid(auto_cc_to_m00_couplers_ARVALID),
        .m_axi_awaddr(auto_cc_to_m00_couplers_AWADDR),
        .m_axi_awburst(auto_cc_to_m00_couplers_AWBURST),
        .m_axi_awcache(auto_cc_to_m00_couplers_AWCACHE),
        .m_axi_awid(auto_cc_to_m00_couplers_AWID),
        .m_axi_awlen(auto_cc_to_m00_couplers_AWLEN),
        .m_axi_awlock(auto_cc_to_m00_couplers_AWLOCK),
        .m_axi_awprot(auto_cc_to_m00_couplers_AWPROT),
        .m_axi_awqos(auto_cc_to_m00_couplers_AWQOS),
        .m_axi_awready(auto_cc_to_m00_couplers_AWREADY),
        .m_axi_awsize(auto_cc_to_m00_couplers_AWSIZE),
        .m_axi_awvalid(auto_cc_to_m00_couplers_AWVALID),
        .m_axi_bid(auto_cc_to_m00_couplers_BID),
        .m_axi_bready(auto_cc_to_m00_couplers_BREADY),
        .m_axi_bresp(auto_cc_to_m00_couplers_BRESP),
        .m_axi_bvalid(auto_cc_to_m00_couplers_BVALID),
        .m_axi_rdata(auto_cc_to_m00_couplers_RDATA),
        .m_axi_rid(auto_cc_to_m00_couplers_RID),
        .m_axi_rlast(auto_cc_to_m00_couplers_RLAST),
        .m_axi_rready(auto_cc_to_m00_couplers_RREADY),
        .m_axi_rresp(auto_cc_to_m00_couplers_RRESP),
        .m_axi_rvalid(auto_cc_to_m00_couplers_RVALID),
        .m_axi_wdata(auto_cc_to_m00_couplers_WDATA),
        .m_axi_wid(auto_cc_to_m00_couplers_WID),
        .m_axi_wlast(auto_cc_to_m00_couplers_WLAST),
        .m_axi_wready(auto_cc_to_m00_couplers_WREADY),
        .m_axi_wstrb(auto_cc_to_m00_couplers_WSTRB),
        .m_axi_wvalid(auto_cc_to_m00_couplers_WVALID),
        .s_axi_aclk(S_ACLK_1),
        .s_axi_araddr(m00_couplers_to_auto_cc_ARADDR),
        .s_axi_arburst(m00_couplers_to_auto_cc_ARBURST),
        .s_axi_arcache(m00_couplers_to_auto_cc_ARCACHE),
        .s_axi_aresetn(S_ARESETN_1),
        .s_axi_arid(m00_couplers_to_auto_cc_ARID),
        .s_axi_arlen(m00_couplers_to_auto_cc_ARLEN),
        .s_axi_arlock(m00_couplers_to_auto_cc_ARLOCK),
        .s_axi_arprot(m00_couplers_to_auto_cc_ARPROT),
        .s_axi_arqos(m00_couplers_to_auto_cc_ARQOS),
        .s_axi_arready(m00_couplers_to_auto_cc_ARREADY),
        .s_axi_arsize(m00_couplers_to_auto_cc_ARSIZE),
        .s_axi_arvalid(m00_couplers_to_auto_cc_ARVALID),
        .s_axi_awaddr(m00_couplers_to_auto_cc_AWADDR),
        .s_axi_awburst(m00_couplers_to_auto_cc_AWBURST),
        .s_axi_awcache(m00_couplers_to_auto_cc_AWCACHE),
        .s_axi_awid(m00_couplers_to_auto_cc_AWID),
        .s_axi_awlen(m00_couplers_to_auto_cc_AWLEN),
        .s_axi_awlock(m00_couplers_to_auto_cc_AWLOCK),
        .s_axi_awprot(m00_couplers_to_auto_cc_AWPROT),
        .s_axi_awqos(m00_couplers_to_auto_cc_AWQOS),
        .s_axi_awready(m00_couplers_to_auto_cc_AWREADY),
        .s_axi_awsize(m00_couplers_to_auto_cc_AWSIZE),
        .s_axi_awvalid(m00_couplers_to_auto_cc_AWVALID),
        .s_axi_bid(m00_couplers_to_auto_cc_BID),
        .s_axi_bready(m00_couplers_to_auto_cc_BREADY),
        .s_axi_bresp(m00_couplers_to_auto_cc_BRESP),
        .s_axi_bvalid(m00_couplers_to_auto_cc_BVALID),
        .s_axi_rdata(m00_couplers_to_auto_cc_RDATA),
        .s_axi_rid(m00_couplers_to_auto_cc_RID),
        .s_axi_rlast(m00_couplers_to_auto_cc_RLAST),
        .s_axi_rready(m00_couplers_to_auto_cc_RREADY),
        .s_axi_rresp(m00_couplers_to_auto_cc_RRESP),
        .s_axi_rvalid(m00_couplers_to_auto_cc_RVALID),
        .s_axi_wdata(m00_couplers_to_auto_cc_WDATA),
        .s_axi_wid(m00_couplers_to_auto_cc_WID),
        .s_axi_wlast(m00_couplers_to_auto_cc_WLAST),
        .s_axi_wready(m00_couplers_to_auto_cc_WREADY),
        .s_axi_wstrb(m00_couplers_to_auto_cc_WSTRB),
        .s_axi_wvalid(m00_couplers_to_auto_cc_WVALID));
endmodule

module m01_couplers_imp_DDWJU7
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arburst,
    M_AXI_arcache,
    M_AXI_arid,
    M_AXI_arlen,
    M_AXI_arlock,
    M_AXI_arprot,
    M_AXI_arqos,
    M_AXI_arready,
    M_AXI_arsize,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awburst,
    M_AXI_awcache,
    M_AXI_awid,
    M_AXI_awlen,
    M_AXI_awlock,
    M_AXI_awprot,
    M_AXI_awqos,
    M_AXI_awready,
    M_AXI_awsize,
    M_AXI_awvalid,
    M_AXI_bid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rid,
    M_AXI_rlast,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wid,
    M_AXI_wlast,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arcache,
    S_AXI_arid,
    S_AXI_arlen,
    S_AXI_arlock,
    S_AXI_arprot,
    S_AXI_arqos,
    S_AXI_arready,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awid,
    S_AXI_awlen,
    S_AXI_awlock,
    S_AXI_awprot,
    S_AXI_awqos,
    S_AXI_awready,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rid,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wid,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output M_AXI_araddr;
  output M_AXI_arburst;
  output M_AXI_arcache;
  output M_AXI_arid;
  output M_AXI_arlen;
  output M_AXI_arlock;
  output M_AXI_arprot;
  output M_AXI_arqos;
  input M_AXI_arready;
  output M_AXI_arsize;
  output M_AXI_arvalid;
  output M_AXI_awaddr;
  output M_AXI_awburst;
  output M_AXI_awcache;
  output M_AXI_awid;
  output M_AXI_awlen;
  output M_AXI_awlock;
  output M_AXI_awprot;
  output M_AXI_awqos;
  input M_AXI_awready;
  output M_AXI_awsize;
  output M_AXI_awvalid;
  input M_AXI_bid;
  output M_AXI_bready;
  input M_AXI_bresp;
  input M_AXI_bvalid;
  input M_AXI_rdata;
  input M_AXI_rid;
  input M_AXI_rlast;
  output M_AXI_rready;
  input M_AXI_rresp;
  input M_AXI_rvalid;
  output M_AXI_wdata;
  output M_AXI_wid;
  output M_AXI_wlast;
  input M_AXI_wready;
  output M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input S_AXI_araddr;
  input S_AXI_arburst;
  input S_AXI_arcache;
  input S_AXI_arid;
  input S_AXI_arlen;
  input S_AXI_arlock;
  input S_AXI_arprot;
  input S_AXI_arqos;
  output S_AXI_arready;
  input S_AXI_arsize;
  input S_AXI_arvalid;
  input S_AXI_awaddr;
  input S_AXI_awburst;
  input S_AXI_awcache;
  input S_AXI_awid;
  input S_AXI_awlen;
  input S_AXI_awlock;
  input S_AXI_awprot;
  input S_AXI_awqos;
  output S_AXI_awready;
  input S_AXI_awsize;
  input S_AXI_awvalid;
  output S_AXI_bid;
  input S_AXI_bready;
  output S_AXI_bresp;
  output S_AXI_bvalid;
  output S_AXI_rdata;
  output S_AXI_rid;
  output S_AXI_rlast;
  input S_AXI_rready;
  output S_AXI_rresp;
  output S_AXI_rvalid;
  input S_AXI_wdata;
  input S_AXI_wid;
  input S_AXI_wlast;
  output S_AXI_wready;
  input S_AXI_wstrb;
  input S_AXI_wvalid;

  wire m01_couplers_to_m01_couplers_ARADDR;
  wire m01_couplers_to_m01_couplers_ARBURST;
  wire m01_couplers_to_m01_couplers_ARCACHE;
  wire m01_couplers_to_m01_couplers_ARID;
  wire m01_couplers_to_m01_couplers_ARLEN;
  wire m01_couplers_to_m01_couplers_ARLOCK;
  wire m01_couplers_to_m01_couplers_ARPROT;
  wire m01_couplers_to_m01_couplers_ARQOS;
  wire m01_couplers_to_m01_couplers_ARREADY;
  wire m01_couplers_to_m01_couplers_ARSIZE;
  wire m01_couplers_to_m01_couplers_ARVALID;
  wire m01_couplers_to_m01_couplers_AWADDR;
  wire m01_couplers_to_m01_couplers_AWBURST;
  wire m01_couplers_to_m01_couplers_AWCACHE;
  wire m01_couplers_to_m01_couplers_AWID;
  wire m01_couplers_to_m01_couplers_AWLEN;
  wire m01_couplers_to_m01_couplers_AWLOCK;
  wire m01_couplers_to_m01_couplers_AWPROT;
  wire m01_couplers_to_m01_couplers_AWQOS;
  wire m01_couplers_to_m01_couplers_AWREADY;
  wire m01_couplers_to_m01_couplers_AWSIZE;
  wire m01_couplers_to_m01_couplers_AWVALID;
  wire m01_couplers_to_m01_couplers_BID;
  wire m01_couplers_to_m01_couplers_BREADY;
  wire m01_couplers_to_m01_couplers_BRESP;
  wire m01_couplers_to_m01_couplers_BVALID;
  wire m01_couplers_to_m01_couplers_RDATA;
  wire m01_couplers_to_m01_couplers_RID;
  wire m01_couplers_to_m01_couplers_RLAST;
  wire m01_couplers_to_m01_couplers_RREADY;
  wire m01_couplers_to_m01_couplers_RRESP;
  wire m01_couplers_to_m01_couplers_RVALID;
  wire m01_couplers_to_m01_couplers_WDATA;
  wire m01_couplers_to_m01_couplers_WID;
  wire m01_couplers_to_m01_couplers_WLAST;
  wire m01_couplers_to_m01_couplers_WREADY;
  wire m01_couplers_to_m01_couplers_WSTRB;
  wire m01_couplers_to_m01_couplers_WVALID;

  assign M_AXI_araddr = m01_couplers_to_m01_couplers_ARADDR;
  assign M_AXI_arburst = m01_couplers_to_m01_couplers_ARBURST;
  assign M_AXI_arcache = m01_couplers_to_m01_couplers_ARCACHE;
  assign M_AXI_arid = m01_couplers_to_m01_couplers_ARID;
  assign M_AXI_arlen = m01_couplers_to_m01_couplers_ARLEN;
  assign M_AXI_arlock = m01_couplers_to_m01_couplers_ARLOCK;
  assign M_AXI_arprot = m01_couplers_to_m01_couplers_ARPROT;
  assign M_AXI_arqos = m01_couplers_to_m01_couplers_ARQOS;
  assign M_AXI_arsize = m01_couplers_to_m01_couplers_ARSIZE;
  assign M_AXI_arvalid = m01_couplers_to_m01_couplers_ARVALID;
  assign M_AXI_awaddr = m01_couplers_to_m01_couplers_AWADDR;
  assign M_AXI_awburst = m01_couplers_to_m01_couplers_AWBURST;
  assign M_AXI_awcache = m01_couplers_to_m01_couplers_AWCACHE;
  assign M_AXI_awid = m01_couplers_to_m01_couplers_AWID;
  assign M_AXI_awlen = m01_couplers_to_m01_couplers_AWLEN;
  assign M_AXI_awlock = m01_couplers_to_m01_couplers_AWLOCK;
  assign M_AXI_awprot = m01_couplers_to_m01_couplers_AWPROT;
  assign M_AXI_awqos = m01_couplers_to_m01_couplers_AWQOS;
  assign M_AXI_awsize = m01_couplers_to_m01_couplers_AWSIZE;
  assign M_AXI_awvalid = m01_couplers_to_m01_couplers_AWVALID;
  assign M_AXI_bready = m01_couplers_to_m01_couplers_BREADY;
  assign M_AXI_rready = m01_couplers_to_m01_couplers_RREADY;
  assign M_AXI_wdata = m01_couplers_to_m01_couplers_WDATA;
  assign M_AXI_wid = m01_couplers_to_m01_couplers_WID;
  assign M_AXI_wlast = m01_couplers_to_m01_couplers_WLAST;
  assign M_AXI_wstrb = m01_couplers_to_m01_couplers_WSTRB;
  assign M_AXI_wvalid = m01_couplers_to_m01_couplers_WVALID;
  assign S_AXI_arready = m01_couplers_to_m01_couplers_ARREADY;
  assign S_AXI_awready = m01_couplers_to_m01_couplers_AWREADY;
  assign S_AXI_bid = m01_couplers_to_m01_couplers_BID;
  assign S_AXI_bresp = m01_couplers_to_m01_couplers_BRESP;
  assign S_AXI_bvalid = m01_couplers_to_m01_couplers_BVALID;
  assign S_AXI_rdata = m01_couplers_to_m01_couplers_RDATA;
  assign S_AXI_rid = m01_couplers_to_m01_couplers_RID;
  assign S_AXI_rlast = m01_couplers_to_m01_couplers_RLAST;
  assign S_AXI_rresp = m01_couplers_to_m01_couplers_RRESP;
  assign S_AXI_rvalid = m01_couplers_to_m01_couplers_RVALID;
  assign S_AXI_wready = m01_couplers_to_m01_couplers_WREADY;
  assign m01_couplers_to_m01_couplers_ARADDR = S_AXI_araddr;
  assign m01_couplers_to_m01_couplers_ARBURST = S_AXI_arburst;
  assign m01_couplers_to_m01_couplers_ARCACHE = S_AXI_arcache;
  assign m01_couplers_to_m01_couplers_ARID = S_AXI_arid;
  assign m01_couplers_to_m01_couplers_ARLEN = S_AXI_arlen;
  assign m01_couplers_to_m01_couplers_ARLOCK = S_AXI_arlock;
  assign m01_couplers_to_m01_couplers_ARPROT = S_AXI_arprot;
  assign m01_couplers_to_m01_couplers_ARQOS = S_AXI_arqos;
  assign m01_couplers_to_m01_couplers_ARREADY = M_AXI_arready;
  assign m01_couplers_to_m01_couplers_ARSIZE = S_AXI_arsize;
  assign m01_couplers_to_m01_couplers_ARVALID = S_AXI_arvalid;
  assign m01_couplers_to_m01_couplers_AWADDR = S_AXI_awaddr;
  assign m01_couplers_to_m01_couplers_AWBURST = S_AXI_awburst;
  assign m01_couplers_to_m01_couplers_AWCACHE = S_AXI_awcache;
  assign m01_couplers_to_m01_couplers_AWID = S_AXI_awid;
  assign m01_couplers_to_m01_couplers_AWLEN = S_AXI_awlen;
  assign m01_couplers_to_m01_couplers_AWLOCK = S_AXI_awlock;
  assign m01_couplers_to_m01_couplers_AWPROT = S_AXI_awprot;
  assign m01_couplers_to_m01_couplers_AWQOS = S_AXI_awqos;
  assign m01_couplers_to_m01_couplers_AWREADY = M_AXI_awready;
  assign m01_couplers_to_m01_couplers_AWSIZE = S_AXI_awsize;
  assign m01_couplers_to_m01_couplers_AWVALID = S_AXI_awvalid;
  assign m01_couplers_to_m01_couplers_BID = M_AXI_bid;
  assign m01_couplers_to_m01_couplers_BREADY = S_AXI_bready;
  assign m01_couplers_to_m01_couplers_BRESP = M_AXI_bresp;
  assign m01_couplers_to_m01_couplers_BVALID = M_AXI_bvalid;
  assign m01_couplers_to_m01_couplers_RDATA = M_AXI_rdata;
  assign m01_couplers_to_m01_couplers_RID = M_AXI_rid;
  assign m01_couplers_to_m01_couplers_RLAST = M_AXI_rlast;
  assign m01_couplers_to_m01_couplers_RREADY = S_AXI_rready;
  assign m01_couplers_to_m01_couplers_RRESP = M_AXI_rresp;
  assign m01_couplers_to_m01_couplers_RVALID = M_AXI_rvalid;
  assign m01_couplers_to_m01_couplers_WDATA = S_AXI_wdata;
  assign m01_couplers_to_m01_couplers_WID = S_AXI_wid;
  assign m01_couplers_to_m01_couplers_WLAST = S_AXI_wlast;
  assign m01_couplers_to_m01_couplers_WREADY = M_AXI_wready;
  assign m01_couplers_to_m01_couplers_WSTRB = S_AXI_wstrb;
  assign m01_couplers_to_m01_couplers_WVALID = S_AXI_wvalid;
endmodule

module m02_couplers_imp_1OOQK25
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arcache,
    S_AXI_arid,
    S_AXI_arlen,
    S_AXI_arlock,
    S_AXI_arprot,
    S_AXI_arqos,
    S_AXI_arready,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awid,
    S_AXI_awlen,
    S_AXI_awlock,
    S_AXI_awprot,
    S_AXI_awqos,
    S_AXI_awready,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rid,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wid,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [1:0]S_AXI_arburst;
  input [3:0]S_AXI_arcache;
  input [11:0]S_AXI_arid;
  input [3:0]S_AXI_arlen;
  input [1:0]S_AXI_arlock;
  input [2:0]S_AXI_arprot;
  input [3:0]S_AXI_arqos;
  output S_AXI_arready;
  input [2:0]S_AXI_arsize;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [1:0]S_AXI_awburst;
  input [3:0]S_AXI_awcache;
  input [11:0]S_AXI_awid;
  input [3:0]S_AXI_awlen;
  input [1:0]S_AXI_awlock;
  input [2:0]S_AXI_awprot;
  input [3:0]S_AXI_awqos;
  output S_AXI_awready;
  input [2:0]S_AXI_awsize;
  input S_AXI_awvalid;
  output [11:0]S_AXI_bid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  output [11:0]S_AXI_rid;
  output S_AXI_rlast;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  input [11:0]S_AXI_wid;
  input S_AXI_wlast;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_pc_to_m02_couplers_ARADDR;
  wire auto_pc_to_m02_couplers_ARREADY;
  wire auto_pc_to_m02_couplers_ARVALID;
  wire [31:0]auto_pc_to_m02_couplers_AWADDR;
  wire auto_pc_to_m02_couplers_AWREADY;
  wire auto_pc_to_m02_couplers_AWVALID;
  wire auto_pc_to_m02_couplers_BREADY;
  wire [1:0]auto_pc_to_m02_couplers_BRESP;
  wire auto_pc_to_m02_couplers_BVALID;
  wire [31:0]auto_pc_to_m02_couplers_RDATA;
  wire auto_pc_to_m02_couplers_RREADY;
  wire [1:0]auto_pc_to_m02_couplers_RRESP;
  wire auto_pc_to_m02_couplers_RVALID;
  wire [31:0]auto_pc_to_m02_couplers_WDATA;
  wire auto_pc_to_m02_couplers_WREADY;
  wire [3:0]auto_pc_to_m02_couplers_WSTRB;
  wire auto_pc_to_m02_couplers_WVALID;
  wire [31:0]m02_couplers_to_auto_pc_ARADDR;
  wire [1:0]m02_couplers_to_auto_pc_ARBURST;
  wire [3:0]m02_couplers_to_auto_pc_ARCACHE;
  wire [11:0]m02_couplers_to_auto_pc_ARID;
  wire [3:0]m02_couplers_to_auto_pc_ARLEN;
  wire [1:0]m02_couplers_to_auto_pc_ARLOCK;
  wire [2:0]m02_couplers_to_auto_pc_ARPROT;
  wire [3:0]m02_couplers_to_auto_pc_ARQOS;
  wire m02_couplers_to_auto_pc_ARREADY;
  wire [2:0]m02_couplers_to_auto_pc_ARSIZE;
  wire m02_couplers_to_auto_pc_ARVALID;
  wire [31:0]m02_couplers_to_auto_pc_AWADDR;
  wire [1:0]m02_couplers_to_auto_pc_AWBURST;
  wire [3:0]m02_couplers_to_auto_pc_AWCACHE;
  wire [11:0]m02_couplers_to_auto_pc_AWID;
  wire [3:0]m02_couplers_to_auto_pc_AWLEN;
  wire [1:0]m02_couplers_to_auto_pc_AWLOCK;
  wire [2:0]m02_couplers_to_auto_pc_AWPROT;
  wire [3:0]m02_couplers_to_auto_pc_AWQOS;
  wire m02_couplers_to_auto_pc_AWREADY;
  wire [2:0]m02_couplers_to_auto_pc_AWSIZE;
  wire m02_couplers_to_auto_pc_AWVALID;
  wire [11:0]m02_couplers_to_auto_pc_BID;
  wire m02_couplers_to_auto_pc_BREADY;
  wire [1:0]m02_couplers_to_auto_pc_BRESP;
  wire m02_couplers_to_auto_pc_BVALID;
  wire [31:0]m02_couplers_to_auto_pc_RDATA;
  wire [11:0]m02_couplers_to_auto_pc_RID;
  wire m02_couplers_to_auto_pc_RLAST;
  wire m02_couplers_to_auto_pc_RREADY;
  wire [1:0]m02_couplers_to_auto_pc_RRESP;
  wire m02_couplers_to_auto_pc_RVALID;
  wire [31:0]m02_couplers_to_auto_pc_WDATA;
  wire [11:0]m02_couplers_to_auto_pc_WID;
  wire m02_couplers_to_auto_pc_WLAST;
  wire m02_couplers_to_auto_pc_WREADY;
  wire [3:0]m02_couplers_to_auto_pc_WSTRB;
  wire m02_couplers_to_auto_pc_WVALID;

  assign M_AXI_araddr[31:0] = auto_pc_to_m02_couplers_ARADDR;
  assign M_AXI_arvalid = auto_pc_to_m02_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = auto_pc_to_m02_couplers_AWADDR;
  assign M_AXI_awvalid = auto_pc_to_m02_couplers_AWVALID;
  assign M_AXI_bready = auto_pc_to_m02_couplers_BREADY;
  assign M_AXI_rready = auto_pc_to_m02_couplers_RREADY;
  assign M_AXI_wdata[31:0] = auto_pc_to_m02_couplers_WDATA;
  assign M_AXI_wstrb[3:0] = auto_pc_to_m02_couplers_WSTRB;
  assign M_AXI_wvalid = auto_pc_to_m02_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_arready = m02_couplers_to_auto_pc_ARREADY;
  assign S_AXI_awready = m02_couplers_to_auto_pc_AWREADY;
  assign S_AXI_bid[11:0] = m02_couplers_to_auto_pc_BID;
  assign S_AXI_bresp[1:0] = m02_couplers_to_auto_pc_BRESP;
  assign S_AXI_bvalid = m02_couplers_to_auto_pc_BVALID;
  assign S_AXI_rdata[31:0] = m02_couplers_to_auto_pc_RDATA;
  assign S_AXI_rid[11:0] = m02_couplers_to_auto_pc_RID;
  assign S_AXI_rlast = m02_couplers_to_auto_pc_RLAST;
  assign S_AXI_rresp[1:0] = m02_couplers_to_auto_pc_RRESP;
  assign S_AXI_rvalid = m02_couplers_to_auto_pc_RVALID;
  assign S_AXI_wready = m02_couplers_to_auto_pc_WREADY;
  assign auto_pc_to_m02_couplers_ARREADY = M_AXI_arready;
  assign auto_pc_to_m02_couplers_AWREADY = M_AXI_awready;
  assign auto_pc_to_m02_couplers_BRESP = M_AXI_bresp[1:0];
  assign auto_pc_to_m02_couplers_BVALID = M_AXI_bvalid;
  assign auto_pc_to_m02_couplers_RDATA = M_AXI_rdata[31:0];
  assign auto_pc_to_m02_couplers_RRESP = M_AXI_rresp[1:0];
  assign auto_pc_to_m02_couplers_RVALID = M_AXI_rvalid;
  assign auto_pc_to_m02_couplers_WREADY = M_AXI_wready;
  assign m02_couplers_to_auto_pc_ARADDR = S_AXI_araddr[31:0];
  assign m02_couplers_to_auto_pc_ARBURST = S_AXI_arburst[1:0];
  assign m02_couplers_to_auto_pc_ARCACHE = S_AXI_arcache[3:0];
  assign m02_couplers_to_auto_pc_ARID = S_AXI_arid[11:0];
  assign m02_couplers_to_auto_pc_ARLEN = S_AXI_arlen[3:0];
  assign m02_couplers_to_auto_pc_ARLOCK = S_AXI_arlock[1:0];
  assign m02_couplers_to_auto_pc_ARPROT = S_AXI_arprot[2:0];
  assign m02_couplers_to_auto_pc_ARQOS = S_AXI_arqos[3:0];
  assign m02_couplers_to_auto_pc_ARSIZE = S_AXI_arsize[2:0];
  assign m02_couplers_to_auto_pc_ARVALID = S_AXI_arvalid;
  assign m02_couplers_to_auto_pc_AWADDR = S_AXI_awaddr[31:0];
  assign m02_couplers_to_auto_pc_AWBURST = S_AXI_awburst[1:0];
  assign m02_couplers_to_auto_pc_AWCACHE = S_AXI_awcache[3:0];
  assign m02_couplers_to_auto_pc_AWID = S_AXI_awid[11:0];
  assign m02_couplers_to_auto_pc_AWLEN = S_AXI_awlen[3:0];
  assign m02_couplers_to_auto_pc_AWLOCK = S_AXI_awlock[1:0];
  assign m02_couplers_to_auto_pc_AWPROT = S_AXI_awprot[2:0];
  assign m02_couplers_to_auto_pc_AWQOS = S_AXI_awqos[3:0];
  assign m02_couplers_to_auto_pc_AWSIZE = S_AXI_awsize[2:0];
  assign m02_couplers_to_auto_pc_AWVALID = S_AXI_awvalid;
  assign m02_couplers_to_auto_pc_BREADY = S_AXI_bready;
  assign m02_couplers_to_auto_pc_RREADY = S_AXI_rready;
  assign m02_couplers_to_auto_pc_WDATA = S_AXI_wdata[31:0];
  assign m02_couplers_to_auto_pc_WID = S_AXI_wid[11:0];
  assign m02_couplers_to_auto_pc_WLAST = S_AXI_wlast;
  assign m02_couplers_to_auto_pc_WSTRB = S_AXI_wstrb[3:0];
  assign m02_couplers_to_auto_pc_WVALID = S_AXI_wvalid;
  design_1_auto_pc_0 auto_pc
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_araddr(auto_pc_to_m02_couplers_ARADDR),
        .m_axi_arready(auto_pc_to_m02_couplers_ARREADY),
        .m_axi_arvalid(auto_pc_to_m02_couplers_ARVALID),
        .m_axi_awaddr(auto_pc_to_m02_couplers_AWADDR),
        .m_axi_awready(auto_pc_to_m02_couplers_AWREADY),
        .m_axi_awvalid(auto_pc_to_m02_couplers_AWVALID),
        .m_axi_bready(auto_pc_to_m02_couplers_BREADY),
        .m_axi_bresp(auto_pc_to_m02_couplers_BRESP),
        .m_axi_bvalid(auto_pc_to_m02_couplers_BVALID),
        .m_axi_rdata(auto_pc_to_m02_couplers_RDATA),
        .m_axi_rready(auto_pc_to_m02_couplers_RREADY),
        .m_axi_rresp(auto_pc_to_m02_couplers_RRESP),
        .m_axi_rvalid(auto_pc_to_m02_couplers_RVALID),
        .m_axi_wdata(auto_pc_to_m02_couplers_WDATA),
        .m_axi_wready(auto_pc_to_m02_couplers_WREADY),
        .m_axi_wstrb(auto_pc_to_m02_couplers_WSTRB),
        .m_axi_wvalid(auto_pc_to_m02_couplers_WVALID),
        .s_axi_araddr(m02_couplers_to_auto_pc_ARADDR),
        .s_axi_arburst(m02_couplers_to_auto_pc_ARBURST),
        .s_axi_arcache(m02_couplers_to_auto_pc_ARCACHE),
        .s_axi_arid(m02_couplers_to_auto_pc_ARID),
        .s_axi_arlen(m02_couplers_to_auto_pc_ARLEN),
        .s_axi_arlock(m02_couplers_to_auto_pc_ARLOCK),
        .s_axi_arprot(m02_couplers_to_auto_pc_ARPROT),
        .s_axi_arqos(m02_couplers_to_auto_pc_ARQOS),
        .s_axi_arready(m02_couplers_to_auto_pc_ARREADY),
        .s_axi_arsize(m02_couplers_to_auto_pc_ARSIZE),
        .s_axi_arvalid(m02_couplers_to_auto_pc_ARVALID),
        .s_axi_awaddr(m02_couplers_to_auto_pc_AWADDR),
        .s_axi_awburst(m02_couplers_to_auto_pc_AWBURST),
        .s_axi_awcache(m02_couplers_to_auto_pc_AWCACHE),
        .s_axi_awid(m02_couplers_to_auto_pc_AWID),
        .s_axi_awlen(m02_couplers_to_auto_pc_AWLEN),
        .s_axi_awlock(m02_couplers_to_auto_pc_AWLOCK),
        .s_axi_awprot(m02_couplers_to_auto_pc_AWPROT),
        .s_axi_awqos(m02_couplers_to_auto_pc_AWQOS),
        .s_axi_awready(m02_couplers_to_auto_pc_AWREADY),
        .s_axi_awsize(m02_couplers_to_auto_pc_AWSIZE),
        .s_axi_awvalid(m02_couplers_to_auto_pc_AWVALID),
        .s_axi_bid(m02_couplers_to_auto_pc_BID),
        .s_axi_bready(m02_couplers_to_auto_pc_BREADY),
        .s_axi_bresp(m02_couplers_to_auto_pc_BRESP),
        .s_axi_bvalid(m02_couplers_to_auto_pc_BVALID),
        .s_axi_rdata(m02_couplers_to_auto_pc_RDATA),
        .s_axi_rid(m02_couplers_to_auto_pc_RID),
        .s_axi_rlast(m02_couplers_to_auto_pc_RLAST),
        .s_axi_rready(m02_couplers_to_auto_pc_RREADY),
        .s_axi_rresp(m02_couplers_to_auto_pc_RRESP),
        .s_axi_rvalid(m02_couplers_to_auto_pc_RVALID),
        .s_axi_wdata(m02_couplers_to_auto_pc_WDATA),
        .s_axi_wid(m02_couplers_to_auto_pc_WID),
        .s_axi_wlast(m02_couplers_to_auto_pc_WLAST),
        .s_axi_wready(m02_couplers_to_auto_pc_WREADY),
        .s_axi_wstrb(m02_couplers_to_auto_pc_WSTRB),
        .s_axi_wvalid(m02_couplers_to_auto_pc_WVALID));
endmodule

module s00_couplers_imp_AMT4UK
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arburst,
    M_AXI_arcache,
    M_AXI_arid,
    M_AXI_arlen,
    M_AXI_arlock,
    M_AXI_arprot,
    M_AXI_arqos,
    M_AXI_arready,
    M_AXI_arsize,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awburst,
    M_AXI_awcache,
    M_AXI_awid,
    M_AXI_awlen,
    M_AXI_awlock,
    M_AXI_awprot,
    M_AXI_awqos,
    M_AXI_awready,
    M_AXI_awsize,
    M_AXI_awvalid,
    M_AXI_bid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rid,
    M_AXI_rlast,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wid,
    M_AXI_wlast,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arburst,
    S_AXI_arcache,
    S_AXI_arid,
    S_AXI_arlen,
    S_AXI_arlock,
    S_AXI_arprot,
    S_AXI_arqos,
    S_AXI_arready,
    S_AXI_arsize,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awid,
    S_AXI_awlen,
    S_AXI_awlock,
    S_AXI_awprot,
    S_AXI_awqos,
    S_AXI_awready,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rid,
    S_AXI_rlast,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wid,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [1:0]M_AXI_arburst;
  output [3:0]M_AXI_arcache;
  output [11:0]M_AXI_arid;
  output [3:0]M_AXI_arlen;
  output [1:0]M_AXI_arlock;
  output [2:0]M_AXI_arprot;
  output [3:0]M_AXI_arqos;
  input M_AXI_arready;
  output [2:0]M_AXI_arsize;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  output [1:0]M_AXI_awburst;
  output [3:0]M_AXI_awcache;
  output [11:0]M_AXI_awid;
  output [3:0]M_AXI_awlen;
  output [1:0]M_AXI_awlock;
  output [2:0]M_AXI_awprot;
  output [3:0]M_AXI_awqos;
  input M_AXI_awready;
  output [2:0]M_AXI_awsize;
  output M_AXI_awvalid;
  input [11:0]M_AXI_bid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  input [11:0]M_AXI_rid;
  input M_AXI_rlast;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  output [11:0]M_AXI_wid;
  output M_AXI_wlast;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [1:0]S_AXI_arburst;
  input [3:0]S_AXI_arcache;
  input [11:0]S_AXI_arid;
  input [3:0]S_AXI_arlen;
  input [1:0]S_AXI_arlock;
  input [2:0]S_AXI_arprot;
  input [3:0]S_AXI_arqos;
  output S_AXI_arready;
  input [2:0]S_AXI_arsize;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [1:0]S_AXI_awburst;
  input [3:0]S_AXI_awcache;
  input [11:0]S_AXI_awid;
  input [3:0]S_AXI_awlen;
  input [1:0]S_AXI_awlock;
  input [2:0]S_AXI_awprot;
  input [3:0]S_AXI_awqos;
  output S_AXI_awready;
  input [2:0]S_AXI_awsize;
  input S_AXI_awvalid;
  output [11:0]S_AXI_bid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  output [11:0]S_AXI_rid;
  output S_AXI_rlast;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  input [11:0]S_AXI_wid;
  input S_AXI_wlast;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire [31:0]s00_couplers_to_s00_couplers_ARADDR;
  wire [1:0]s00_couplers_to_s00_couplers_ARBURST;
  wire [3:0]s00_couplers_to_s00_couplers_ARCACHE;
  wire [11:0]s00_couplers_to_s00_couplers_ARID;
  wire [3:0]s00_couplers_to_s00_couplers_ARLEN;
  wire [1:0]s00_couplers_to_s00_couplers_ARLOCK;
  wire [2:0]s00_couplers_to_s00_couplers_ARPROT;
  wire [3:0]s00_couplers_to_s00_couplers_ARQOS;
  wire s00_couplers_to_s00_couplers_ARREADY;
  wire [2:0]s00_couplers_to_s00_couplers_ARSIZE;
  wire s00_couplers_to_s00_couplers_ARVALID;
  wire [31:0]s00_couplers_to_s00_couplers_AWADDR;
  wire [1:0]s00_couplers_to_s00_couplers_AWBURST;
  wire [3:0]s00_couplers_to_s00_couplers_AWCACHE;
  wire [11:0]s00_couplers_to_s00_couplers_AWID;
  wire [3:0]s00_couplers_to_s00_couplers_AWLEN;
  wire [1:0]s00_couplers_to_s00_couplers_AWLOCK;
  wire [2:0]s00_couplers_to_s00_couplers_AWPROT;
  wire [3:0]s00_couplers_to_s00_couplers_AWQOS;
  wire s00_couplers_to_s00_couplers_AWREADY;
  wire [2:0]s00_couplers_to_s00_couplers_AWSIZE;
  wire s00_couplers_to_s00_couplers_AWVALID;
  wire [11:0]s00_couplers_to_s00_couplers_BID;
  wire s00_couplers_to_s00_couplers_BREADY;
  wire [1:0]s00_couplers_to_s00_couplers_BRESP;
  wire s00_couplers_to_s00_couplers_BVALID;
  wire [31:0]s00_couplers_to_s00_couplers_RDATA;
  wire [11:0]s00_couplers_to_s00_couplers_RID;
  wire s00_couplers_to_s00_couplers_RLAST;
  wire s00_couplers_to_s00_couplers_RREADY;
  wire [1:0]s00_couplers_to_s00_couplers_RRESP;
  wire s00_couplers_to_s00_couplers_RVALID;
  wire [31:0]s00_couplers_to_s00_couplers_WDATA;
  wire [11:0]s00_couplers_to_s00_couplers_WID;
  wire s00_couplers_to_s00_couplers_WLAST;
  wire s00_couplers_to_s00_couplers_WREADY;
  wire [3:0]s00_couplers_to_s00_couplers_WSTRB;
  wire s00_couplers_to_s00_couplers_WVALID;

  assign M_AXI_araddr[31:0] = s00_couplers_to_s00_couplers_ARADDR;
  assign M_AXI_arburst[1:0] = s00_couplers_to_s00_couplers_ARBURST;
  assign M_AXI_arcache[3:0] = s00_couplers_to_s00_couplers_ARCACHE;
  assign M_AXI_arid[11:0] = s00_couplers_to_s00_couplers_ARID;
  assign M_AXI_arlen[3:0] = s00_couplers_to_s00_couplers_ARLEN;
  assign M_AXI_arlock[1:0] = s00_couplers_to_s00_couplers_ARLOCK;
  assign M_AXI_arprot[2:0] = s00_couplers_to_s00_couplers_ARPROT;
  assign M_AXI_arqos[3:0] = s00_couplers_to_s00_couplers_ARQOS;
  assign M_AXI_arsize[2:0] = s00_couplers_to_s00_couplers_ARSIZE;
  assign M_AXI_arvalid = s00_couplers_to_s00_couplers_ARVALID;
  assign M_AXI_awaddr[31:0] = s00_couplers_to_s00_couplers_AWADDR;
  assign M_AXI_awburst[1:0] = s00_couplers_to_s00_couplers_AWBURST;
  assign M_AXI_awcache[3:0] = s00_couplers_to_s00_couplers_AWCACHE;
  assign M_AXI_awid[11:0] = s00_couplers_to_s00_couplers_AWID;
  assign M_AXI_awlen[3:0] = s00_couplers_to_s00_couplers_AWLEN;
  assign M_AXI_awlock[1:0] = s00_couplers_to_s00_couplers_AWLOCK;
  assign M_AXI_awprot[2:0] = s00_couplers_to_s00_couplers_AWPROT;
  assign M_AXI_awqos[3:0] = s00_couplers_to_s00_couplers_AWQOS;
  assign M_AXI_awsize[2:0] = s00_couplers_to_s00_couplers_AWSIZE;
  assign M_AXI_awvalid = s00_couplers_to_s00_couplers_AWVALID;
  assign M_AXI_bready = s00_couplers_to_s00_couplers_BREADY;
  assign M_AXI_rready = s00_couplers_to_s00_couplers_RREADY;
  assign M_AXI_wdata[31:0] = s00_couplers_to_s00_couplers_WDATA;
  assign M_AXI_wid[11:0] = s00_couplers_to_s00_couplers_WID;
  assign M_AXI_wlast = s00_couplers_to_s00_couplers_WLAST;
  assign M_AXI_wstrb[3:0] = s00_couplers_to_s00_couplers_WSTRB;
  assign M_AXI_wvalid = s00_couplers_to_s00_couplers_WVALID;
  assign S_AXI_arready = s00_couplers_to_s00_couplers_ARREADY;
  assign S_AXI_awready = s00_couplers_to_s00_couplers_AWREADY;
  assign S_AXI_bid[11:0] = s00_couplers_to_s00_couplers_BID;
  assign S_AXI_bresp[1:0] = s00_couplers_to_s00_couplers_BRESP;
  assign S_AXI_bvalid = s00_couplers_to_s00_couplers_BVALID;
  assign S_AXI_rdata[31:0] = s00_couplers_to_s00_couplers_RDATA;
  assign S_AXI_rid[11:0] = s00_couplers_to_s00_couplers_RID;
  assign S_AXI_rlast = s00_couplers_to_s00_couplers_RLAST;
  assign S_AXI_rresp[1:0] = s00_couplers_to_s00_couplers_RRESP;
  assign S_AXI_rvalid = s00_couplers_to_s00_couplers_RVALID;
  assign S_AXI_wready = s00_couplers_to_s00_couplers_WREADY;
  assign s00_couplers_to_s00_couplers_ARADDR = S_AXI_araddr[31:0];
  assign s00_couplers_to_s00_couplers_ARBURST = S_AXI_arburst[1:0];
  assign s00_couplers_to_s00_couplers_ARCACHE = S_AXI_arcache[3:0];
  assign s00_couplers_to_s00_couplers_ARID = S_AXI_arid[11:0];
  assign s00_couplers_to_s00_couplers_ARLEN = S_AXI_arlen[3:0];
  assign s00_couplers_to_s00_couplers_ARLOCK = S_AXI_arlock[1:0];
  assign s00_couplers_to_s00_couplers_ARPROT = S_AXI_arprot[2:0];
  assign s00_couplers_to_s00_couplers_ARQOS = S_AXI_arqos[3:0];
  assign s00_couplers_to_s00_couplers_ARREADY = M_AXI_arready;
  assign s00_couplers_to_s00_couplers_ARSIZE = S_AXI_arsize[2:0];
  assign s00_couplers_to_s00_couplers_ARVALID = S_AXI_arvalid;
  assign s00_couplers_to_s00_couplers_AWADDR = S_AXI_awaddr[31:0];
  assign s00_couplers_to_s00_couplers_AWBURST = S_AXI_awburst[1:0];
  assign s00_couplers_to_s00_couplers_AWCACHE = S_AXI_awcache[3:0];
  assign s00_couplers_to_s00_couplers_AWID = S_AXI_awid[11:0];
  assign s00_couplers_to_s00_couplers_AWLEN = S_AXI_awlen[3:0];
  assign s00_couplers_to_s00_couplers_AWLOCK = S_AXI_awlock[1:0];
  assign s00_couplers_to_s00_couplers_AWPROT = S_AXI_awprot[2:0];
  assign s00_couplers_to_s00_couplers_AWQOS = S_AXI_awqos[3:0];
  assign s00_couplers_to_s00_couplers_AWREADY = M_AXI_awready;
  assign s00_couplers_to_s00_couplers_AWSIZE = S_AXI_awsize[2:0];
  assign s00_couplers_to_s00_couplers_AWVALID = S_AXI_awvalid;
  assign s00_couplers_to_s00_couplers_BID = M_AXI_bid[11:0];
  assign s00_couplers_to_s00_couplers_BREADY = S_AXI_bready;
  assign s00_couplers_to_s00_couplers_BRESP = M_AXI_bresp[1:0];
  assign s00_couplers_to_s00_couplers_BVALID = M_AXI_bvalid;
  assign s00_couplers_to_s00_couplers_RDATA = M_AXI_rdata[31:0];
  assign s00_couplers_to_s00_couplers_RID = M_AXI_rid[11:0];
  assign s00_couplers_to_s00_couplers_RLAST = M_AXI_rlast;
  assign s00_couplers_to_s00_couplers_RREADY = S_AXI_rready;
  assign s00_couplers_to_s00_couplers_RRESP = M_AXI_rresp[1:0];
  assign s00_couplers_to_s00_couplers_RVALID = M_AXI_rvalid;
  assign s00_couplers_to_s00_couplers_WDATA = S_AXI_wdata[31:0];
  assign s00_couplers_to_s00_couplers_WID = S_AXI_wid[11:0];
  assign s00_couplers_to_s00_couplers_WLAST = S_AXI_wlast;
  assign s00_couplers_to_s00_couplers_WREADY = M_AXI_wready;
  assign s00_couplers_to_s00_couplers_WSTRB = S_AXI_wstrb[3:0];
  assign s00_couplers_to_s00_couplers_WVALID = S_AXI_wvalid;
endmodule
