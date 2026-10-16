set out [open {E:/yoloProject/vivado_projects/yoloproject/dump_props.log} w]
proc L {msg} { global out; puts $out $msg; flush $out }
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bd [lindex [get_files -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd
set ps7 [get_bd_cells /processing_system7_0]
foreach p [lsort [list_property $ps7]] {
  if {[string match -nocase "*ENET*" $p] || [string match -nocase "*MDIO*" $p]} {
    if {[catch {set v [get_property $p $ps7]} e]} { set v "<err>" }
    L "$p = $v"
  }
}
close_project
close $out
exit
