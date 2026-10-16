# BD repair v8: reconnect axi_smc_instr M00 -> dpu DPU0_M_AXI_INSTR, validate, generate.
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]
set m [get_bd_intf_pins -quiet axi_smc_instr/M00_AXI]
set d [get_bd_intf_pins -quiet dpu_eu_0/DPU0_M_AXI_INSTR]
set mn [get_bd_intf_nets -quiet -of_objects $m]
set dn [get_bd_intf_nets -quiet -of_objects $d]
puts "smc_instr M00 net: [get_property NAME [lindex $mn 0]]"
puts "dpu instr net: [get_property NAME [lindex $dn 0]]"
if {[llength $mn] == 0 && [llength $dn] == 0} {
    connect_bd_intf_net $m $d
    puts "instr bus reconnected"
} elseif {[llength $mn] == 0} {
    connect_bd_intf_net $m [lindex $dn 0]
    puts "smc side merged into existing net"
} elseif {[llength $dn] == 0} {
    connect_bd_intf_net [lindex $mn 0] $d
    puts "dpu side merged into existing net"
} else { puts "both sides already netted?!" }
if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v" } else { puts "validate OK" }
catch { generate_target all [get_files design_1.bd] } eg
puts "generate: $eg"
save_bd_design
puts "BD_REPAIR8_DONE"
