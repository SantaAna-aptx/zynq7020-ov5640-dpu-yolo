set out [open {E:/yoloProject/vivado_projects/yoloproject/fix_mdio2.log} w]
proc L {msg} { global out; puts $out $msg; puts $msg; flush $out }
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bd [lindex [get_files -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd
set ps7 [get_bd_cells /processing_system7_0]
if {[catch {set_property CONFIG.PCW_ENET0_GRP_MDIO_ENABLE 1 $ps7} e]} { L "ERR enable: $e" } else { L "SET GRP_MDIO_ENABLE=1" }
if {[catch {set_property CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} $ps7} e]} { L "ERR io: $e" } else { L "SET GRP_MDIO_IO=MIO52..53" }
L "MDIO_ENABLE=[get_property CONFIG.PCW_ENET0_GRP_MDIO_ENABLE $ps7] MDIO_IO=[get_property CONFIG.PCW_ENET0_GRP_MDIO_IO $ps7]"
if {[catch {validate_bd_design} e]} { L "VALIDATE FAIL: $e" } else { L "VALIDATE OK" }
if {[catch {generate_target all [get_files $bd]} e]} { L "gen ERR: $e" }
if {[catch {write_hwdef -force -file {E:/yoloProject/petalinux_projects/zturn_hw/design_1_wrapper_fixed.hdf}} e]} { L "write ERR: $e" } else { L "write OK" }
close_project
L "DONE"
close $out
exit
