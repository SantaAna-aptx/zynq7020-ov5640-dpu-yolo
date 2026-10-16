set out [open {E:/yoloProject/vivado_projects/yoloproject/fix_enetrst.log} w]
proc L {msg} { global out; puts $out $msg; puts $msg; flush $out }
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bd [lindex [get_files -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd
set ps7 [get_bd_cells /processing_system7_0]
if {[catch {set_property CONFIG.PCW_ENET_RESET_ENABLE 1 $ps7} e]} { L "ERR1: $e" } else { L "SET ENET_RESET_ENABLE=1" }
if {[catch {set_property CONFIG.PCW_ENET_RESET_SELECT {Share reset pin} $ps7} e]} { L "ERR2: $e" } else { L "SET ENET_RESET_SELECT=Share reset pin" }
if {[catch {set_property CONFIG.PCW_ENET0_RESET_ENABLE 1 $ps7} e]} { L "ERR3: $e" } else { L "SET ENET0_RESET_ENABLE=1" }
if {[catch {set_property CONFIG.PCW_ENET0_RESET_IO {MIO 51} $ps7} e]} { L "ERR4: $e" } else { L "SET ENET0_RESET_IO=MIO51" }
L "校验: RESET_EN=[get_property CONFIG.PCW_ENET0_RESET_ENABLE $ps7] RESET_IO=[get_property CONFIG.PCW_ENET0_RESET_IO $ps7] SPEEDBIN=[get_property CONFIG.PCW_UIPARAM_DDR_SPEED_BIN $ps7] QSPI=[get_property CONFIG.PCW_QSPI_PERIPHERAL_ENABLE $ps7] SD1=[get_property CONFIG.PCW_SD1_PERIPHERAL_ENABLE $ps7]"
if {[catch {validate_bd_design} e]} { L "VALIDATE FAIL: $e" } else { L "VALIDATE OK" }
if {[catch {generate_target all [get_files $bd]} e]} { L "gen ERR: $e" }
if {[catch {write_hwdef -force -file {E:/yoloProject/petalinux_projects/zturn_hw/design_1_wrapper_fixed.hdf}} e]} { L "write ERR: $e" } else { L "write OK" }
close_project
L "DONE"
close $out
exit
