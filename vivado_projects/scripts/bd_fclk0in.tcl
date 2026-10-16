# BD clock surgery v3: move clk_wiz input from FCLK_CLK1 to FCLK_CLK0
# Rationale: FCLK_CLK0 is the ONLY empirically-proven-alive PS->PL clock:
#   - FCLK0_CTRL (0xF8000170) reads 0x00400A00 (divisor 10) AFTER kernel late_init
#   - DPU s_axi_aclk + GP0_ACLK run on FCLK_CLK0 and signature check passes
#   - last night's DPU compute ran with m_axi on FCLK_CLK0
# FCLK_CLK1 is suspected gated by the kernel clkc driver -> clk_wiz input dead
#   -> DPU compute domain dead -> task timeout.
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]

set cw [get_bd_cells clk_wiz_0]
puts "PRIM=[get_property CONFIG.PRIM_IN_FREQ $cw] R2=[get_property CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $cw] R3=[get_property CONFIG.CLKOUT3_REQUESTED_OUT_FREQ $cw]"

set pin [get_bd_pins clk_wiz_0/clk_in1]
set cur [get_bd_nets -quiet -of_objects $pin]
if {[llength $cur] == 0} {
    puts "FATAL: clk_in1 has no net"
    exit 1
}
set curname [get_property NAME [lindex $cur 0]]
puts "clk_in1 current net: $curname"

if {[string match "*FCLK_CLK0*" $curname]} {
    puts "ALREADY_ON_FCLK0 - no move needed"
} else {
    puts "MOVE clk_in1 : $curname -> processing_system7_0_FCLK_CLK0"
    disconnect_bd_net [lindex $cur 0] $pin
    connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] $pin
}

puts "================ AFTER ================"
set nf0 [get_bd_nets -of_objects [get_bd_pins processing_system7_0/FCLK_CLK0]]
foreach p [get_bd_pins -of_objects $nf0] { puts "FCLK0 member: $p" }
set n1 [get_bd_nets -quiet -of_objects [get_bd_pins processing_system7_0/FCLK_CLK1]]
if {[llength $n1]} {
    foreach p [get_bd_pins -of_objects [lindex $n1 0]] { puts "FCLK1 member: $p" }
} else {
    puts "FCLK1 net: <none> (fully dangling - OK)"
}
puts "NET clk_wiz_0/clk_in1 <- [get_bd_nets -quiet -of_objects [get_bd_pins clk_wiz_0/clk_in1]]"
puts "NET dpu_eu_0/m_axi_dpu_aclk <- [get_bd_nets -quiet -of_objects [get_bd_pins dpu_eu_0/m_axi_dpu_aclk]]"
puts "NET dpu_eu_0/dpu_2x_clk <- [get_bd_nets -quiet -of_objects [get_bd_pins dpu_eu_0/dpu_2x_clk]]"
puts "NET dpu_eu_0/s_axi_aclk <- [get_bd_nets -quiet -of_objects [get_bd_pins dpu_eu_0/s_axi_aclk]]"

puts "================ VALIDATE ================"
if {[catch {validate_bd_design} vmsg]} { puts "VALIDATE_ERROR: $vmsg"; exit 1 }
puts "validate OK"
save_bd_design
puts "BD_FCLK0IN_DONE"
