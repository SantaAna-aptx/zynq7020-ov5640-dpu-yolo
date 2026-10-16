# BD repair v10b: validate + generate + save (port already created/wired).
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]
puts "port exists: [get_bd_ports -quiet cmos_data]"
set pin [get_bd_pins -quiet ov5640_0/cmos_data]
puts "pin net: [get_bd_nets -quiet -of_objects $pin]"
if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v"; exit 1 } else { puts "validate OK" }
catch { generate_target all [get_files design_1.bd] } eg
puts "generate: $eg"
save_bd_design
puts "BD_REPAIR10B_DONE"
