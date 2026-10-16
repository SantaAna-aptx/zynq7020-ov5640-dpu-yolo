set out [open {E:/yoloProject/vivado_projects/yoloproject/bd_probe.log} w]
proc L {msg} { global out; puts $out $msg; flush $out }
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bd [lindex [get_files -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd
L "== DPU 接口 =="
foreach i [get_bd_intf_pins dpu_eu_0/*] {
  L "INTF $i : [get_property VLNV $i] / connected=[get_property ENABLED $i]"
}
L "== DPU 引脚(时钟类) =="
foreach p [get_bd_pins dpu_eu_0/*] {
  if {[string match "*clk*" [string tolower $p]] || [string match "*reset*" [string tolower $p]]} {
    L "PIN $p dir=[get_property DIR $p] net=[get_nets -of_objects $p -quiet]"
  }
}
L "== clk_wiz_0 引脚 =="
foreach p [get_bd_pins clk_wiz_0/*] {
  L "PIN $p dir=[get_property DIR $p] net=[get_nets -of_objects $p -quiet]"
}
L "== clk_wiz_0 配置 =="
foreach p {PRIM_IN_FREQ CLKOUT1_REQUESTED_OUT_FREQ CLKOUT2_REQUESTED_OUT_FREQ CLKOUT3_REQUESTED_OUT_FREQ} {
  catch { L "CFG $p = [get_property CONFIG.$p [get_bd_cells clk_wiz_0]]" }
}
L "== FCLK0 状态 =="
set ps7 [get_bd_cells /processing_system7_0]
foreach p {PCW_FPGA0_PERIPHERAL_FREQMHZ PCW_FPGA_FCLK0_ENABLE PCW_EN_CLK0_PORT PCW_USE_S_AXI_HP0} {
  catch { L "PS $p = [get_property CONFIG.$p $ps7]" }
}
L "== 复位单元 =="
foreach c [get_bd_cells -hierarchical -filter {VLNV =~ "*proc_sys_reset*"}] {
  L "RST $c : ext=[get_nets -of_objects [get_bd_pins $c/ext_reset_in] -quiet] slowest=[get_nets -of_objects [get_bd_pins $c/slowest_sync_clk] -quiet]"
}
close_project
close $out
exit
