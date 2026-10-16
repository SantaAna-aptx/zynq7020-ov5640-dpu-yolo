# BD repair v10: create the missing cmos_data[7:0] external port and wire it.
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]
set dp [get_bd_ports -quiet cmos_data]
if {[llength $dp] == 0} {
    set dp [create_bd_port -dir I -from 7 -to 0 cmos_data]
    puts "created port cmos_data[7:0]"
} else { puts "port exists" }
set pin [get_bd_pins -quiet ov5640_0/cmos_data]
set nn [get_bd_nets -quiet -of_objects $pin]
if {[llength $nn] == 0} {
    connect_bd_net $pin $dp
    puts "cmos_data wired"
} else { puts "already netted: [get_property NAME [lindex $nn 0]]" }
# sanity: dump all top-level cmos ports with direction
foreach p [get_bd_ports -quiet -filter {NAME =~ cmos*}] {
    puts "port $p dir=[get_property DIRECTION $p] width=[expr {[get_property LEFT $p] - [get_property RIGHT $p] + 1}]"
}
if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v" } else { puts "validate OK" }
catch { generate_target all [get_files design_1.bd] } eg
puts "generate: $eg"
save_bd_design
puts "BD_REPAIR10_DONE"
