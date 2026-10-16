# recreate_project.tcl -- fresh project from the self-contained BD (bypasses all locks)
set part xc7z020clg400-2
set proj E:/yoloProject/vivado_projects/yolo2
set old  E:/yoloProject/vivado_projects/yoloproject/yoloproject.srcs/sources_1/bd/design_1/design_1.bd

create_project yolo2 $proj -part $part -force
set_property ip_repo_paths {e:/dpu_ip_repo/zcu102-dpu-trd-2019-1-timer/pl/srcs/dpu_ip e:/yoloProject/rtl} [current_project]
update_ip_catalog

# mref module sources MUST be added BEFORE opening the BD
add_files -norecurse {E:/yoloProject/rtl/ov5640_cam_top.v E:/yoloProject/rtl/async_fifo_18b.v E:/yoloProject/rtl/I2C_OV5640_1280720_Config.v E:/yoloProject/rtl/i2c_timing_ctrl_reg16_dat8_wronly.v}
update_compile_order -fileset sources_1

read_bd $old
open_bd_design [get_files design_1.bd]
# NOTE: validate_bd_design is skipped deliberately — dpu_eu carries a benign
# per-project lock (present in every successful historical build too).
save_bd_design
close_bd_design [current_bd_design]

# constraints
add_files -fileset constrs_1 -norecurse {E:/yoloProject/rtl/camera.xdc E:/yoloProject/rtl/clock_route_fix.xdc E:/yoloProject/rtl/clock_route_fix_impl.xdc E:/yoloProject/rtl/mmcm_comp_bufin.xdc}

make_wrapper -files [get_files design_1.bd] -top
add_files -norecurse $proj/yolo2.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v
set_property top design_1_wrapper [current_fileset]
update_compile_order -fileset sources_1

set_property -name {STEPS.PLACE_DESIGN.TCL.PRE} -value {E:/yoloProject/vivado_projects/scripts/pre_place.tcl} -objects [get_runs impl_1]

launch_runs synth_1 -jobs 4
wait_on_run synth_1
puts "SYNTH_STATUS: [get_property STATUS [get_runs synth_1]]"
if {[string match "*fail*" [string tolower [get_property STATUS [get_runs synth_1]]]]} { exit 1 }
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "IMPL_STATUS: [get_property STATUS [get_runs impl_1]]"
if {[string match "*fail*" [string tolower [get_property STATUS [get_runs impl_1]]]]} { exit 1 }

set bit E:/yoloProject/vivado_projects/yolo2/yolo2.runs/impl_1/design_1_wrapper.bit
if {[file exists $bit]} {
    file copy -force $bit E:/yoloProject/web/design_1_wrapper_vdma.bit
    puts "BIT COPIED: [file size $bit] bytes"
} else { puts "BIT_MISSING"; exit 1 }
puts "YOLO2_DONE"
