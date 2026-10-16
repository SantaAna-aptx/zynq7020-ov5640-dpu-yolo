# fix_ps_config.tcl v2 — Phase 1: 最小启动集修复（UART1 + SD0 + DDR + bank1 电压）
set out [open {E:/yoloProject/vivado_projects/yoloproject/ps_fix.log} w]
proc L {msg} { global out; puts $out $msg; puts $msg; flush $out }

open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bds [get_files -filter {FILE_TYPE == "Block Designs"}]
open_bd_design [lindex $bds 0]
set ps7 [get_bd_cells /processing_system7_0]
L "PS7: $ps7  当前使能: UART1=[get_property CONFIG.PCW_UART1_PERIPHERAL_ENABLE $ps7] SD0=[get_property CONFIG.PCW_SD0_PERIPHERAL_ENABLE $ps7]"

# 撤掉上次实验性开启的 ENET0/USB0（等确认原理图后再开，本次只修启动三要素）
foreach {k v} [list PCW_ENET0_PERIPHERAL_ENABLE 0 PCW_USB0_PERIPHERAL_ENABLE 0] {
  catch {set_property CONFIG.$k $v $ps7}
}

# dump 所有 SD0 相关参数名（找 CD/WP 的真实名字）
foreach p [list_property $ps7] {
  if {[string match -nocase "*sd0*" $p] || [string match -nocase "*SD0*" $p]} {
    catch { L "SD0PROP $p = [get_property $p $ps7]" }
  }
}

# 核心配置（单条 catch）
set err 0
foreach {k v} [list \
  PCW_UART1_PERIPHERAL_ENABLE   {1} \
  PCW_UART1_UART1_IO            {MIO 48 .. 49} \
  PCW_UART0_PERIPHERAL_ENABLE   {0} \
  PCW_SD0_PERIPHERAL_ENABLE     {1} \
  PCW_SD0_SD0_IO                {MIO 40 .. 45} \
  PCW_SD0_SD0_CD                {MIO 47} \
  PCW_UIPARAM_DDR_PARTNO        {MT41K256M16 RE-125} \
  PCW_UIPARAM_DDR_MEMORY_TYPE   {DDR 3} \
  PCW_UIPARAM_DDR_BUS_WIDTH     {32 Bit} \
  PCW_PRESET_BANK1_VOLTAGE      {LVCMOS 1.8V} \
] {
  if {[catch {set_property CONFIG.$k $v $ps7} e]} {
    L "ERR  $k = $v  --> [string range $e 0 150]"
    incr err
  } else {
    L "SET  $k = $v"
  }
}
L "设置错误数: $err"

if {[catch {validate_bd_design} e]} { L "VALIDATE FAIL: $e" } else { L "VALIDATE OK" }

# 导出新 hdf（含 ps7_init；PL bit 复用现有的，不重综合）
if {[catch {
  write_sysdef -file {E:/yoloProject/petalinux_projects/zturn_hw/design_1_wrapper_fixed.hdf} -force
} e]} {
  L "write_sysdef ERR: $e"
} else {
  L "write_sysdef OK -> design_1_wrapper_fixed.hdf"
}

save_bd_design
close_project
L "DONE"
close $out
