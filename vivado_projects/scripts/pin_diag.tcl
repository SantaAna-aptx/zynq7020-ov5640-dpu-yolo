set out [open {E:/yoloProject/vivado_projects/yoloproject/pin_diag.log} w]
proc L {msg} { global out; puts $out $msg; flush $out }
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bd [lindex [get_files -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd

set src [get_bd_pins -quiet clk_wiz_0/clk_out2]
L "src handle: $src"
if {$src ne ""} {
  L "src DIR: [get_property DIR $src]"
  L "src NAME: [get_property NAME $src]"
  L "src FULLNAME: [get_property FULL_NAME $src]"
}
set dst [get_bd_pins -quiet ps7/S_AXI_HP0_ACLK]
L "dst handle: $dst"
if {$dst ne ""} {
  L "dst DIR: [get_property DIR $dst]"
}
L "尝试 connect_bd_net 双引脚形式..."
if {[catch { connect_bd_net $src $dst } e]} {
  L "FAIL-A: $e"
  L "尝试 -net 命名形式..."
  if {[catch { connect_bd_net -net hp0_aclk_test $src $dst } e2]} {
    L "FAIL-B: $e2"
    L "尝试 connect_bd_net 仅目标引脚（自动建网）..."
    if {[catch { connect_bd_net $dst } e3]} {
      L "FAIL-C: $e3"
    } else {
      L "OK-C（网已建，再连源）"
      if {[catch { connect_bd_net [get_bd_nets -filter {NAME =~ *hp0_aclk*}] $src } e4]} { L "FAIL-D: $e4" } else { L "OK-D" }
    }
  } else { L "OK-B" }
} else { L "OK-A" }
close_project
close $out
exit
