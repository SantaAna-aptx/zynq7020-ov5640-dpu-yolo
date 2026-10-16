# BD repair v7: recreate the FCLK_CLK0 net membership (v4 deleted the whole net).
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]
set src [get_bd_pins processing_system7_0/FCLK_CLK0]
foreach p {clk_wiz_0/clk_in1 rst_ps7_0_50M/slowest_sync_clk axi_vdma_0/s_axi_lite_aclk dpu_eu_0/s_axi_aclk} {
    set pp [get_bd_pins -quiet $p]
    set nn [get_bd_nets -quiet -of_objects $pp]
    if {[llength $nn] == 0} {
        connect_bd_net $src $pp
        puts "reconnected $p -> FCLK_CLK0"
    } else {
        puts "$p already on net: [get_property NAME [lindex $nn 0]]"
    }
}
# full membership dump of the rebuilt net
set net [get_bd_nets -quiet -of_objects $src]
puts "FCLK_CLK0 net: [get_property NAME [lindex $net 0]]"
foreach pp [get_bd_pins -quiet -of_objects [lindex $net 0]] { puts "  member: $pp" }
if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v" } else { puts "validate OK" }
catch { generate_target all [get_files design_1.bd] } eg
puts "generate: $eg"
save_bd_design
puts "BD_REPAIR7_DONE"
