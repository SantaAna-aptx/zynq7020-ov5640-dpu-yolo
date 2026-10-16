# BD repair v11: complete the camera memory path per original v10 blueprint.
# 1) vdma_icc (axi_interconnect 1x1, data FIFO, regslice) : vdma M_AXI_S2MM -> HP3
# 2) clocks/resets on clk_out1 domain (proc_sys_reset_1)
# 3) disable the dangling M_AXI_GP1 left from a failed attempt
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]

# 0) verify vdma memory master is unconnected
set mm [get_bd_intf_pins -quiet axi_vdma_0/M_AXI_S2MM]
set mn [get_bd_intf_nets -quiet -of_objects $mm]
if {[llength $mn]} { puts "M_AXI_S2MM already connected: [get_property NAME [lindex $mn 0]]"; exit 0 }
puts "M_AXI_S2MM unconnected - proceeding"

# 1) clean the dangling GP1 (v2 leftover)
set g1a [get_bd_pins -quiet processing_system7_0/M_AXI_GP1_ACLK]
if {[llength $g1a]} {
    set gn [get_bd_nets -quiet -of_objects $g1a]
    if {[llength $gn]} { delete_bd_objs [lindex $gn 0]; puts "deleted GP1_ACLK net" }
}
catch { set_property CONFIG.PCW_USE_M_AXI_GP1 {0} [get_bd_cells processing_system7_0] } eg1
puts "gp1 disable: $eg1"

# 2) create vdma_icc exactly like original v10
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 vdma_icc
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1} \
  CONFIG.S00_HAS_DATA_FIFO {2} CONFIG.M00_HAS_DATA_FIFO {2} \
  CONFIG.S00_HAS_REGSLICE {1} CONFIG.M00_HAS_REGSLICE {1}] [get_bd_cells vdma_icc]
connect_bd_intf_net [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM] [get_bd_intf_pins vdma_icc/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins vdma_icc/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP3]

# 3) clocks + resets on clk_out1 domain
set clk100 [get_bd_pins clk_wiz_0/clk_out1]
set rst100 [get_bd_pins proc_sys_reset_1/peripheral_aresetn]
connect_bd_net $clk100 [get_bd_pins vdma_icc/ACLK]
connect_bd_net $clk100 [get_bd_pins vdma_icc/S00_ACLK]
connect_bd_net $clk100 [get_bd_pins vdma_icc/M00_ACLK]
connect_bd_net $rst100 [get_bd_pins vdma_icc/ARESETN]
connect_bd_net $rst100 [get_bd_pins vdma_icc/S00_ARESETN]
connect_bd_net $rst100 [get_bd_pins vdma_icc/M00_ARESETN]
puts "vdma -> vdma_icc -> HP3 wired"

if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v"; exit 1 } else { puts "validate OK" }
catch { generate_target all [get_files design_1.bd] } eg
puts "generate: $eg"
save_bd_design
set m2 [get_bd_intf_nets -quiet -of_objects [get_bd_intf_pins -quiet axi_vdma_0/M_AXI_S2MM]]
puts "VERIFY M_AXI_S2MM net: [get_property NAME [lindex $m2 0]]"
puts "BD_REPAIR11_DONE"
