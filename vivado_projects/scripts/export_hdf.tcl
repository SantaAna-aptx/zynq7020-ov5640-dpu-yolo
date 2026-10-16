set out [open {E:/yoloProject/vivado_projects/yoloproject/export_hdf.log} w]
proc L {msg} { global out; puts $out $msg; puts $msg; flush $out }
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bd [lindex [get_files -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd
L "刷新 BD 输出产物（含重新生成 ps7_init）..."
if {[catch {generate_target all [get_files $bd]} e]} { L "generate_target ERR: $e" } else { L "generate_target OK" }
L "write_hwdef -help 输出："
if {[catch {write_hwdef -help} e]} { L "help ERR: $e" }
L "尝试导出 hdf："
if {[catch {write_hwdef -force -file {E:/yoloProject/petalinux_projects/zturn_hw/design_1_wrapper_fixed.hdf}} e]} {
  L "write_hwdef(file) ERR: $e"
  if {[catch {write_hwdef -force -name design_1_wrapper_fixed -dir {E:/yoloProject/petalinux_projects/zturn_hw}} e2]} {
    L "write_hwdef(namedir) ERR: $e2"
  } else { L "write_hwdef namedir OK" }
} else { L "write_hwdef file OK" }
close_project
L "DONE"
close $out
exit
