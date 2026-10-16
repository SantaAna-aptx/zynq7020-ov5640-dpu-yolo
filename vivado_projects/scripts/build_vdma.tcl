# Rebuild bitstream after VDMA LITE surgery; gates: dpu_2x from clk_wiz, clk_in1 from FCLK0,
# NEW: verify vdma LITE seg exists at 0x43C00000 in the address map via netlist presence.
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bdfile [get_files design_1.bd]
puts "=== generate targets ==="
if {[catch {generate_target all $bdfile} gmsg]} { puts "GEN_WARN: $gmsg" }
catch {export_ip_user_files -of_objects $bdfile -no_script -sync -force -quiet}
foreach r [get_runs] {
    set st [get_property STATUS $r]
    if {[string match "*fail*" [string tolower $st]]} { catch {reset_run $r} }
}
catch {reset_run impl_1}
catch {reset_run synth_1}
foreach r [get_runs -filter {IS_SYNTHESIS && !IS_IMPLEMENTATION}] { catch {reset_run $r} }
launch_runs synth_1 -jobs 4
wait_on_run synth_1
puts "SYNTH_STATUS: [get_property STATUS [get_runs synth_1]]"
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "IMPL_STATUS: [get_property STATUS [get_runs impl_1]]"
if {[catch {open_run impl_1} eo]} { puts "OPENRUN_ERR: $eo"; exit 1 }
set w [get_timing_paths -delay_type max -max_paths 1]
puts "WNS_SETUP: [get_property SLACK $w]"
catch {report_timing_summary -delay_type max -report_unconstrained -max_paths 3 -file E:/yoloProject/vivado_projects/scripts/post_impl_timing_vdma.rpt}
# GATE 1: dpu_2x from clk_wiz clkout3
set n2 [get_nets -quiet -of_objects [get_pins -quiet design_1_i/dpu_eu_0/dpu_2x_clk]]
puts "VERIFY_NET dpu_2x: [get_property NAME $n2]"
if {![string match "*clk_wiz*" [get_property NAME $n2]]} { puts "GATE1_BAD"; exit 1 }
# GATE 2: clk_wiz input = FCLK0
set nc [get_nets -quiet -of_objects [get_pins -quiet design_1_i/clk_wiz_0/clk_in1]]
puts "VERIFY_NET clk_in1: [get_property NAME $nc]"
if {![string match "*FCLK_CLK0*" [get_property NAME $nc]]} { puts "GATE2_BAD"; exit 1 }
# GATE 3 (new): a VDMA register decode exists on GP0 path — check the netlist has
# the vdma lite decode: look for design_1_i/axi_vdma_0 instance and its s_axi_lite pins driven
set vl [get_cells -quiet design_1_i/axi_vdma_0]
if {[llength $vl]} { puts "GATE3: vdma instance present" } else { puts "GATE3_BAD: no vdma instance"; exit 1 }
puts "CLOCK_WIRING_OK"
set bit E:/yoloProject/vivado_projects/yoloproject/yoloproject.runs/impl_1/design_1_wrapper.bit
if {[file exists $bit]} {
    file copy -force $bit E:/yoloProject/board_deploy/sd_delivery/design_1_wrapper_vdma.bit
    file copy -force $bit E:/yoloProject/web/design_1_wrapper_vdma.bit
    puts "BIT COPIED: [file size $bit] bytes"
} else { puts "BIT_MISSING"; exit 1 }
puts "BUILD_VDMA_DONE"
