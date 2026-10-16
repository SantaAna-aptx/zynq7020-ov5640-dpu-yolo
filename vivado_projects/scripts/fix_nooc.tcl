# fix_nooc.tcl -- disable OOC for the ov5640 mref IP so it compiles inside synth_1
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set xcis [get_files -quiet *design_1_ov5640_0_0.xci]
puts "XCI files: $xcis"
foreach x $xcis {
    catch {set_property GENERATE_SYNTH_CHECKPOINT false [get_files $x]} em
    puts "set ooc-off: $em"
}
# also try the run-level property
catch {set_property OOC_RUN false [get_runs design_1_ov5640_0_0_synth_1]} em2
puts "ooc_run prop: $em2"

reset_run synth_1
reset_run impl_1
set_property -name {STEPS.PLACE_DESIGN.TCL.PRE} -value {E:/yoloProject/vivado_projects/scripts/pre_place.tcl} -objects [get_runs impl_1]
launch_runs synth_1 -jobs 4
wait_on_run synth_1
puts "SYNTH_STATUS: [get_property STATUS [get_runs synth_1]]"
if {[string match "*fail*" [string tolower [get_property STATUS [get_runs synth_1]]]]} { exit 1 }
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "IMPL_STATUS: [get_property STATUS [get_runs impl_1]]"
if {[string match "*fail*" [string tolower [get_property STATUS [get_runs impl_1]]]]} { exit 1 }
set bit E:/yoloProject/vivado_projects/yoloproject/yoloproject.runs/impl_1/design_1_wrapper.bit
if {[file exists $bit]} {
    file copy -force $bit E:/yoloProject/web/design_1_wrapper_vdma.bit
    puts "BIT COPIED: [file size $bit] bytes"
} else { puts "BIT_MISSING"; exit 1 }
puts "BUILD_NOOC_DONE"
