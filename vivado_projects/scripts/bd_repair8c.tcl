# BD repair v8c: always connect the two interface PINS (Vivado merges nets).
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]
set m [get_bd_intf_pins -quiet axi_smc_instr/M00_AXI]
set d [get_bd_intf_pins -quiet dpu_eu_0/DPU0_M_AXI_INSTR]
set mn [get_bd_intf_nets -quiet -of_objects $m]
set dn [get_bd_intf_nets -quiet -of_objects $d]
if {[llength $mn] && [llength $dn]} {
    puts "both sides already netted - merging via pins"
    connect_bd_intf_net $m $d
} else {
    connect_bd_intf_net $m $d
    puts "instr bus reconnected"
}
if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v" } else { puts "validate OK" }
catch { generate_target all [get_files design_1.bd] } eg
puts "generate: $eg"
save_bd_design
puts "BD_REPAIR8_DONE"
