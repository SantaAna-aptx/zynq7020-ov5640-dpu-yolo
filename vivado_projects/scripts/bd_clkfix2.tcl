# BD clock surgery v2: complete DPU clock domain fix
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]
set cw [get_bd_cells clk_wiz_0]

puts "================ BEFORE DUMP ================"
set nf0 [get_bd_nets -of_objects [get_bd_pins processing_system7_0/FCLK_CLK0]]
foreach pin [get_bd_pins -of_objects $nf0] { puts "FCLK0 member: $pin" }
foreach pin {dpu_eu_0/m_axi_dpu_aclk dpu_eu_0/s_axi_aclk dpu_eu_0/dpu_2x_clk \
             processing_system7_0/S_AXI_HP0_ACLK processing_system7_0/S_AXI_HP1_ACLK \
             processing_system7_0/S_AXI_HP2_ACLK processing_system7_0/S_AXI_HP3_ACLK} {
  puts "NET $pin <- [get_bd_nets -quiet -of_objects [get_bd_pins $pin]]"
}
foreach r {proc_sys_reset_0 proc_sys_reset_1 proc_sys_reset_2 rst_300M rst_ps7_0_50M} {
  if {[llength [get_bd_cells -quiet $r]]} {
    puts "RST $r.slowest_sync_clk <- [get_bd_nets -quiet -of_objects [get_bd_pins $r/slowest_sync_clk]]"
  }
}
puts "clk_wiz PRIM=[get_property CONFIG.PRIM_IN_FREQ $cw] R1=[get_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $cw] R2=[get_property CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $cw] R3=[get_property CONFIG.CLKOUT3_REQUESTED_OUT_FREQ $cw]"

puts "================ FIX ================"
# revert PRIM to 50 (matches FCLK_CLK1 net FREQ_HZ), set safe freqs:
#  out1=100 (camera/HP3, unchanged)   real 101.7
#  out2=100 (DPU m_axi + HP0/1/2)     real 101.7, closed-at-100, DPU rated 150 on -2 -> huge margin
#  out3=200 (dpu_2x)                  real 203.3 = 2x101.7 EXACT, DPU rated 300 -> huge margin
set_property CONFIG.PRIM_IN_FREQ {50.000} $cw
set_property CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {100} $cw
set_property CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {200} $cw

# move pins from FCLK0 net to clk_out2 / clk_out3
proc move_pin {pin tgt_pin tgt_name} {
  set p [get_bd_pins $pin]
  set cur [get_bd_nets -quiet -of_objects $p]
  set curn [get_property NAME [get_bd_nets $cur]]
  if {[string match "*$tgt_name*" $curn]} { puts "SKIP $pin already on $tgt_name"; return }
  puts "MOVE $pin : $curn -> $tgt_name"
  disconnect_bd_net $cur $p
  connect_bd_net [get_bd_pins $tgt_pin] $p
}

move_pin dpu_eu_0/m_axi_dpu_aclk           clk_wiz_0/clk_out2 clk_wiz_0_clk_out2
move_pin processing_system7_0/S_AXI_HP0_ACLK clk_wiz_0/clk_out2 clk_wiz_0_clk_out2
move_pin processing_system7_0/S_AXI_HP1_ACLK clk_wiz_0/clk_out2 clk_wiz_0_clk_out2
move_pin processing_system7_0/S_AXI_HP2_ACLK clk_wiz_0/clk_out2 clk_wiz_0_clk_out2
move_pin dpu_eu_0/dpu_2x_clk               clk_wiz_0/clk_out3 clk_wiz_0_clk_out3

if {[llength [get_bd_cells -quiet proc_sys_reset_0]]} {
  move_pin proc_sys_reset_0/slowest_sync_clk clk_wiz_0/clk_out2 clk_wiz_0_clk_out2
}
if {[llength [get_bd_cells -quiet rst_300M]]} {
  move_pin rst_300M/slowest_sync_clk clk_wiz_0/clk_out3 clk_wiz_0_clk_out3
}
if {[llength [get_bd_cells -quiet proc_sys_reset_1]]} {
  move_pin proc_sys_reset_1/slowest_sync_clk processing_system7_0/FCLK_CLK0 processing_system7_0_FCLK_CLK0
}

puts "================ AFTER DUMP ================"
set nf0b [get_bd_nets -of_objects [get_bd_pins processing_system7_0/FCLK_CLK0]]
foreach pin [get_bd_pins -of_objects $nf0b] { puts "FCLK0 member: $pin" }
foreach pin {dpu_eu_0/m_axi_dpu_aclk dpu_eu_0/dpu_2x_clk processing_system7_0/S_AXI_HP0_ACLK} {
  puts "NET $pin <- [get_bd_nets -quiet -of_objects [get_bd_pins $pin]]"
}
foreach c {clk_out1 clk_out2 clk_out3} {
  set nn [get_bd_nets -quiet -of_objects [get_bd_pins clk_wiz_0/$c]]
  puts "clk_wiz $c net=$nn FREQ_HZ=[get_property FREQ_HZ [get_bd_pins clk_wiz_0/$c]]"
}

puts "================ VALIDATE ================"
if {[catch {validate_bd_design} vmsg]} { puts "VALIDATE_ERROR: $vmsg" } else { puts "validate OK" }
save_bd_design
puts "BD_CLKFIX2_DONE"
