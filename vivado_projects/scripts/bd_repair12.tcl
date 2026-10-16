# BD repair v12: map HP3 DDR segment into VDMA Data_S2MM address space.
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]
set seg [get_bd_addr_segs -quiet processing_system7_0/S_AXI_HP3/HP3_DDR_LOWOCM]
puts "HP3 seg: $seg"
if {[llength $seg]} {
    if {[catch { assign_bd_address -target_address_space /axi_vdma_0/Data_S2MM [get_bd_addr_segs $seg] -offset 0x00000000 -range 512M } e]} {
        puts "assign err: $e"
        catch { assign_bd_address -target_address_space /axi_vdma_0/Data_S2MM [get_bd_addr_segs $seg] } e2
        puts "assign retry: $e2"
    }
    puts "mapped HP3 DDR into VDMA space"
}
if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v"; exit 1 } else { puts "validate OK" }
catch { generate_target all [get_files design_1.bd] } eg
puts "generate: $eg"
save_bd_design
# dump VDMA space mapping
foreach s [get_bd_addr_segs -quiet -of_objects [get_bd_addr_space /axi_vdma_0/Data_S2MM]] {
    puts "VDMA SPACE: [get_property NAME $s] @ [get_property OFFSET $s] range [get_property RANGE $s]"
}
puts "BD_REPAIR12_DONE"
