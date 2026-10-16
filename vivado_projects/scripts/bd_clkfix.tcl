# BD clock surgery: fix dpu_2x_clk violation + reparam clk_wiz for timing-safe margins
set script_dir E:/yoloProject/vivado_projects/scripts
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bdfile [get_files design_1.bd]
puts "BD: $bdfile"
open_bd_design $bdfile

puts "================ BEFORE ================"
set p2x [get_bd_pins dpu_eu_0/dpu_2x_clk]
set n2x [get_bd_nets -of_objects $p2x -quiet]
puts "dpu_2x_clk net: $n2x"
foreach pin [get_bd_pins -quiet -of_objects [get_bd_nets -quiet $n2x]] { puts "  FCLK0-net member: $pin" }

set cw [get_bd_cells clk_wiz_0]
puts "clk_wiz PRIM_IN_FREQ = [get_property CONFIG.PRIM_IN_FREQ $cw]"
for {set i 1} {$i <= 3} {incr i} {
  puts "clk_wiz CLKOUT${i}_REQ = [get_property CONFIG.CLKOUT${i}_REQUESTED_OUT_FREQUENCY $cw]"
}
foreach c {clk_out1 clk_out2 clk_out3} {
  set nn [get_bd_nets -quiet -of_objects [get_bd_pins clk_wiz_0/$c]]
  puts "clk_wiz $c net=$nn"
  if {[llength $nn]} {
    foreach pin [get_bd_pins -quiet -of_objects [get_bd_nets $nn]] { puts "    consumer: $pin" }
  }
}

puts "================ SURGERY ================"
# 1) dpu_2x_clk: FCLK0 -> clk_out3 (the 2x domain, reset_2 already on clk_out3)
if {[string match "*FCLK_CLK0*" $n2x]} {
  disconnect_bd_net [get_bd_nets $n2x] $p2x
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out3] $p2x
  puts "dpu_2x_clk reconnected to clk_out3"
} else {
  puts "WARNING: dpu_2x_clk net was not FCLK0 (net=$n2x) - reconnecting anyway"
  disconnect_bd_net [get_bd_nets -quiet $n2x] $p2x
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out3] $p2x
}

# 2) clk_wiz reparam: PRIM=51 (real input 50.8 < 51 -> real outputs always under constraints)
#    out1=51  (reset dom for s_axi; nominal 51 -> real 50.8, matches FCLK0 exactly)
#    out2=120 (m_axi + HP0/1/2; nominal 119 -> real 118.5, huge margin under 150)
#    out3=240 (dpu_2x; nominal 238 = 2x119 EXACT -> real 237.1 = 2x118.5 EXACT)
set_property -dict [list \
  CONFIG.PRIM_IN_FREQ {51} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQUENCY {51} \
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQUENCY {120} \
  CONFIG.CLKOUT3_REQUESTED_OUT_FREQUENCY {240} ] $cw

puts "================ AFTER ================"
puts "clk_wiz PRIM_IN_FREQ = [get_property CONFIG.PRIM_IN_FREQ $cw]"
for {set i 1} {$i <= 3} {incr i} {
  puts "clk_wiz CLKOUT${i}_REQ = [get_property CONFIG.CLKOUT${i}_REQUESTED_OUT_FREQUENCY $cw]"
}
set n2xb [get_bd_nets -quiet -of_objects [get_bd_pins dpu_eu_0/dpu_2x_clk]]
puts "dpu_2x_clk now on net: $n2xb"

puts "================ VALIDATE ================"
if {[catch {validate_bd_design} vmsg]} {
  puts "VALIDATE_ERROR: $vmsg"
} else {
  puts "validate OK"
}
save_bd_design
puts "BD_CLKFIX_DONE"
