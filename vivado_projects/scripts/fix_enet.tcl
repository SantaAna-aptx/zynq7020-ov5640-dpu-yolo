# fix_enet.tcl — 最终 PS 配置：按 MZQ7X 手册恢复 ENET0（bank1 已是 1.8V），其余保持
set out [open {E:/yoloProject/vivado_projects/yoloproject/fix_enet.log} w]
proc L {msg} { global out; puts $out $msg; puts $msg; flush $out }
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bd [lindex [get_files -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd
set ps7 [get_bd_cells /processing_system7_0]

L "修复前: UART1=[get_property CONFIG.PCW_UART1_PERIPHERAL_ENABLE $ps7] SD0=[get_property CONFIG.PCW_SD0_PERIPHERAL_ENABLE $ps7] ENET0=[get_property CONFIG.PCW_ENET0_PERIPHERAL_ENABLE $ps7] BANK1=[get_property CONFIG.PCW_PRESET_BANK1_VOLTAGE $ps7] DDR=[get_property CONFIG.PCW_UIPARAM_DDR_PARTNO $ps7]"

set err 0
foreach {k v} [list \
  PCW_ENET0_PERIPHERAL_ENABLE   {1} \
  PCW_ENET0_ENET0_IO            {MIO 16 .. 27} \
  PCW_ENET0_GRP_MDIO_IO         {MIO 52 .. 53} \
  PCW_ENET0_ENET0_PHY_TYPE      {RGMII} \
] {
  if {[catch {set_property CONFIG.$k $v $ps7} e]} {
    L "ERR  $k --> [string range $e 0 120]"
    incr err
  } else { L "SET  $k = $v" }
}

# 确认启动三要素没被破坏
foreach {k exp} {PCW_UART1_PERIPHERAL_ENABLE 1 PCW_SD0_PERIPHERAL_ENABLE 1 PCW_UIPARAM_DDR_PARTNO {MT41K256M16 RE-125} PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V}} {
  set cur [get_property CONFIG.$k $ps7]
  if {$cur ne $exp} { L "REGRESS $k = $cur (期望 $exp)"; incr err } else { L "KEEP $k = $cur" }
}

if {[catch {validate_bd_design} e]} { L "VALIDATE FAIL: $e" } else { L "VALIDATE OK" }
if {[catch {generate_target all [get_files $bd]} e]} { L "generate_target ERR: $e" }
# 强制 PS7 输出产物重生成（防陈旧）
if {[catch {reset_target all [get_bd_cells /processing_system7_0]} e]} {
  L "reset_target ERR: $e"
} else { L "reset_target ps7 OK" }
if {[catch {generate_target all [get_bd_cells /processing_system7_0]} e]} {
  L "gen ps7 ERR: $e"
} else { L "gen ps7 OK" }
if {[catch {write_hwdef -force -file {E:/yoloProject/petalinux_projects/zturn_hw/design_1_wrapper_fixed.hdf}} e]} {
  L "write_hwdef ERR: $e"
} else { L "write_hwdef OK" }
save_bd_design
close_project
L "DONE err=$err"
close $out
exit
