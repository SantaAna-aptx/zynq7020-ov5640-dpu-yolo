# BD repair v9: reconnect axi_smc_instr M00 -> PS S_AXI_HP2 (instr fetch to DDR).
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]
set m [get_bd_intf_pins -quiet axi_smc_instr/M00_AXI]
set h [get_bd_intf_pins -quiet processing_system7_0/S_AXI_HP2]
set mn [get_bd_intf_nets -quiet -of_objects $m]
set hn [get_bd_intf_nets -quiet -of_objects $h]
if {[llength $mn]} { puts "smc_instr M00 net: [get_property NAME [lindex $mn 0]]" } else { puts "smc_instr M00 net: NONE" }
if {[llength $hn]} { puts "HP2 net: [get_property NAME [lindex $hn 0]]" } else { puts "HP2 net: NONE" }
if {[llength $mn] && [llength $hn]} {
    connect_bd_intf_net $m $h
    puts "M00 -> HP2 reconnected"
} else {
    connect_bd_intf_net $m $h
    puts "M00 -> HP2 connected"
}
if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v" } else { puts "validate OK" }
catch { generate_target all [get_files design_1.bd] } eg
puts "generate: $eg"
save_bd_design
puts "BD_REPAIR9_DONE"
