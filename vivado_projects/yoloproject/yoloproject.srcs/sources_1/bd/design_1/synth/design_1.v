//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
//Date        : Wed Sep 30 00:46:10 2026
//Host        : LAPTOP-7HADCOJD running 64-bit major release  (build 9200)
//Command     : generate_target design_1.bd
//Design      : design_1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=design_1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=16,numReposBlks=14,numNonXlnxBlks=0,numHierBlks=2,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=1,numPkgbdBlks=0,bdsource=USER,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "design_1.hwdef" *) 
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
    cam_cfg_done,
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
  output cam_cfg_done;
  input [7:0]cmos_data;
  input cmos_href;
  input cmos_pclk;
  output cmos_scl;
  inout cmos_sda;
  input cmos_vsync;
  output cmos_xclk;

  wire Net;
  wire [31:0]axi_smc_M00_AXI_ARADDR;
  wire [1:0]axi_smc_M00_AXI_ARBURST;
  wire [3:0]axi_smc_M00_AXI_ARCACHE;
  wire [3:0]axi_smc_M00_AXI_ARLEN;
  wire [1:0]axi_smc_M00_AXI_ARLOCK;
  wire [2:0]axi_smc_M00_AXI_ARPROT;
  wire [3:0]axi_smc_M00_AXI_ARQOS;
  wire axi_smc_M00_AXI_ARREADY;
  wire [2:0]axi_smc_M00_AXI_ARSIZE;
  wire axi_smc_M00_AXI_ARVALID;
  wire [31:0]axi_smc_M00_AXI_AWADDR;
  wire [1:0]axi_smc_M00_AXI_AWBURST;
  wire [3:0]axi_smc_M00_AXI_AWCACHE;
  wire [3:0]axi_smc_M00_AXI_AWLEN;
  wire [1:0]axi_smc_M00_AXI_AWLOCK;
  wire [2:0]axi_smc_M00_AXI_AWPROT;
  wire [3:0]axi_smc_M00_AXI_AWQOS;
  wire axi_smc_M00_AXI_AWREADY;
  wire [2:0]axi_smc_M00_AXI_AWSIZE;
  wire axi_smc_M00_AXI_AWVALID;
  wire axi_smc_M00_AXI_BREADY;
  wire [1:0]axi_smc_M00_AXI_BRESP;
  wire axi_smc_M00_AXI_BVALID;
  wire [31:0]axi_smc_M00_AXI_RDATA;
  wire axi_smc_M00_AXI_RLAST;
  wire axi_smc_M00_AXI_RREADY;
  wire [1:0]axi_smc_M00_AXI_RRESP;
  wire axi_smc_M00_AXI_RVALID;
  wire [31:0]axi_smc_M00_AXI_WDATA;
  wire axi_smc_M00_AXI_WLAST;
  wire axi_smc_M00_AXI_WREADY;
  wire [3:0]axi_smc_M00_AXI_WSTRB;
  wire axi_smc_M00_AXI_WVALID;
  wire [8:0]axi_smc_M01_AXI_ARADDR;
  wire axi_smc_M01_AXI_ARREADY;
  wire axi_smc_M01_AXI_ARVALID;
  wire [8:0]axi_smc_M01_AXI_AWADDR;
  wire axi_smc_M01_AXI_AWREADY;
  wire axi_smc_M01_AXI_AWVALID;
  wire axi_smc_M01_AXI_BREADY;
  wire [1:0]axi_smc_M01_AXI_BRESP;
  wire axi_smc_M01_AXI_BVALID;
  wire [31:0]axi_smc_M01_AXI_RDATA;
  wire axi_smc_M01_AXI_RREADY;
  wire [1:0]axi_smc_M01_AXI_RRESP;
  wire axi_smc_M01_AXI_RVALID;
  wire [31:0]axi_smc_M01_AXI_WDATA;
  wire axi_smc_M01_AXI_WREADY;
  wire axi_smc_M01_AXI_WVALID;
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
  wire [31:0]axi_vdma_0_M_AXI_S2MM_AWADDR;
  wire [1:0]axi_vdma_0_M_AXI_S2MM_AWBURST;
  wire [3:0]axi_vdma_0_M_AXI_S2MM_AWCACHE;
  wire [7:0]axi_vdma_0_M_AXI_S2MM_AWLEN;
  wire [2:0]axi_vdma_0_M_AXI_S2MM_AWPROT;
  wire axi_vdma_0_M_AXI_S2MM_AWREADY;
  wire [2:0]axi_vdma_0_M_AXI_S2MM_AWSIZE;
  wire axi_vdma_0_M_AXI_S2MM_AWVALID;
  wire axi_vdma_0_M_AXI_S2MM_BREADY;
  wire [1:0]axi_vdma_0_M_AXI_S2MM_BRESP;
  wire axi_vdma_0_M_AXI_S2MM_BVALID;
  wire [63:0]axi_vdma_0_M_AXI_S2MM_WDATA;
  wire axi_vdma_0_M_AXI_S2MM_WLAST;
  wire axi_vdma_0_M_AXI_S2MM_WREADY;
  wire [7:0]axi_vdma_0_M_AXI_S2MM_WSTRB;
  wire axi_vdma_0_M_AXI_S2MM_WVALID;
  wire clk_wiz_0_clk_out1;
  wire clk_wiz_0_clk_out2;
  wire clk_wiz_0_clk_out3;
  wire [7:0]cmos_data_1;
  wire cmos_href_0_1;
  wire cmos_pclk_0_1;
  wire cmos_vsync_0_1;
  wire [0:0]const_rst0_dout;
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
  wire ov5640_0_cam_cfg_done;
  wire ov5640_0_cmos_scl;
  wire ov5640_0_cmos_xclk;
  wire [15:0]ov5640_0_m_axis_video_TDATA;
  wire ov5640_0_m_axis_video_TLAST;
  wire ov5640_0_m_axis_video_TREADY;
  wire ov5640_0_m_axis_video_TUSER;
  wire ov5640_0_m_axis_video_TVALID;
  wire [0:0]proc_sys_reset_0_peripheral_aresetn;
  wire [0:0]proc_sys_reset_1_peripheral_aresetn;
  wire [0:0]proc_sys_reset_2_peripheral_aresetn;
  wire [14:0]processing_system7_0_DDR_ADDR;
  wire [2:0]processing_system7_0_DDR_BA;
  wire processing_system7_0_DDR_CAS_N;
  wire processing_system7_0_DDR_CKE;
  wire processing_system7_0_DDR_CK_N;
  wire processing_system7_0_DDR_CK_P;
  wire processing_system7_0_DDR_CS_N;
  wire [3:0]processing_system7_0_DDR_DM;
  wire [31:0]processing_system7_0_DDR_DQ;
  wire [3:0]processing_system7_0_DDR_DQS_N;
  wire [3:0]processing_system7_0_DDR_DQS_P;
  wire processing_system7_0_DDR_ODT;
  wire processing_system7_0_DDR_RAS_N;
  wire processing_system7_0_DDR_RESET_N;
  wire processing_system7_0_DDR_WE_N;
  wire processing_system7_0_FCLK_CLK0;
  wire processing_system7_0_FCLK_CLK1;
  wire processing_system7_0_FCLK_RESET0_N;
  wire processing_system7_0_FIXED_IO_DDR_VRN;
  wire processing_system7_0_FIXED_IO_DDR_VRP;
  wire [53:0]processing_system7_0_FIXED_IO_MIO;
  wire processing_system7_0_FIXED_IO_PS_CLK;
  wire processing_system7_0_FIXED_IO_PS_PORB;
  wire processing_system7_0_FIXED_IO_PS_SRSTB;
  wire [31:0]processing_system7_0_M_AXI_GP0_ARADDR;
  wire [1:0]processing_system7_0_M_AXI_GP0_ARBURST;
  wire [3:0]processing_system7_0_M_AXI_GP0_ARCACHE;
  wire [11:0]processing_system7_0_M_AXI_GP0_ARID;
  wire [3:0]processing_system7_0_M_AXI_GP0_ARLEN;
  wire [1:0]processing_system7_0_M_AXI_GP0_ARLOCK;
  wire [2:0]processing_system7_0_M_AXI_GP0_ARPROT;
  wire [3:0]processing_system7_0_M_AXI_GP0_ARQOS;
  wire processing_system7_0_M_AXI_GP0_ARREADY;
  wire [2:0]processing_system7_0_M_AXI_GP0_ARSIZE;
  wire processing_system7_0_M_AXI_GP0_ARVALID;
  wire [31:0]processing_system7_0_M_AXI_GP0_AWADDR;
  wire [1:0]processing_system7_0_M_AXI_GP0_AWBURST;
  wire [3:0]processing_system7_0_M_AXI_GP0_AWCACHE;
  wire [11:0]processing_system7_0_M_AXI_GP0_AWID;
  wire [3:0]processing_system7_0_M_AXI_GP0_AWLEN;
  wire [1:0]processing_system7_0_M_AXI_GP0_AWLOCK;
  wire [2:0]processing_system7_0_M_AXI_GP0_AWPROT;
  wire [3:0]processing_system7_0_M_AXI_GP0_AWQOS;
  wire processing_system7_0_M_AXI_GP0_AWREADY;
  wire [2:0]processing_system7_0_M_AXI_GP0_AWSIZE;
  wire processing_system7_0_M_AXI_GP0_AWVALID;
  wire [11:0]processing_system7_0_M_AXI_GP0_BID;
  wire processing_system7_0_M_AXI_GP0_BREADY;
  wire [1:0]processing_system7_0_M_AXI_GP0_BRESP;
  wire processing_system7_0_M_AXI_GP0_BVALID;
  wire [31:0]processing_system7_0_M_AXI_GP0_RDATA;
  wire [11:0]processing_system7_0_M_AXI_GP0_RID;
  wire processing_system7_0_M_AXI_GP0_RLAST;
  wire processing_system7_0_M_AXI_GP0_RREADY;
  wire [1:0]processing_system7_0_M_AXI_GP0_RRESP;
  wire processing_system7_0_M_AXI_GP0_RVALID;
  wire [31:0]processing_system7_0_M_AXI_GP0_WDATA;
  wire [11:0]processing_system7_0_M_AXI_GP0_WID;
  wire processing_system7_0_M_AXI_GP0_WLAST;
  wire processing_system7_0_M_AXI_GP0_WREADY;
  wire [3:0]processing_system7_0_M_AXI_GP0_WSTRB;
  wire processing_system7_0_M_AXI_GP0_WVALID;
  wire [0:0]rst_300M_peripheral_aresetn;
  wire [31:0]vdma_icc_M00_AXI_AWADDR;
  wire [1:0]vdma_icc_M00_AXI_AWBURST;
  wire [3:0]vdma_icc_M00_AXI_AWCACHE;
  wire [3:0]vdma_icc_M00_AXI_AWLEN;
  wire [1:0]vdma_icc_M00_AXI_AWLOCK;
  wire [2:0]vdma_icc_M00_AXI_AWPROT;
  wire [3:0]vdma_icc_M00_AXI_AWQOS;
  wire vdma_icc_M00_AXI_AWREADY;
  wire [2:0]vdma_icc_M00_AXI_AWSIZE;
  wire vdma_icc_M00_AXI_AWVALID;
  wire vdma_icc_M00_AXI_BREADY;
  wire [1:0]vdma_icc_M00_AXI_BRESP;
  wire vdma_icc_M00_AXI_BVALID;
  wire [63:0]vdma_icc_M00_AXI_WDATA;
  wire vdma_icc_M00_AXI_WLAST;
  wire vdma_icc_M00_AXI_WREADY;
  wire [7:0]vdma_icc_M00_AXI_WSTRB;
  wire vdma_icc_M00_AXI_WVALID;

  assign cam_cfg_done = ov5640_0_cam_cfg_done;
  assign cmos_data_1 = cmos_data[7:0];
  assign cmos_href_0_1 = cmos_href;
  assign cmos_pclk_0_1 = cmos_pclk;
  assign cmos_scl = ov5640_0_cmos_scl;
  assign cmos_vsync_0_1 = cmos_vsync;
  assign cmos_xclk = ov5640_0_cmos_xclk;
  design_1_axi_smc_1 axi_smc
       (.M00_AXI_araddr(axi_smc_M00_AXI_ARADDR),
        .M00_AXI_arburst(axi_smc_M00_AXI_ARBURST),
        .M00_AXI_arcache(axi_smc_M00_AXI_ARCACHE),
        .M00_AXI_arlen(axi_smc_M00_AXI_ARLEN),
        .M00_AXI_arlock(axi_smc_M00_AXI_ARLOCK),
        .M00_AXI_arprot(axi_smc_M00_AXI_ARPROT),
        .M00_AXI_arqos(axi_smc_M00_AXI_ARQOS),
        .M00_AXI_arready(axi_smc_M00_AXI_ARREADY),
        .M00_AXI_arsize(axi_smc_M00_AXI_ARSIZE),
        .M00_AXI_arvalid(axi_smc_M00_AXI_ARVALID),
        .M00_AXI_awaddr(axi_smc_M00_AXI_AWADDR),
        .M00_AXI_awburst(axi_smc_M00_AXI_AWBURST),
        .M00_AXI_awcache(axi_smc_M00_AXI_AWCACHE),
        .M00_AXI_awlen(axi_smc_M00_AXI_AWLEN),
        .M00_AXI_awlock(axi_smc_M00_AXI_AWLOCK),
        .M00_AXI_awprot(axi_smc_M00_AXI_AWPROT),
        .M00_AXI_awqos(axi_smc_M00_AXI_AWQOS),
        .M00_AXI_awready(axi_smc_M00_AXI_AWREADY),
        .M00_AXI_awsize(axi_smc_M00_AXI_AWSIZE),
        .M00_AXI_awvalid(axi_smc_M00_AXI_AWVALID),
        .M00_AXI_bready(axi_smc_M00_AXI_BREADY),
        .M00_AXI_bresp(axi_smc_M00_AXI_BRESP),
        .M00_AXI_bvalid(axi_smc_M00_AXI_BVALID),
        .M00_AXI_rdata(axi_smc_M00_AXI_RDATA),
        .M00_AXI_rlast(axi_smc_M00_AXI_RLAST),
        .M00_AXI_rready(axi_smc_M00_AXI_RREADY),
        .M00_AXI_rresp(axi_smc_M00_AXI_RRESP),
        .M00_AXI_rvalid(axi_smc_M00_AXI_RVALID),
        .M00_AXI_wdata(axi_smc_M00_AXI_WDATA),
        .M00_AXI_wlast(axi_smc_M00_AXI_WLAST),
        .M00_AXI_wready(axi_smc_M00_AXI_WREADY),
        .M00_AXI_wstrb(axi_smc_M00_AXI_WSTRB),
        .M00_AXI_wvalid(axi_smc_M00_AXI_WVALID),
        .M01_AXI_araddr(axi_smc_M01_AXI_ARADDR),
        .M01_AXI_arready(axi_smc_M01_AXI_ARREADY),
        .M01_AXI_arvalid(axi_smc_M01_AXI_ARVALID),
        .M01_AXI_awaddr(axi_smc_M01_AXI_AWADDR),
        .M01_AXI_awready(axi_smc_M01_AXI_AWREADY),
        .M01_AXI_awvalid(axi_smc_M01_AXI_AWVALID),
        .M01_AXI_bready(axi_smc_M01_AXI_BREADY),
        .M01_AXI_bresp(axi_smc_M01_AXI_BRESP),
        .M01_AXI_bvalid(axi_smc_M01_AXI_BVALID),
        .M01_AXI_rdata(axi_smc_M01_AXI_RDATA),
        .M01_AXI_rready(axi_smc_M01_AXI_RREADY),
        .M01_AXI_rresp(axi_smc_M01_AXI_RRESP),
        .M01_AXI_rvalid(axi_smc_M01_AXI_RVALID),
        .M01_AXI_wdata(axi_smc_M01_AXI_WDATA),
        .M01_AXI_wready(axi_smc_M01_AXI_WREADY),
        .M01_AXI_wvalid(axi_smc_M01_AXI_WVALID),
        .S00_AXI_araddr(processing_system7_0_M_AXI_GP0_ARADDR),
        .S00_AXI_arburst(processing_system7_0_M_AXI_GP0_ARBURST),
        .S00_AXI_arcache(processing_system7_0_M_AXI_GP0_ARCACHE),
        .S00_AXI_arid(processing_system7_0_M_AXI_GP0_ARID),
        .S00_AXI_arlen(processing_system7_0_M_AXI_GP0_ARLEN),
        .S00_AXI_arlock(processing_system7_0_M_AXI_GP0_ARLOCK),
        .S00_AXI_arprot(processing_system7_0_M_AXI_GP0_ARPROT),
        .S00_AXI_arqos(processing_system7_0_M_AXI_GP0_ARQOS),
        .S00_AXI_arready(processing_system7_0_M_AXI_GP0_ARREADY),
        .S00_AXI_arsize(processing_system7_0_M_AXI_GP0_ARSIZE),
        .S00_AXI_arvalid(processing_system7_0_M_AXI_GP0_ARVALID),
        .S00_AXI_awaddr(processing_system7_0_M_AXI_GP0_AWADDR),
        .S00_AXI_awburst(processing_system7_0_M_AXI_GP0_AWBURST),
        .S00_AXI_awcache(processing_system7_0_M_AXI_GP0_AWCACHE),
        .S00_AXI_awid(processing_system7_0_M_AXI_GP0_AWID),
        .S00_AXI_awlen(processing_system7_0_M_AXI_GP0_AWLEN),
        .S00_AXI_awlock(processing_system7_0_M_AXI_GP0_AWLOCK),
        .S00_AXI_awprot(processing_system7_0_M_AXI_GP0_AWPROT),
        .S00_AXI_awqos(processing_system7_0_M_AXI_GP0_AWQOS),
        .S00_AXI_awready(processing_system7_0_M_AXI_GP0_AWREADY),
        .S00_AXI_awsize(processing_system7_0_M_AXI_GP0_AWSIZE),
        .S00_AXI_awvalid(processing_system7_0_M_AXI_GP0_AWVALID),
        .S00_AXI_bid(processing_system7_0_M_AXI_GP0_BID),
        .S00_AXI_bready(processing_system7_0_M_AXI_GP0_BREADY),
        .S00_AXI_bresp(processing_system7_0_M_AXI_GP0_BRESP),
        .S00_AXI_bvalid(processing_system7_0_M_AXI_GP0_BVALID),
        .S00_AXI_rdata(processing_system7_0_M_AXI_GP0_RDATA),
        .S00_AXI_rid(processing_system7_0_M_AXI_GP0_RID),
        .S00_AXI_rlast(processing_system7_0_M_AXI_GP0_RLAST),
        .S00_AXI_rready(processing_system7_0_M_AXI_GP0_RREADY),
        .S00_AXI_rresp(processing_system7_0_M_AXI_GP0_RRESP),
        .S00_AXI_rvalid(processing_system7_0_M_AXI_GP0_RVALID),
        .S00_AXI_wdata(processing_system7_0_M_AXI_GP0_WDATA),
        .S00_AXI_wid(processing_system7_0_M_AXI_GP0_WID),
        .S00_AXI_wlast(processing_system7_0_M_AXI_GP0_WLAST),
        .S00_AXI_wready(processing_system7_0_M_AXI_GP0_WREADY),
        .S00_AXI_wstrb(processing_system7_0_M_AXI_GP0_WSTRB),
        .S00_AXI_wvalid(processing_system7_0_M_AXI_GP0_WVALID),
        .aclk(processing_system7_0_FCLK_CLK0),
        .aresetn(1'b1));
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
        .aclk1(clk_wiz_0_clk_out2),
        .aresetn(proc_sys_reset_0_peripheral_aresetn));
  design_1_axi_vdma_0_0 axi_vdma_0
       (.axi_resetn(1'b1),
        .m_axi_s2mm_aclk(clk_wiz_0_clk_out1),
        .m_axi_s2mm_awaddr(axi_vdma_0_M_AXI_S2MM_AWADDR),
        .m_axi_s2mm_awburst(axi_vdma_0_M_AXI_S2MM_AWBURST),
        .m_axi_s2mm_awcache(axi_vdma_0_M_AXI_S2MM_AWCACHE),
        .m_axi_s2mm_awlen(axi_vdma_0_M_AXI_S2MM_AWLEN),
        .m_axi_s2mm_awprot(axi_vdma_0_M_AXI_S2MM_AWPROT),
        .m_axi_s2mm_awready(axi_vdma_0_M_AXI_S2MM_AWREADY),
        .m_axi_s2mm_awsize(axi_vdma_0_M_AXI_S2MM_AWSIZE),
        .m_axi_s2mm_awvalid(axi_vdma_0_M_AXI_S2MM_AWVALID),
        .m_axi_s2mm_bready(axi_vdma_0_M_AXI_S2MM_BREADY),
        .m_axi_s2mm_bresp(axi_vdma_0_M_AXI_S2MM_BRESP),
        .m_axi_s2mm_bvalid(axi_vdma_0_M_AXI_S2MM_BVALID),
        .m_axi_s2mm_wdata(axi_vdma_0_M_AXI_S2MM_WDATA),
        .m_axi_s2mm_wlast(axi_vdma_0_M_AXI_S2MM_WLAST),
        .m_axi_s2mm_wready(axi_vdma_0_M_AXI_S2MM_WREADY),
        .m_axi_s2mm_wstrb(axi_vdma_0_M_AXI_S2MM_WSTRB),
        .m_axi_s2mm_wvalid(axi_vdma_0_M_AXI_S2MM_WVALID),
        .s_axi_lite_aclk(processing_system7_0_FCLK_CLK0),
        .s_axi_lite_araddr(axi_smc_M01_AXI_ARADDR),
        .s_axi_lite_arready(axi_smc_M01_AXI_ARREADY),
        .s_axi_lite_arvalid(axi_smc_M01_AXI_ARVALID),
        .s_axi_lite_awaddr(axi_smc_M01_AXI_AWADDR),
        .s_axi_lite_awready(axi_smc_M01_AXI_AWREADY),
        .s_axi_lite_awvalid(axi_smc_M01_AXI_AWVALID),
        .s_axi_lite_bready(axi_smc_M01_AXI_BREADY),
        .s_axi_lite_bresp(axi_smc_M01_AXI_BRESP),
        .s_axi_lite_bvalid(axi_smc_M01_AXI_BVALID),
        .s_axi_lite_rdata(axi_smc_M01_AXI_RDATA),
        .s_axi_lite_rready(axi_smc_M01_AXI_RREADY),
        .s_axi_lite_rresp(axi_smc_M01_AXI_RRESP),
        .s_axi_lite_rvalid(axi_smc_M01_AXI_RVALID),
        .s_axi_lite_wdata(axi_smc_M01_AXI_WDATA),
        .s_axi_lite_wready(axi_smc_M01_AXI_WREADY),
        .s_axi_lite_wvalid(axi_smc_M01_AXI_WVALID),
        .s_axis_s2mm_aclk(clk_wiz_0_clk_out1),
        .s_axis_s2mm_tdata(ov5640_0_m_axis_video_TDATA),
        .s_axis_s2mm_tkeep({1'b1,1'b1}),
        .s_axis_s2mm_tlast(ov5640_0_m_axis_video_TLAST),
        .s_axis_s2mm_tready(ov5640_0_m_axis_video_TREADY),
        .s_axis_s2mm_tuser(ov5640_0_m_axis_video_TUSER),
        .s_axis_s2mm_tvalid(ov5640_0_m_axis_video_TVALID));
  design_1_clk_wiz_0_0 clk_wiz_0
       (.clk_in1(processing_system7_0_FCLK_CLK0),
        .clk_out1(clk_wiz_0_clk_out1),
        .clk_out2(clk_wiz_0_clk_out2),
        .clk_out3(clk_wiz_0_clk_out3),
        .reset(const_rst0_dout));
  design_1_const_rst0_0 const_rst0
       (.dout(const_rst0_dout));
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
        .dpu_2x_resetn(rst_300M_peripheral_aresetn),
        .dpu_interrupt(dpu_eu_0_dpu_interrupt),
        .m_axi_dpu_aclk(clk_wiz_0_clk_out2),
        .m_axi_dpu_aresetn(proc_sys_reset_0_peripheral_aresetn),
        .s_axi_aclk(processing_system7_0_FCLK_CLK0),
        .s_axi_araddr(axi_smc_M00_AXI_ARADDR),
        .s_axi_arburst(axi_smc_M00_AXI_ARBURST),
        .s_axi_arcache(axi_smc_M00_AXI_ARCACHE),
        .s_axi_aresetn(proc_sys_reset_1_peripheral_aresetn),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen(axi_smc_M00_AXI_ARLEN),
        .s_axi_arlock(axi_smc_M00_AXI_ARLOCK),
        .s_axi_arprot(axi_smc_M00_AXI_ARPROT),
        .s_axi_arqos(axi_smc_M00_AXI_ARQOS),
        .s_axi_arready(axi_smc_M00_AXI_ARREADY),
        .s_axi_arregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arsize(axi_smc_M00_AXI_ARSIZE),
        .s_axi_arvalid(axi_smc_M00_AXI_ARVALID),
        .s_axi_awaddr(axi_smc_M00_AXI_AWADDR),
        .s_axi_awburst(axi_smc_M00_AXI_AWBURST),
        .s_axi_awcache(axi_smc_M00_AXI_AWCACHE),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen(axi_smc_M00_AXI_AWLEN),
        .s_axi_awlock(axi_smc_M00_AXI_AWLOCK),
        .s_axi_awprot(axi_smc_M00_AXI_AWPROT),
        .s_axi_awqos(axi_smc_M00_AXI_AWQOS),
        .s_axi_awready(axi_smc_M00_AXI_AWREADY),
        .s_axi_awregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awsize(axi_smc_M00_AXI_AWSIZE),
        .s_axi_awvalid(axi_smc_M00_AXI_AWVALID),
        .s_axi_bready(axi_smc_M00_AXI_BREADY),
        .s_axi_bresp(axi_smc_M00_AXI_BRESP),
        .s_axi_bvalid(axi_smc_M00_AXI_BVALID),
        .s_axi_rdata(axi_smc_M00_AXI_RDATA),
        .s_axi_rlast(axi_smc_M00_AXI_RLAST),
        .s_axi_rready(axi_smc_M00_AXI_RREADY),
        .s_axi_rresp(axi_smc_M00_AXI_RRESP),
        .s_axi_rvalid(axi_smc_M00_AXI_RVALID),
        .s_axi_wdata(axi_smc_M00_AXI_WDATA),
        .s_axi_wid({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(axi_smc_M00_AXI_WLAST),
        .s_axi_wready(axi_smc_M00_AXI_WREADY),
        .s_axi_wstrb(axi_smc_M00_AXI_WSTRB),
        .s_axi_wvalid(axi_smc_M00_AXI_WVALID));
  design_1_ov5640_0_0 ov5640_0
       (.ACLK(clk_wiz_0_clk_out1),
        .ARESETN(proc_sys_reset_1_peripheral_aresetn),
        .cam_cfg_done(ov5640_0_cam_cfg_done),
        .cmos_data(cmos_data_1),
        .cmos_href(cmos_href_0_1),
        .cmos_pclk(cmos_pclk_0_1),
        .cmos_scl(ov5640_0_cmos_scl),
        .cmos_sda(cmos_sda),
        .cmos_vsync(cmos_vsync_0_1),
        .cmos_xclk(ov5640_0_cmos_xclk),
        .m_axis_video_tdata(ov5640_0_m_axis_video_TDATA),
        .m_axis_video_tlast(ov5640_0_m_axis_video_TLAST),
        .m_axis_video_tready(ov5640_0_m_axis_video_TREADY),
        .m_axis_video_tuser(ov5640_0_m_axis_video_TUSER),
        .m_axis_video_tvalid(ov5640_0_m_axis_video_TVALID));
  design_1_proc_sys_reset_0_0 proc_sys_reset_0
       (.aux_reset_in(1'b1),
        .dcm_locked(1'b1),
        .ext_reset_in(processing_system7_0_FCLK_RESET0_N),
        .mb_debug_sys_rst(1'b0),
        .peripheral_aresetn(proc_sys_reset_0_peripheral_aresetn),
        .slowest_sync_clk(clk_wiz_0_clk_out2));
  design_1_proc_sys_reset_1_0 proc_sys_reset_1
       (.aux_reset_in(1'b1),
        .dcm_locked(1'b1),
        .ext_reset_in(processing_system7_0_FCLK_RESET0_N),
        .mb_debug_sys_rst(1'b0),
        .peripheral_aresetn(proc_sys_reset_1_peripheral_aresetn),
        .slowest_sync_clk(clk_wiz_0_clk_out1));
  design_1_proc_sys_reset_2_0 proc_sys_reset_2
       (.aux_reset_in(1'b1),
        .dcm_locked(1'b1),
        .ext_reset_in(processing_system7_0_FCLK_RESET0_N),
        .mb_debug_sys_rst(1'b0),
        .peripheral_aresetn(proc_sys_reset_2_peripheral_aresetn),
        .slowest_sync_clk(clk_wiz_0_clk_out3));
  design_1_processing_system7_0_0 processing_system7_0
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
        .FCLK_CLK0(processing_system7_0_FCLK_CLK0),
        .FCLK_CLK1(processing_system7_0_FCLK_CLK1),
        .FCLK_RESET0_N(processing_system7_0_FCLK_RESET0_N),
        .IRQ_F2P(dpu_eu_0_dpu_interrupt),
        .MIO(FIXED_IO_mio[53:0]),
        .M_AXI_GP0_ACLK(processing_system7_0_FCLK_CLK0),
        .M_AXI_GP0_ARADDR(processing_system7_0_M_AXI_GP0_ARADDR),
        .M_AXI_GP0_ARBURST(processing_system7_0_M_AXI_GP0_ARBURST),
        .M_AXI_GP0_ARCACHE(processing_system7_0_M_AXI_GP0_ARCACHE),
        .M_AXI_GP0_ARID(processing_system7_0_M_AXI_GP0_ARID),
        .M_AXI_GP0_ARLEN(processing_system7_0_M_AXI_GP0_ARLEN),
        .M_AXI_GP0_ARLOCK(processing_system7_0_M_AXI_GP0_ARLOCK),
        .M_AXI_GP0_ARPROT(processing_system7_0_M_AXI_GP0_ARPROT),
        .M_AXI_GP0_ARQOS(processing_system7_0_M_AXI_GP0_ARQOS),
        .M_AXI_GP0_ARREADY(processing_system7_0_M_AXI_GP0_ARREADY),
        .M_AXI_GP0_ARSIZE(processing_system7_0_M_AXI_GP0_ARSIZE),
        .M_AXI_GP0_ARVALID(processing_system7_0_M_AXI_GP0_ARVALID),
        .M_AXI_GP0_AWADDR(processing_system7_0_M_AXI_GP0_AWADDR),
        .M_AXI_GP0_AWBURST(processing_system7_0_M_AXI_GP0_AWBURST),
        .M_AXI_GP0_AWCACHE(processing_system7_0_M_AXI_GP0_AWCACHE),
        .M_AXI_GP0_AWID(processing_system7_0_M_AXI_GP0_AWID),
        .M_AXI_GP0_AWLEN(processing_system7_0_M_AXI_GP0_AWLEN),
        .M_AXI_GP0_AWLOCK(processing_system7_0_M_AXI_GP0_AWLOCK),
        .M_AXI_GP0_AWPROT(processing_system7_0_M_AXI_GP0_AWPROT),
        .M_AXI_GP0_AWQOS(processing_system7_0_M_AXI_GP0_AWQOS),
        .M_AXI_GP0_AWREADY(processing_system7_0_M_AXI_GP0_AWREADY),
        .M_AXI_GP0_AWSIZE(processing_system7_0_M_AXI_GP0_AWSIZE),
        .M_AXI_GP0_AWVALID(processing_system7_0_M_AXI_GP0_AWVALID),
        .M_AXI_GP0_BID(processing_system7_0_M_AXI_GP0_BID),
        .M_AXI_GP0_BREADY(processing_system7_0_M_AXI_GP0_BREADY),
        .M_AXI_GP0_BRESP(processing_system7_0_M_AXI_GP0_BRESP),
        .M_AXI_GP0_BVALID(processing_system7_0_M_AXI_GP0_BVALID),
        .M_AXI_GP0_RDATA(processing_system7_0_M_AXI_GP0_RDATA),
        .M_AXI_GP0_RID(processing_system7_0_M_AXI_GP0_RID),
        .M_AXI_GP0_RLAST(processing_system7_0_M_AXI_GP0_RLAST),
        .M_AXI_GP0_RREADY(processing_system7_0_M_AXI_GP0_RREADY),
        .M_AXI_GP0_RRESP(processing_system7_0_M_AXI_GP0_RRESP),
        .M_AXI_GP0_RVALID(processing_system7_0_M_AXI_GP0_RVALID),
        .M_AXI_GP0_WDATA(processing_system7_0_M_AXI_GP0_WDATA),
        .M_AXI_GP0_WID(processing_system7_0_M_AXI_GP0_WID),
        .M_AXI_GP0_WLAST(processing_system7_0_M_AXI_GP0_WLAST),
        .M_AXI_GP0_WREADY(processing_system7_0_M_AXI_GP0_WREADY),
        .M_AXI_GP0_WSTRB(processing_system7_0_M_AXI_GP0_WSTRB),
        .M_AXI_GP0_WVALID(processing_system7_0_M_AXI_GP0_WVALID),
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
        .S_AXI_HP3_ACLK(clk_wiz_0_clk_out1),
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
        .S_AXI_HP3_AWADDR(vdma_icc_M00_AXI_AWADDR),
        .S_AXI_HP3_AWBURST(vdma_icc_M00_AXI_AWBURST),
        .S_AXI_HP3_AWCACHE(vdma_icc_M00_AXI_AWCACHE),
        .S_AXI_HP3_AWID({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP3_AWLEN(vdma_icc_M00_AXI_AWLEN),
        .S_AXI_HP3_AWLOCK(vdma_icc_M00_AXI_AWLOCK),
        .S_AXI_HP3_AWPROT(vdma_icc_M00_AXI_AWPROT),
        .S_AXI_HP3_AWQOS(vdma_icc_M00_AXI_AWQOS),
        .S_AXI_HP3_AWREADY(vdma_icc_M00_AXI_AWREADY),
        .S_AXI_HP3_AWSIZE(vdma_icc_M00_AXI_AWSIZE),
        .S_AXI_HP3_AWVALID(vdma_icc_M00_AXI_AWVALID),
        .S_AXI_HP3_BREADY(vdma_icc_M00_AXI_BREADY),
        .S_AXI_HP3_BRESP(vdma_icc_M00_AXI_BRESP),
        .S_AXI_HP3_BVALID(vdma_icc_M00_AXI_BVALID),
        .S_AXI_HP3_RDISSUECAP1_EN(1'b0),
        .S_AXI_HP3_RREADY(1'b0),
        .S_AXI_HP3_WDATA(vdma_icc_M00_AXI_WDATA),
        .S_AXI_HP3_WID({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .S_AXI_HP3_WLAST(vdma_icc_M00_AXI_WLAST),
        .S_AXI_HP3_WREADY(vdma_icc_M00_AXI_WREADY),
        .S_AXI_HP3_WRISSUECAP1_EN(1'b0),
        .S_AXI_HP3_WSTRB(vdma_icc_M00_AXI_WSTRB),
        .S_AXI_HP3_WVALID(vdma_icc_M00_AXI_WVALID));
  design_1_rst_300M_0 rst_300M
       (.aux_reset_in(1'b1),
        .dcm_locked(1'b1),
        .ext_reset_in(processing_system7_0_FCLK_RESET0_N),
        .mb_debug_sys_rst(1'b0),
        .peripheral_aresetn(rst_300M_peripheral_aresetn),
        .slowest_sync_clk(clk_wiz_0_clk_out3));
  design_1_rst_ps7_0_50M_0 rst_ps7_0_50M
       (.aux_reset_in(1'b1),
        .dcm_locked(1'b1),
        .ext_reset_in(processing_system7_0_FCLK_RESET0_N),
        .mb_debug_sys_rst(1'b0),
        .slowest_sync_clk(processing_system7_0_FCLK_CLK0));
  design_1_vdma_icc_0 vdma_icc
       (.ACLK(clk_wiz_0_clk_out1),
        .ARESETN(proc_sys_reset_1_peripheral_aresetn),
        .M00_ACLK(clk_wiz_0_clk_out1),
        .M00_ARESETN(proc_sys_reset_1_peripheral_aresetn),
        .M00_AXI_awaddr(vdma_icc_M00_AXI_AWADDR),
        .M00_AXI_awburst(vdma_icc_M00_AXI_AWBURST),
        .M00_AXI_awcache(vdma_icc_M00_AXI_AWCACHE),
        .M00_AXI_awlen(vdma_icc_M00_AXI_AWLEN),
        .M00_AXI_awlock(vdma_icc_M00_AXI_AWLOCK),
        .M00_AXI_awprot(vdma_icc_M00_AXI_AWPROT),
        .M00_AXI_awqos(vdma_icc_M00_AXI_AWQOS),
        .M00_AXI_awready(vdma_icc_M00_AXI_AWREADY),
        .M00_AXI_awsize(vdma_icc_M00_AXI_AWSIZE),
        .M00_AXI_awvalid(vdma_icc_M00_AXI_AWVALID),
        .M00_AXI_bready(vdma_icc_M00_AXI_BREADY),
        .M00_AXI_bresp(vdma_icc_M00_AXI_BRESP),
        .M00_AXI_bvalid(vdma_icc_M00_AXI_BVALID),
        .M00_AXI_wdata(vdma_icc_M00_AXI_WDATA),
        .M00_AXI_wlast(vdma_icc_M00_AXI_WLAST),
        .M00_AXI_wready(vdma_icc_M00_AXI_WREADY),
        .M00_AXI_wstrb(vdma_icc_M00_AXI_WSTRB),
        .M00_AXI_wvalid(vdma_icc_M00_AXI_WVALID),
        .S00_ACLK(clk_wiz_0_clk_out1),
        .S00_ARESETN(proc_sys_reset_1_peripheral_aresetn),
        .S00_AXI_awaddr(axi_vdma_0_M_AXI_S2MM_AWADDR),
        .S00_AXI_awburst(axi_vdma_0_M_AXI_S2MM_AWBURST),
        .S00_AXI_awcache(axi_vdma_0_M_AXI_S2MM_AWCACHE),
        .S00_AXI_awlen(axi_vdma_0_M_AXI_S2MM_AWLEN),
        .S00_AXI_awprot(axi_vdma_0_M_AXI_S2MM_AWPROT),
        .S00_AXI_awready(axi_vdma_0_M_AXI_S2MM_AWREADY),
        .S00_AXI_awsize(axi_vdma_0_M_AXI_S2MM_AWSIZE),
        .S00_AXI_awvalid(axi_vdma_0_M_AXI_S2MM_AWVALID),
        .S00_AXI_bready(axi_vdma_0_M_AXI_S2MM_BREADY),
        .S00_AXI_bresp(axi_vdma_0_M_AXI_S2MM_BRESP),
        .S00_AXI_bvalid(axi_vdma_0_M_AXI_S2MM_BVALID),
        .S00_AXI_wdata(axi_vdma_0_M_AXI_S2MM_WDATA),
        .S00_AXI_wlast(axi_vdma_0_M_AXI_S2MM_WLAST),
        .S00_AXI_wready(axi_vdma_0_M_AXI_S2MM_WREADY),
        .S00_AXI_wstrb(axi_vdma_0_M_AXI_S2MM_WSTRB),
        .S00_AXI_wvalid(axi_vdma_0_M_AXI_S2MM_WVALID));
endmodule

module design_1_vdma_icc_0
   (ACLK,
    ARESETN,
    M00_ACLK,
    M00_ARESETN,
    M00_AXI_awaddr,
    M00_AXI_awburst,
    M00_AXI_awcache,
    M00_AXI_awlen,
    M00_AXI_awlock,
    M00_AXI_awprot,
    M00_AXI_awqos,
    M00_AXI_awready,
    M00_AXI_awsize,
    M00_AXI_awvalid,
    M00_AXI_bready,
    M00_AXI_bresp,
    M00_AXI_bvalid,
    M00_AXI_wdata,
    M00_AXI_wlast,
    M00_AXI_wready,
    M00_AXI_wstrb,
    M00_AXI_wvalid,
    S00_ACLK,
    S00_ARESETN,
    S00_AXI_awaddr,
    S00_AXI_awburst,
    S00_AXI_awcache,
    S00_AXI_awlen,
    S00_AXI_awprot,
    S00_AXI_awready,
    S00_AXI_awsize,
    S00_AXI_awvalid,
    S00_AXI_bready,
    S00_AXI_bresp,
    S00_AXI_bvalid,
    S00_AXI_wdata,
    S00_AXI_wlast,
    S00_AXI_wready,
    S00_AXI_wstrb,
    S00_AXI_wvalid);
  input ACLK;
  input ARESETN;
  input M00_ACLK;
  input M00_ARESETN;
  output [31:0]M00_AXI_awaddr;
  output [1:0]M00_AXI_awburst;
  output [3:0]M00_AXI_awcache;
  output [3:0]M00_AXI_awlen;
  output [1:0]M00_AXI_awlock;
  output [2:0]M00_AXI_awprot;
  output [3:0]M00_AXI_awqos;
  input M00_AXI_awready;
  output [2:0]M00_AXI_awsize;
  output M00_AXI_awvalid;
  output M00_AXI_bready;
  input [1:0]M00_AXI_bresp;
  input M00_AXI_bvalid;
  output [63:0]M00_AXI_wdata;
  output M00_AXI_wlast;
  input M00_AXI_wready;
  output [7:0]M00_AXI_wstrb;
  output M00_AXI_wvalid;
  input S00_ACLK;
  input S00_ARESETN;
  input [31:0]S00_AXI_awaddr;
  input [1:0]S00_AXI_awburst;
  input [3:0]S00_AXI_awcache;
  input [7:0]S00_AXI_awlen;
  input [2:0]S00_AXI_awprot;
  output S00_AXI_awready;
  input [2:0]S00_AXI_awsize;
  input S00_AXI_awvalid;
  input S00_AXI_bready;
  output [1:0]S00_AXI_bresp;
  output S00_AXI_bvalid;
  input [63:0]S00_AXI_wdata;
  input S00_AXI_wlast;
  output S00_AXI_wready;
  input [7:0]S00_AXI_wstrb;
  input S00_AXI_wvalid;

  wire S00_ACLK_1;
  wire S00_ARESETN_1;
  wire [31:0]s00_couplers_to_vdma_icc_AWADDR;
  wire [1:0]s00_couplers_to_vdma_icc_AWBURST;
  wire [3:0]s00_couplers_to_vdma_icc_AWCACHE;
  wire [3:0]s00_couplers_to_vdma_icc_AWLEN;
  wire [1:0]s00_couplers_to_vdma_icc_AWLOCK;
  wire [2:0]s00_couplers_to_vdma_icc_AWPROT;
  wire [3:0]s00_couplers_to_vdma_icc_AWQOS;
  wire s00_couplers_to_vdma_icc_AWREADY;
  wire [2:0]s00_couplers_to_vdma_icc_AWSIZE;
  wire s00_couplers_to_vdma_icc_AWVALID;
  wire s00_couplers_to_vdma_icc_BREADY;
  wire [1:0]s00_couplers_to_vdma_icc_BRESP;
  wire s00_couplers_to_vdma_icc_BVALID;
  wire [63:0]s00_couplers_to_vdma_icc_WDATA;
  wire s00_couplers_to_vdma_icc_WLAST;
  wire s00_couplers_to_vdma_icc_WREADY;
  wire [7:0]s00_couplers_to_vdma_icc_WSTRB;
  wire s00_couplers_to_vdma_icc_WVALID;
  wire vdma_icc_ACLK_net;
  wire vdma_icc_ARESETN_net;
  wire [31:0]vdma_icc_to_s00_couplers_AWADDR;
  wire [1:0]vdma_icc_to_s00_couplers_AWBURST;
  wire [3:0]vdma_icc_to_s00_couplers_AWCACHE;
  wire [7:0]vdma_icc_to_s00_couplers_AWLEN;
  wire [2:0]vdma_icc_to_s00_couplers_AWPROT;
  wire vdma_icc_to_s00_couplers_AWREADY;
  wire [2:0]vdma_icc_to_s00_couplers_AWSIZE;
  wire vdma_icc_to_s00_couplers_AWVALID;
  wire vdma_icc_to_s00_couplers_BREADY;
  wire [1:0]vdma_icc_to_s00_couplers_BRESP;
  wire vdma_icc_to_s00_couplers_BVALID;
  wire [63:0]vdma_icc_to_s00_couplers_WDATA;
  wire vdma_icc_to_s00_couplers_WLAST;
  wire vdma_icc_to_s00_couplers_WREADY;
  wire [7:0]vdma_icc_to_s00_couplers_WSTRB;
  wire vdma_icc_to_s00_couplers_WVALID;

  assign M00_AXI_awaddr[31:0] = s00_couplers_to_vdma_icc_AWADDR;
  assign M00_AXI_awburst[1:0] = s00_couplers_to_vdma_icc_AWBURST;
  assign M00_AXI_awcache[3:0] = s00_couplers_to_vdma_icc_AWCACHE;
  assign M00_AXI_awlen[3:0] = s00_couplers_to_vdma_icc_AWLEN;
  assign M00_AXI_awlock[1:0] = s00_couplers_to_vdma_icc_AWLOCK;
  assign M00_AXI_awprot[2:0] = s00_couplers_to_vdma_icc_AWPROT;
  assign M00_AXI_awqos[3:0] = s00_couplers_to_vdma_icc_AWQOS;
  assign M00_AXI_awsize[2:0] = s00_couplers_to_vdma_icc_AWSIZE;
  assign M00_AXI_awvalid = s00_couplers_to_vdma_icc_AWVALID;
  assign M00_AXI_bready = s00_couplers_to_vdma_icc_BREADY;
  assign M00_AXI_wdata[63:0] = s00_couplers_to_vdma_icc_WDATA;
  assign M00_AXI_wlast = s00_couplers_to_vdma_icc_WLAST;
  assign M00_AXI_wstrb[7:0] = s00_couplers_to_vdma_icc_WSTRB;
  assign M00_AXI_wvalid = s00_couplers_to_vdma_icc_WVALID;
  assign S00_ACLK_1 = S00_ACLK;
  assign S00_ARESETN_1 = S00_ARESETN;
  assign S00_AXI_awready = vdma_icc_to_s00_couplers_AWREADY;
  assign S00_AXI_bresp[1:0] = vdma_icc_to_s00_couplers_BRESP;
  assign S00_AXI_bvalid = vdma_icc_to_s00_couplers_BVALID;
  assign S00_AXI_wready = vdma_icc_to_s00_couplers_WREADY;
  assign s00_couplers_to_vdma_icc_AWREADY = M00_AXI_awready;
  assign s00_couplers_to_vdma_icc_BRESP = M00_AXI_bresp[1:0];
  assign s00_couplers_to_vdma_icc_BVALID = M00_AXI_bvalid;
  assign s00_couplers_to_vdma_icc_WREADY = M00_AXI_wready;
  assign vdma_icc_ACLK_net = M00_ACLK;
  assign vdma_icc_ARESETN_net = M00_ARESETN;
  assign vdma_icc_to_s00_couplers_AWADDR = S00_AXI_awaddr[31:0];
  assign vdma_icc_to_s00_couplers_AWBURST = S00_AXI_awburst[1:0];
  assign vdma_icc_to_s00_couplers_AWCACHE = S00_AXI_awcache[3:0];
  assign vdma_icc_to_s00_couplers_AWLEN = S00_AXI_awlen[7:0];
  assign vdma_icc_to_s00_couplers_AWPROT = S00_AXI_awprot[2:0];
  assign vdma_icc_to_s00_couplers_AWSIZE = S00_AXI_awsize[2:0];
  assign vdma_icc_to_s00_couplers_AWVALID = S00_AXI_awvalid;
  assign vdma_icc_to_s00_couplers_BREADY = S00_AXI_bready;
  assign vdma_icc_to_s00_couplers_WDATA = S00_AXI_wdata[63:0];
  assign vdma_icc_to_s00_couplers_WLAST = S00_AXI_wlast;
  assign vdma_icc_to_s00_couplers_WSTRB = S00_AXI_wstrb[7:0];
  assign vdma_icc_to_s00_couplers_WVALID = S00_AXI_wvalid;
  s00_couplers_imp_1V41RD5 s00_couplers
       (.M_ACLK(vdma_icc_ACLK_net),
        .M_ARESETN(vdma_icc_ARESETN_net),
        .M_AXI_awaddr(s00_couplers_to_vdma_icc_AWADDR),
        .M_AXI_awburst(s00_couplers_to_vdma_icc_AWBURST),
        .M_AXI_awcache(s00_couplers_to_vdma_icc_AWCACHE),
        .M_AXI_awlen(s00_couplers_to_vdma_icc_AWLEN),
        .M_AXI_awlock(s00_couplers_to_vdma_icc_AWLOCK),
        .M_AXI_awprot(s00_couplers_to_vdma_icc_AWPROT),
        .M_AXI_awqos(s00_couplers_to_vdma_icc_AWQOS),
        .M_AXI_awready(s00_couplers_to_vdma_icc_AWREADY),
        .M_AXI_awsize(s00_couplers_to_vdma_icc_AWSIZE),
        .M_AXI_awvalid(s00_couplers_to_vdma_icc_AWVALID),
        .M_AXI_bready(s00_couplers_to_vdma_icc_BREADY),
        .M_AXI_bresp(s00_couplers_to_vdma_icc_BRESP),
        .M_AXI_bvalid(s00_couplers_to_vdma_icc_BVALID),
        .M_AXI_wdata(s00_couplers_to_vdma_icc_WDATA),
        .M_AXI_wlast(s00_couplers_to_vdma_icc_WLAST),
        .M_AXI_wready(s00_couplers_to_vdma_icc_WREADY),
        .M_AXI_wstrb(s00_couplers_to_vdma_icc_WSTRB),
        .M_AXI_wvalid(s00_couplers_to_vdma_icc_WVALID),
        .S_ACLK(S00_ACLK_1),
        .S_ARESETN(S00_ARESETN_1),
        .S_AXI_awaddr(vdma_icc_to_s00_couplers_AWADDR),
        .S_AXI_awburst(vdma_icc_to_s00_couplers_AWBURST),
        .S_AXI_awcache(vdma_icc_to_s00_couplers_AWCACHE),
        .S_AXI_awlen(vdma_icc_to_s00_couplers_AWLEN),
        .S_AXI_awprot(vdma_icc_to_s00_couplers_AWPROT),
        .S_AXI_awready(vdma_icc_to_s00_couplers_AWREADY),
        .S_AXI_awsize(vdma_icc_to_s00_couplers_AWSIZE),
        .S_AXI_awvalid(vdma_icc_to_s00_couplers_AWVALID),
        .S_AXI_bready(vdma_icc_to_s00_couplers_BREADY),
        .S_AXI_bresp(vdma_icc_to_s00_couplers_BRESP),
        .S_AXI_bvalid(vdma_icc_to_s00_couplers_BVALID),
        .S_AXI_wdata(vdma_icc_to_s00_couplers_WDATA),
        .S_AXI_wlast(vdma_icc_to_s00_couplers_WLAST),
        .S_AXI_wready(vdma_icc_to_s00_couplers_WREADY),
        .S_AXI_wstrb(vdma_icc_to_s00_couplers_WSTRB),
        .S_AXI_wvalid(vdma_icc_to_s00_couplers_WVALID));
endmodule

module s00_couplers_imp_1V41RD5
   (M_ACLK,
    M_ARESETN,
    M_AXI_awaddr,
    M_AXI_awburst,
    M_AXI_awcache,
    M_AXI_awlen,
    M_AXI_awlock,
    M_AXI_awprot,
    M_AXI_awqos,
    M_AXI_awready,
    M_AXI_awsize,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_wdata,
    M_AXI_wlast,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_awaddr,
    S_AXI_awburst,
    S_AXI_awcache,
    S_AXI_awlen,
    S_AXI_awprot,
    S_AXI_awready,
    S_AXI_awsize,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_wdata,
    S_AXI_wlast,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_awaddr;
  output [1:0]M_AXI_awburst;
  output [3:0]M_AXI_awcache;
  output [3:0]M_AXI_awlen;
  output [1:0]M_AXI_awlock;
  output [2:0]M_AXI_awprot;
  output [3:0]M_AXI_awqos;
  input M_AXI_awready;
  output [2:0]M_AXI_awsize;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  output [63:0]M_AXI_wdata;
  output M_AXI_wlast;
  input M_AXI_wready;
  output [7:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_awaddr;
  input [1:0]S_AXI_awburst;
  input [3:0]S_AXI_awcache;
  input [7:0]S_AXI_awlen;
  input [2:0]S_AXI_awprot;
  output S_AXI_awready;
  input [2:0]S_AXI_awsize;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  input [63:0]S_AXI_wdata;
  input S_AXI_wlast;
  output S_AXI_wready;
  input [7:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire S_ACLK_1;
  wire S_ARESETN_1;
  wire [31:0]auto_pc_to_s00_couplers_AWADDR;
  wire [1:0]auto_pc_to_s00_couplers_AWBURST;
  wire [3:0]auto_pc_to_s00_couplers_AWCACHE;
  wire [3:0]auto_pc_to_s00_couplers_AWLEN;
  wire [1:0]auto_pc_to_s00_couplers_AWLOCK;
  wire [2:0]auto_pc_to_s00_couplers_AWPROT;
  wire [3:0]auto_pc_to_s00_couplers_AWQOS;
  wire auto_pc_to_s00_couplers_AWREADY;
  wire [2:0]auto_pc_to_s00_couplers_AWSIZE;
  wire auto_pc_to_s00_couplers_AWVALID;
  wire auto_pc_to_s00_couplers_BREADY;
  wire [1:0]auto_pc_to_s00_couplers_BRESP;
  wire auto_pc_to_s00_couplers_BVALID;
  wire [63:0]auto_pc_to_s00_couplers_WDATA;
  wire auto_pc_to_s00_couplers_WLAST;
  wire auto_pc_to_s00_couplers_WREADY;
  wire [7:0]auto_pc_to_s00_couplers_WSTRB;
  wire auto_pc_to_s00_couplers_WVALID;
  wire [31:0]s00_couplers_to_auto_pc_AWADDR;
  wire [1:0]s00_couplers_to_auto_pc_AWBURST;
  wire [3:0]s00_couplers_to_auto_pc_AWCACHE;
  wire [7:0]s00_couplers_to_auto_pc_AWLEN;
  wire [2:0]s00_couplers_to_auto_pc_AWPROT;
  wire s00_couplers_to_auto_pc_AWREADY;
  wire [2:0]s00_couplers_to_auto_pc_AWSIZE;
  wire s00_couplers_to_auto_pc_AWVALID;
  wire s00_couplers_to_auto_pc_BREADY;
  wire [1:0]s00_couplers_to_auto_pc_BRESP;
  wire s00_couplers_to_auto_pc_BVALID;
  wire [63:0]s00_couplers_to_auto_pc_WDATA;
  wire s00_couplers_to_auto_pc_WLAST;
  wire s00_couplers_to_auto_pc_WREADY;
  wire [7:0]s00_couplers_to_auto_pc_WSTRB;
  wire s00_couplers_to_auto_pc_WVALID;

  assign M_AXI_awaddr[31:0] = auto_pc_to_s00_couplers_AWADDR;
  assign M_AXI_awburst[1:0] = auto_pc_to_s00_couplers_AWBURST;
  assign M_AXI_awcache[3:0] = auto_pc_to_s00_couplers_AWCACHE;
  assign M_AXI_awlen[3:0] = auto_pc_to_s00_couplers_AWLEN;
  assign M_AXI_awlock[1:0] = auto_pc_to_s00_couplers_AWLOCK;
  assign M_AXI_awprot[2:0] = auto_pc_to_s00_couplers_AWPROT;
  assign M_AXI_awqos[3:0] = auto_pc_to_s00_couplers_AWQOS;
  assign M_AXI_awsize[2:0] = auto_pc_to_s00_couplers_AWSIZE;
  assign M_AXI_awvalid = auto_pc_to_s00_couplers_AWVALID;
  assign M_AXI_bready = auto_pc_to_s00_couplers_BREADY;
  assign M_AXI_wdata[63:0] = auto_pc_to_s00_couplers_WDATA;
  assign M_AXI_wlast = auto_pc_to_s00_couplers_WLAST;
  assign M_AXI_wstrb[7:0] = auto_pc_to_s00_couplers_WSTRB;
  assign M_AXI_wvalid = auto_pc_to_s00_couplers_WVALID;
  assign S_ACLK_1 = S_ACLK;
  assign S_ARESETN_1 = S_ARESETN;
  assign S_AXI_awready = s00_couplers_to_auto_pc_AWREADY;
  assign S_AXI_bresp[1:0] = s00_couplers_to_auto_pc_BRESP;
  assign S_AXI_bvalid = s00_couplers_to_auto_pc_BVALID;
  assign S_AXI_wready = s00_couplers_to_auto_pc_WREADY;
  assign auto_pc_to_s00_couplers_AWREADY = M_AXI_awready;
  assign auto_pc_to_s00_couplers_BRESP = M_AXI_bresp[1:0];
  assign auto_pc_to_s00_couplers_BVALID = M_AXI_bvalid;
  assign auto_pc_to_s00_couplers_WREADY = M_AXI_wready;
  assign s00_couplers_to_auto_pc_AWADDR = S_AXI_awaddr[31:0];
  assign s00_couplers_to_auto_pc_AWBURST = S_AXI_awburst[1:0];
  assign s00_couplers_to_auto_pc_AWCACHE = S_AXI_awcache[3:0];
  assign s00_couplers_to_auto_pc_AWLEN = S_AXI_awlen[7:0];
  assign s00_couplers_to_auto_pc_AWPROT = S_AXI_awprot[2:0];
  assign s00_couplers_to_auto_pc_AWSIZE = S_AXI_awsize[2:0];
  assign s00_couplers_to_auto_pc_AWVALID = S_AXI_awvalid;
  assign s00_couplers_to_auto_pc_BREADY = S_AXI_bready;
  assign s00_couplers_to_auto_pc_WDATA = S_AXI_wdata[63:0];
  assign s00_couplers_to_auto_pc_WLAST = S_AXI_wlast;
  assign s00_couplers_to_auto_pc_WSTRB = S_AXI_wstrb[7:0];
  assign s00_couplers_to_auto_pc_WVALID = S_AXI_wvalid;
  design_1_auto_pc_0 auto_pc
       (.aclk(S_ACLK_1),
        .aresetn(S_ARESETN_1),
        .m_axi_awaddr(auto_pc_to_s00_couplers_AWADDR),
        .m_axi_awburst(auto_pc_to_s00_couplers_AWBURST),
        .m_axi_awcache(auto_pc_to_s00_couplers_AWCACHE),
        .m_axi_awlen(auto_pc_to_s00_couplers_AWLEN),
        .m_axi_awlock(auto_pc_to_s00_couplers_AWLOCK),
        .m_axi_awprot(auto_pc_to_s00_couplers_AWPROT),
        .m_axi_awqos(auto_pc_to_s00_couplers_AWQOS),
        .m_axi_awready(auto_pc_to_s00_couplers_AWREADY),
        .m_axi_awsize(auto_pc_to_s00_couplers_AWSIZE),
        .m_axi_awvalid(auto_pc_to_s00_couplers_AWVALID),
        .m_axi_bready(auto_pc_to_s00_couplers_BREADY),
        .m_axi_bresp(auto_pc_to_s00_couplers_BRESP),
        .m_axi_bvalid(auto_pc_to_s00_couplers_BVALID),
        .m_axi_wdata(auto_pc_to_s00_couplers_WDATA),
        .m_axi_wlast(auto_pc_to_s00_couplers_WLAST),
        .m_axi_wready(auto_pc_to_s00_couplers_WREADY),
        .m_axi_wstrb(auto_pc_to_s00_couplers_WSTRB),
        .m_axi_wvalid(auto_pc_to_s00_couplers_WVALID),
        .s_axi_awaddr(s00_couplers_to_auto_pc_AWADDR),
        .s_axi_awburst(s00_couplers_to_auto_pc_AWBURST),
        .s_axi_awcache(s00_couplers_to_auto_pc_AWCACHE),
        .s_axi_awlen(s00_couplers_to_auto_pc_AWLEN),
        .s_axi_awlock(1'b0),
        .s_axi_awprot(s00_couplers_to_auto_pc_AWPROT),
        .s_axi_awqos({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(s00_couplers_to_auto_pc_AWREADY),
        .s_axi_awregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awsize(s00_couplers_to_auto_pc_AWSIZE),
        .s_axi_awvalid(s00_couplers_to_auto_pc_AWVALID),
        .s_axi_bready(s00_couplers_to_auto_pc_BREADY),
        .s_axi_bresp(s00_couplers_to_auto_pc_BRESP),
        .s_axi_bvalid(s00_couplers_to_auto_pc_BVALID),
        .s_axi_wdata(s00_couplers_to_auto_pc_WDATA),
        .s_axi_wlast(s00_couplers_to_auto_pc_WLAST),
        .s_axi_wready(s00_couplers_to_auto_pc_WREADY),
        .s_axi_wstrb(s00_couplers_to_auto_pc_WSTRB),
        .s_axi_wvalid(s00_couplers_to_auto_pc_WVALID));
endmodule
