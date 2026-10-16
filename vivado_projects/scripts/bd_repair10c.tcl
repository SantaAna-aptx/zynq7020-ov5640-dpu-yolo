# BD repair v10c: create port + wire + validate + generate + save (no debug crash).
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]
set dp [get_bd_ports -quiet cmos_data]
if {[llength $dp] == 0} {
    set dp [create_bd_port -dir I -from 7 -to 0 cmos_data]
    puts "created port cmos_data[7:0]"
}
set pin [get_bd_pins -quiet ov5640_0/cmos_data]
set nn [get_bd_nets -quiet -of_objects $pin]
if {[llength $nn] == 0} {
    connect_bd_net $pin $dp
    puts "cmos_data wired"
} else { puts "already netted" }
if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v"; exit 1 } else { puts "validate OK" }
catch { generate_target all [get_files design_1.bd] } eg
puts "generate: $eg"
save_bd_design
# post-save verification
open_bd_design [get_files design_1.bd]
set dp2 [get_bd_ports -quiet cmos_data]
set pin2 [get_bd_pins -quiet ov5640_0/cmos_data]
puts "VERIFY port: $dp2  pin net: [get_bd_nets -quiet -of_objects $pin2]"
puts "BD_REPAIR10C_DONE"
