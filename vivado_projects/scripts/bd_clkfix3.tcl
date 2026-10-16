# BD clock surgery v3: fix axi_smc_instr clock domain + restore reset_1
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]

puts "================ BEFORE DUMP ================"
foreach pin {axi_smc_instr/aclk axi_smc_instr/aclk1 axi_smc_instr/aresetn \
             proc_sys_reset_1/slowest_sync_clk proc_sys_reset_0/slowest_sync_clk} {
  puts "NET $pin <- [get_bd_nets -quiet -of_objects [get_bd_pins $pin]]"
}
foreach ifc {axi_smc_instr/S00_AXI axi_smc_instr/M00_AXI dpu_eu_0/DPU0_M_AXI_INSTR \
             processing_system7_0/S_AXI_HP0 processing_system7_0/S_AXI_HP1 processing_system7_0/S_AXI_HP2} {
  if {[llength [get_bd_intf_pins -quiet $ifc]]} {
    puts "IFC $ifc FREQ_HZ=[get_property FREQ_HZ [get_bd_intf_pins $ifc]] CLK_DOMAIN=[get_property CLK_DOMAIN [get_bd_intf_pins $ifc]]"
  } else { puts "IFC $ifc absent" }
}

proc move_pin {pin tgt_pin tgt_name} {
  set p [get_bd_pins $pin]
  set cur [get_bd_nets -quiet -of_objects $p]
  if {![llength $cur]} { puts "NO NET on $pin"; return }
  set curn [get_property NAME [get_bd_nets $cur]]
  if {[string match "*$tgt_name*" $curn]} { puts "SKIP $pin already on $tgt_name"; return }
  puts "MOVE $pin : $curn -> $tgt_name"
  disconnect_bd_net $cur $p
  connect_bd_net [get_bd_pins $tgt_pin] $p
}

# 1) restore proc_sys_reset_1 to clk_out1 (serves ov5640 reset; s_axi reset crossing proven functional)
move_pin proc_sys_reset_1/slowest_sync_clk clk_wiz_0/clk_out1 clk_wiz_0_clk_out1
# 2) instruction smartconnect: both clocks to clk_out2 (DPU instr master + HP2 both on clk_out2 now)
move_pin axi_smc_instr/aclk  clk_wiz_0/clk_out2 clk_wiz_0_clk_out2
move_pin axi_smc_instr/aclk1 clk_wiz_0/clk_out2 clk_wiz_0_clk_out2
# 3) instruction smartconnect reset: move to proc_sys_reset_0 (clk_out2 domain) if it is on FCLK0-domain reset
set rn [get_bd_nets -quiet -of_objects [get_bd_pins axi_smc_instr/aresetn]]
if {[llength $rn]} {
  set rname [get_property NAME [get_bd_nets $rn]]
  puts "smc_instr aresetn net: $rname"
  if {[string match "*rst_ps7_0_50M*" $rname]} {
    move_pin axi_smc_instr/aresetn proc_sys_reset_0/peripheral_aresetn proc_sys_reset_0_peripheral_aresetn
  }
}

puts "================ AFTER DUMP ================"
foreach pin {axi_smc_instr/aclk axi_smc_instr/aclk1 proc_sys_reset_1/slowest_sync_clk} {
  puts "NET $pin <- [get_bd_nets -quiet -of_objects [get_bd_pins $pin]]"
}
foreach ifc {axi_smc_instr/S00_AXI axi_smc_instr/M00_AXI dpu_eu_0/DPU0_M_AXI_INSTR processing_system7_0/S_AXI_HP2} {
  puts "IFC $ifc FREQ_HZ=[get_property FREQ_HZ [get_bd_intf_pins $ifc]]"
}
foreach c {clk_out1 clk_out2 clk_out3} {
  set nn [get_bd_nets -quiet -of_objects [get_bd_pins clk_wiz_0/$c]]
  puts "clk_wiz $c net=$nn FREQ_HZ=[get_property FREQ_HZ [get_bd_pins clk_wiz_0/$c]]"
}

puts "================ VALIDATE ================"
if {[catch {validate_bd_design} vmsg]} { puts "VALIDATE_ERROR: $vmsg" } else { puts "validate OK" }
save_bd_design
puts "BD_CLKFIX3_DONE"
