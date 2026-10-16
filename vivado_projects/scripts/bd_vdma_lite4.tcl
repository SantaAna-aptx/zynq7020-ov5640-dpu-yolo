# BD surgery v4: DELETE axi_smc (junk state from v1-v3 attempts) and recreate fresh:
# NUM_SI=1, NUM_MI=2, NUM_CLKS=1, no regslice. Rewire: GP0->S00, M00->dpu, M01->vdmaLITE.
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]

set smc [get_bd_cells axi_smc]
# drop connected nets first
set inets [get_bd_intf_nets -quiet -filter "PATH =~ *axi_smc*"]
foreach n $inets { puts "del intf net: [get_property NAME $n]" }
if {[llength $inets]} { delete_bd_objs $inets }
set cnets [get_bd_nets -quiet -of_objects [get_bd_pins -quiet -of_objects $smc]]
foreach n $cnets { puts "del net: [get_property NAME $n]" }
if {[llength $cnets]} { delete_bd_objs $cnets }
delete_bd_objs $smc
puts "axi_smc deleted"

# recreate fresh
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc
set smc [get_bd_cells axi_smc]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {2} CONFIG.NUM_CLKS {1}] $smc

# wiring
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins axi_smc/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins dpu_eu_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc/M01_AXI] [get_bd_intf_pins axi_vdma_0/S_AXI_LITE]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_smc/aclk]
connect_bd_net [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins axi_smc/aclk] -quiet

if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v" } else { puts "validate OK" }

# addresses: dpu 0x40000000 (may persist), vdma 0x43C00000
set dseg [get_bd_addr_segs -quiet dpu_eu_0/S_AXI/Reg]
if {[llength [get_bd_addr_segs -quiet -of_objects [get_bd_addr_space processing_system7_0/Data]]] == 0 || [llength [get_bd_addr_segs -quiet -of_objects [get_bd_addr_space processing_system7_0/Data] -filter "OFFSET == 1073741824"]] == 0} {
    if {[llength $dseg]} {
        assign_bd_address -target_address_space /processing_system7_0/Data [get_bd_addr_segs $dseg] -offset 0x40000000 -range 16M
        puts "dpu seg assigned 0x40000000"
    }
}
set seg [get_bd_addr_segs -quiet axi_vdma_0/s_axi_lite/Reg]
if {[llength $seg]} {
    assign_bd_address -target_address_space /processing_system7_0/Data [get_bd_addr_segs $seg] -offset 0x43C00000 -range 64K
    puts "vdma seg assigned 0x43C00000"
}
save_bd_design
puts "BD_VDMA_LITE4_DONE"
