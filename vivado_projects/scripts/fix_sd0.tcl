set out [open {E:/yoloProject/vivado_projects/yoloproject/fix_sd0.log} w]
proc L {msg} { global out; puts $out $msg; puts $msg; flush $out }
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bd [lindex [get_files -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd
set ps7 [get_bd_cells /processing_system7_0]

L "当前状态: SD0_EN=[get_property CONFIG.PCW_SD0_PERIPHERAL_ENABLE $ps7] SD0_IO=[get_property CONFIG.PCW_SD0_SD0_IO $ps7]"
if {[catch {set v [get_property CONFIG.PCW_SD0_SD0_CD $ps7]} e]} { L "PCW_SD0_SD0_CD 不存在: $e" } else { L "PCW_SD0_SD0_CD = $v（历史误设，清掉）"; catch {set_property CONFIG.PCW_SD0_SD0_CD {} $ps7} }

# 正确的卡检测配置：GRP_CD 使能 + MIO47
if {[catch {set_property CONFIG.PCW_SD0_GRP_CD_ENABLE 1 $ps7} e]} { L "GRP_CD_ENABLE ERR: $e" } else { L "SET PCW_SD0_GRP_CD_ENABLE = 1" }
if {[catch {set_property CONFIG.PCW_SD0_GRP_CD_IO {MIO 47} $ps7} e]} { L "GRP_CD_IO ERR: $e" } else { L "SET PCW_SD0_GRP_CD_IO = MIO 47" }

if {[catch {validate_bd_design} e]} { L "VALIDATE FAIL: $e" } else { L "VALIDATE OK" }
if {[catch {generate_target all [get_files $bd]} e]} { L "generate_target ERR: $e" } else { L "generate_target OK" }
if {[catch {write_hwdef -force -file {E:/yoloProject/petalinux_projects/zturn_hw/design_1_wrapper_fixed.hdf}} e]} {
  L "write_hwdef ERR: $e"
} else { L "write_hwdef OK" }
close_project
L "DONE"
close $out
exit
