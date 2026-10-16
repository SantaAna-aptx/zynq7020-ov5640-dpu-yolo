# BD surgery v2: VDMA control via PS M_AXI_GP1 (direct, no interconnect changes).
# Revert axi_smc from the failed v1 attempt first.
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]

set smc [get_bd_cells axi_smc]
puts "BEFORE: NUM_SI=[get_property CONFIG.NUM_SI $smc] NUM_MI=[get_property CONFIG.NUM_MI $smc] NUM_CLOCKS=[get_property CONFIG.NUM_CLOCKS $smc]"
# revert v1 leftovers
catch { set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_CLOCKS {1}] $smc } e0
puts "revert smc: $e0"

# enable PS GP1
set ps7 [get_bd_cells processing_system7_0]
if {[catch { set_property CONFIG.PCW_USE_M_AXI_GP1 {1} $ps7 } ep]} {
    puts "GP1_ENABLE_ERR: $ep"
}
# materialize PS changes
catch { validate_bd_design } ev
puts "validate after ps gp1: $ev"

# wire GP1 ACLK to clk_out1 (camera domain, matches vdma s_axi_lite_aclk)
set g1aclk [get_bd_pins -quiet processing_system7_0/M_AXI_GP1_ACLK]
puts "GP1_ACLK pin: $g1aclk"
if {[llength $g1aclk]} {
    set nets [get_bd_nets -quiet -of_objects $g1aclk]
    if {[llength $nets] == 0} {
        connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] $g1aclk
        puts "GP1_ACLK <- clk_out1"
    } else { puts "GP1_ACLK already netted: [get_property NAME [lindex $nets 0]]" }
}

# connect VDMA LITE -> GP1
set lite [get_bd_intf_pins -quiet axi_vdma_0/S_AXI_LITE]
if {[llength [get_bd_intf_nets -quiet -of_objects $lite]] == 0} {
    connect_bd_intf_net [get_bd_intf_pins axi_vdma_0/S_AXI_LITE] [get_bd_intf_pins processing_system7_0/M_AXI_GP1]
    puts "vdma LITE -> GP1 connected"
} else { puts "vdma LITE already connected" }

if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v" } else { puts "validate OK" }

# assign address 0x43C00000
set seg [get_bd_addr_segs -quiet axi_vdma_0/s_axi_lite/Reg]
puts "vdma seg: $seg"
if {[llength $seg]} {
    assign_bd_address -target_address_space /processing_system7_0/Data [get_bd_addr_segs $seg] -offset 0x43C00000 -range 64K
    puts "assigned 0x43C00000"
}
save_bd_design

# dump final state
puts "GP1 members check:"
set g1 [get_bd_intf_pins -quiet processing_system7_0/M_AXI_GP1]
puts "GP1 intf: $g1 nets: [get_bd_intf_nets -quiet -of_objects $g1]"
puts "BD_VDMA_LITE2_DONE"
