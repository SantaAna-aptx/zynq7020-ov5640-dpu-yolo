# BD repair v5: reconnect the deleted DPU instruction bus (axi_smc_instr M00 -> dpu
# DPU0_M_AXI_INSTR) to clear the IP lock, then verify all axi_smc wiring and addresses.
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]

# 1) reconnect the DPU instruction fetch path
set im [get_bd_intf_pins -quiet dpu_eu_0/DPU0_M_AXI_INSTR]
set imnet [get_bd_intf_nets -quiet -of_objects $im]
puts "dpu instr intf net: [get_property NAME [lindex $imnet 0]]"
if {[llength $imnet] == 0} {
    connect_bd_intf_net [get_bd_intf_pins axi_smc_instr/M00_AXI] [get_bd_intf_pins dpu_eu_0/DPU0_M_AXI_INSTR]
    puts "instr bus reconnected"
}

# 2) verify axi_smc wiring
foreach c [list S00_AXI M00_AXI M01_AXI] {
    set p [get_bd_intf_pins -quiet axi_smc/$c]
    puts "smc $c: nets=[get_bd_intf_nets -quiet -of_objects $p]"
}
set ap [get_bd_pins -quiet axi_smc/aclk]
puts "smc aclk net: [get_bd_nets -quiet -of_objects $ap]"

# 3) validate (lock should clear once required connections restored)
if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v" } else { puts "validate OK" }

# 4) make sure both address segments are assigned
set dseg [get_bd_addr_segs -quiet dpu_eu_0/S_AXI/Reg]
set vseg [get_bd_addr_segs -quiet axi_vdma_0/s_axi_lite/Reg]
set assigned [get_bd_addr_segs -quiet -of_objects [get_bd_addr_space processing_system7_0/Data]]
puts "assigned segs in PS Data space:"
foreach s $assigned { puts "  [get_property NAME $s] @ [get_property OFFSET $s] ([get_property RANGE $s])" }
if {[llength $dseg]} {
    catch { assign_bd_address -target_address_space /processing_system7_0/Data [get_bd_addr_segs $dseg] -offset 0x40000000 -range 16M } ed
    puts "dpu assign: $ed"
}
if {[llength $vseg]} {
    catch { assign_bd_address -target_address_space /processing_system7_0/Data [get_bd_addr_segs $vseg] -offset 0x43C00000 -range 64K } ev
    puts "vdma assign: $ev"
}
save_bd_design
puts "BD_REPAIR_DONE"
