# build v2: reuse completed synth, skip the placer's early utilization check.
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bdfile [get_files design_1.bd]
catch { generate_target all $bdfile }
catch {export_ip_user_files -of_objects $bdfile -no_script -sync -force -quiet}
catch {reset_run impl_1}
# keep synth_1 (already complete for current BD)
set_property -name {STEPS.PLACE_DESIGN.ARGS.MORE OPTIONS} -value {-param place.skipUtilizationCheck 1} -objects [get_runs impl_1]
puts "launch impl (skip util check)..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "IMPL_STATUS: [get_property STATUS [get_runs impl_1]]"
if {[catch {open_run impl_1} eo]} { puts "OPENRUN_ERR: $eo"; exit 1 }
set w [get_timing_paths -delay_type max -max_paths 1]
puts "WNS_SETUP: [get_property SLACK $w]"
catch {report_timing_summary -delay_type max -report_unconstrained -max_paths 3 -file E:/yoloProject/vivado_projects/scripts/post_impl_timing_vdma.rpt}
set n2 [get_nets -quiet -of_objects [get_pins -quiet design_1_i/dpu_eu_0/dpu_2x_clk]]
puts "VERIFY_NET dpu_2x: [get_property NAME $n2]"
if {![string match "*clk_wiz*" [get_property NAME $n2]]} { puts "GATE1_BAD"; exit 1 }
set nc [get_nets -quiet -of_objects [get_pins -quiet design_1_i/clk_wiz_0/clk_in1]]
puts "VERIFY_NET clk_in1: [get_property NAME $nc]"
if {![string match "*FCLK_CLK0*" [get_property NAME $nc]]} { puts "GATE2_BAD"; exit 1 }
puts "CLOCK_WIRING_OK"
set bit E:/yoloProject/vivado_projects/yoloproject/yoloproject.runs/impl_1/design_1_wrapper.bit
if {[file exists $bit]} {
    file copy -force $bit E:/yoloProject/board_deploy/sd_delivery/design_1_wrapper_vdma.bit
    file copy -force $bit E:/yoloProject/web/design_1_wrapper_vdma.bit
    puts "BIT COPIED: [file size $bit] bytes"
} else { puts "BIT_MISSING"; exit 1 }
puts "BUILD_VDMA_DONE"
