set out [open {E:/yoloProject/vivado_projects/yoloproject/fix_baud.log} w]
proc L {msg} { global out; puts $out $msg; puts $msg; flush $out }
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bd [lindex [get_files -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd
set ps7 [get_bd_cells /processing_system7_0]
L "当前 BAUD_RATE=[get_property CONFIG.PCW_UART1_BAUD_RATE $ps7]"
if {[catch {set_property CONFIG.PCW_UART1_BAUD_RATE 115200 $ps7} e]} { L "ERR: $e" } else { L "SET UART1_BAUD=115200" }
if {[catch {set_property CONFIG.PCW_UART0_BAUD_RATE 115200 $ps7} e]} { L "ERR0: $e" }
L "确认: [get_property CONFIG.PCW_UART1_BAUD_RATE $ps7] stdout相关刷新开始"
if {[catch {validate_bd_design} e]} { L "VALIDATE FAIL: $e" } else { L "VALIDATE OK" }
if {[catch {generate_target all [get_files $bd]} e]} { L "gen ERR: $e" }
if {[catch {write_hwdef -force -file {E:/yoloProject/petalinux_projects/zturn_hw/design_1_wrapper_fixed.hdf}} e]} { L "write ERR: $e" } else { L "write OK" }
close_project
L "DONE"
close $out
exit
