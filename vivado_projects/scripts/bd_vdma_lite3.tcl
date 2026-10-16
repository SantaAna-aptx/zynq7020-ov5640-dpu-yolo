# BD surgery v3: widen axi_smc NUM_MI to 2, rewire vdma lite clock to FCLK0 domain,
# connect vdma LITE -> smc M01, assign 0x43C00000.
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]

set smc [get_bd_cells axi_smc]
puts "BEFORE: NUM_SI=[get_property CONFIG.NUM_SI $smc] NUM_MI=[get_property CONFIG.NUM_MI $smc] NUM_CLOCKS=[get_property CONFIG.NUM_CLOCKS $smc]"

# widen master side (SmartConnect converts AXI3->AXI4LITE per branch)
set_property CONFIG.NUM_MI {2} $smc
catch { set_property CONFIG.S00_HAS_REGSLICE {1} $smc }
catch { set_property CONFIG.M00_HAS_REGSLICE {1} $smc }
catch { set_property CONFIG.M01_HAS_REGSLICE {1} $smc }

# rewire vdma s_axi_lite_aclk: clk_out1 -> FCLK_CLK0 (same domain as smc aclk)
set lp [get_bd_pins -quiet axi_vdma_0/s_axi_lite_aclk]
set ln [get_bd_nets -quiet -of_objects $lp]
if {[llength $ln]} {
    puts "vdma lite clk was on: [get_property NAME [lindex $ln 0]]"
    disconnect_bd_net [lindex $ln 0] $lp
}
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] $lp
puts "vdma lite clk -> FCLK_CLK0 (50M)"

# connect vdma LITE -> smc M01
set lite [get_bd_intf_pins -quiet axi_vdma_0/S_AXI_LITE]
if {[llength [get_bd_intf_nets -quiet -of_objects $lite]] == 0} {
    connect_bd_intf_net [get_bd_intf_pins axi_vdma_0/S_AXI_LITE] [get_bd_intf_pins axi_smc/M01_AXI]
    puts "vdma LITE -> smc M01 connected"
} else { puts "vdma LITE already connected" }

if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v" } else { puts "validate OK" }

set seg [get_bd_addr_segs -quiet axi_vdma_0/s_axi_lite/Reg]
puts "vdma seg: $seg"
if {[llength $seg]} {
    assign_bd_address -target_address_space /processing_system7_0/Data [get_bd_addr_segs $seg] -offset 0x43C00000 -range 64K
    puts "assigned 0x43C00000"
}
save_bd_design
puts "BD_VDMA_LITE3_DONE"
