# =============================================================================
# create_dpu_project.tcl (v2)
# B1152 DPU (dpu_eu 3.0) hardware for MYIR Z-turn Board V2 (XC7Z020-2CLG400)
#
# Clock tree based on Xilinx Zynq-7000 DPU reference (dpu_eu):
#   FCLK_CLK0 (100MHz, from PS) -> clk_wiz -> clk_100M (100MHz) / clk_dpu (150MHz) / clk_dpu_2x (300MHz)
#   each clock domain has its own proc_sys_reset
# To keep this minimal and reliable, we drive DPU S_AXI at 100MHz and M_AXI
# at 150MHz/300MHz via a single clk_wiz, mirroring the reference design.
# =============================================================================

# ---------------- 0. Directories --------------------------------------------
set projDir   "E:/yoloProject/vivado_projects/zturn_v2_dpu"
set dpuIpRepo "E:/dpu_ip_repo/zcu102-dpu-trd-2019-1-timer/pl/srcs/dpu_ip"
set partName  "xc7z020clg400-2"

# ---------------- 1. Create / reset project ---------------------------------
file mkdir $projDir
create_project -force zturn_v2_dpu $projDir -part $partName
set_property target_language VHDL [current_project]

# ---------------- 2. Add DPU IP repository ----------------------------------
set_property ip_repo_paths $dpuIpRepo [current_project]
update_ip_catalog
set dpuFound [get_ipdefs -quiet xilinx.com:ip:dpu_eu:3.0]
if {[llength $dpuFound] == 0} {
    puts "ERROR: DPU IP (dpu_eu 3.0) not found!"
    return 1
} else {
    puts "OK: Found xilinx.com:ip:dpu_eu:3.0"
}

# ---------------- 3. Create Block Design -------------------------------------
create_bd_design "design_1"

# ---------------- 4. IP cells -------------------------------------------------
# 4a Zynq PS
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
# 4b DPU
create_bd_cell -type ip -vlnv xilinx.com:ip:dpu_eu:3.0 dpu_eu_0
# 4c Clocking Wizard (100/150/300)
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
# 4d reset blocks (3 clock domains)
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ;# 100M S_AXI domain
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1 ;# 150M DPU domain
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_2 ;# 300M DSP domain
# 4e AXI interconnect (PS Master -> DPU S_AXI slave)
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0

# ---------------- 5. Configure clk_wiz ---------------------------------------
# clk_wiz default port names are clk_out1/clk_out2/clk_out3 (NOT CLKOUTx_PORT).
set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {150.000} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {300.000} \
    CONFIG.CLKOUT1_USED {true} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_RESET {true} \
] [get_bd_cells clk_wiz_0]

# ---------------- 6. Configure DPU (B1152) using numeric(0/1) values ---------
set_property -dict [list \
    CONFIG.ARCH {B1152} \
    CONFIG.VER_DPU_NUM {1} \
    CONFIG.LOAD_AUGM {0} \
    CONFIG.DWCV_ENA {1} \
    CONFIG.POOL_AVERAGE {0} \
    CONFIG.CONV_RELU_ADDON {2} \
    CONFIG.SFM_ENA {0} \
    CONFIG.S_AXI_CLK_INDEPENDENT {0} \
] [get_bd_cells dpu_eu_0]

# ---------------- 7. PS IO / DDR ----------------------------------------------
# Z-turn V2 : 1GB DDR (32-bit), UART1, SD0, GEM0, USB0, QSPI.
# Enable DDR, PL clocks, and both GP0 (master) + HP0 (slave).
set_property -dict [list \
    CONFIG.PCW_EN_DDR {1} \
    CONFIG.PCW_DDR_RAM_HIGHADDR {0x3FFFFFFF} \
    CONFIG.PCW_DQ_WIDTH {32} \
    CONFIG.PCW_DQS_WIDTH {4} \
    CONFIG.PCW_DM_WIDTH {4} \
    CONFIG.PCW_EN_CLK0_PORT {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
    CONFIG.PCW_EN_RST0_PORT {1} \
    CONFIG.PCW_EN_UART1 {1} \
    CONFIG.PCW_UART1_PERIPHERAL_FREQMHZ {50} \
    CONFIG.PCW_EN_GP0 {1} \
    CONFIG.PCW_EN_GP1 {0} \
    CONFIG.PCW_EN_S_AXI_HP0 {1} \
    CONFIG.PCW_EN_S_AXI_HP1 {0} \
] [get_bd_cells processing_system7_0]

# ---------------- 8. Create DDR + FIXED_IO external ports ----------------------
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR
create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/DDR] [get_bd_intf_ports DDR]
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/FIXED_IO] [get_bd_intf_ports FIXED_IO]

# ---------------- 9. Connect clk_wiz input --------------------------------------
# clk_wiz input clock = PS FCLK_CLK0 (100MHz)
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins clk_wiz_0/clk_in1]

# ---------------- 10. Connect DPU clocks --------------------------------------
# clk_wiz outputs: clk_out1=100MHz(S_AXI), clk_out2=150MHz(M_AXI DPU), clk_out3=300MHz(DSP)
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins dpu_eu_0/s_axi_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins dpu_eu_0/m_axi_dpu_aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out3] [get_bd_pins dpu_eu_0/m_axi_dsp_aclk]

# ---------------- 11. Connect AXI interconnect clocks (100MHz domain) --------
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_interconnect_0/M00_ACLK]

# ---------------- 12. Reset blocks ---------------------------------------------
# proc_sys_reset_0 : 100MHz domain
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins dpu_eu_0/s_axi_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
# proc_sys_reset_1 : 150MHz domain
connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins proc_sys_reset_1/slowest_sync_clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_1/ext_reset_in]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins dpu_eu_0/m_axi_dpu_aresetn]
# proc_sys_reset_2 : 300MHz domain
connect_bd_net [get_bd_pins clk_wiz_0/clk_out3] [get_bd_pins proc_sys_reset_2/slowest_sync_clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_2/ext_reset_in]
connect_bd_net [get_bd_pins proc_sys_reset_2/peripheral_aresetn] [get_bd_pins dpu_eu_0/m_axi_dsp_aresetn]

# ---------------- 13. Connect data path: PS GP0 -> AXI -> DPU S_AXI ----------
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/GP0_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins dpu_eu_0/S_AXI]

# ---------------- 14. Reg + Interrupt ------------------------------------------
assign_bd_address [get_bd_addr_segs dpu_eu_0/S_AXI/reg0] [get_bd_addr_spaces processing_system7_0/Data]
# DPU interrupt -> PS PL-PS IRQ
connect_bd_net [get_bd_pins dpu_eu_0/dpu_interrupt_0] [get_bd_pins processing_system7_0/IRQ_F2P]

# ---------------- 15. Validate -------------------------------------------------
validate_bd_design
save_bd_design

# ---------------- 16. Wrapper ---------------------------------------------------
make_wrapper -files [get_files design_1.bd] -top
add_files -norecurse [file join [get_property DIRECTORY [current_project]] \
                      zturn_v2_dpu.srcs sources_1 bd design_1 hdl design_1_wrapper.vhd]
update_compile_order -fileset sources_1

# ---------------- 17. Synth / impl / bitstream ---------------------------------
launch_runs synth_1 -jobs 4
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# ---------------- 18. Export .hdf -----------------------------------------------
file mkdir [file join $projDir "export"]
write_hwdef -force -file [file join $projDir "export" "system.hdf"]
puts "=== DONE: bitstream + system.hdf in $projDir/export ==="