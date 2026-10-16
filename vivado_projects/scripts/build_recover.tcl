# build_recover.tcl -- recover from partial-reset state:
# 1. rebuild the ov5640 OOC run alone  2. wait for its dcp  3. top synth/impl/bit
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bdfile [get_files design_1.bd]
catch { generate_target all $bdfile }

puts "=== reset + launch ov5640 OOC ==="
catch {reset_run design_1_ov5640_0_0_synth_1}
launch_runs design_1_ov5640_0_0_synth_1
wait_on_run design_1_ov5640_0_0_synth_1
puts "OV5640_OOC: [get_property STATUS [get_runs design_1_ov5640_0_0_synth_1]]"

set ooc_dcp {E:/yoloProject/vivado_projects/yoloproject/yoloproject.srcs/sources_1/bd/design_1/ip/design_1_ov5640_0_0_1/design_1_ov5640_0_0.dcp}
if {![file exists $ooc_dcp]} {
    puts "OOC_DCP_MISSING - trying generate_target"
    catch { generate_target all [get_ips design_1_ov5640_0_0] }
}

puts "=== top synth/impl ==="
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
puts "BUILD_RECOVER_DONE"
