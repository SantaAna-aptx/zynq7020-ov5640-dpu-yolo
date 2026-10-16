# fix_mref.tcl -- diagnose + repair the ov5640 module reference
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
puts "=== files matching ov5640_cam_top.v ==="
puts [get_files -quiet -of_objects [get_filesets sources_1] *ov5640_cam_top.v]
puts [get_files -quiet *ov5640_cam_top.v]

puts "=== update compile order ==="
catch {update_compile_order -fileset sources_1}

puts "=== is rtl dir still in ip repo paths? ==="
puts [get_property ip_repo_paths [current_project]]

puts "=== refresh repo ==="
catch {set_property ip_repo_paths {e:/dpu_ip_repo/zcu102-dpu-trd-2019-1-timer/pl/srcs/dpu_ip e:/yoloProject/rtl} [current_project]}
catch {update_ip_catalog -force}

puts "=== try reset OOC again ==="
catch {reset_run design_1_ov5640_0_0_synth_1} emsg
puts "reset msg: $emsg"
puts "OOC STATUS: [get_property STATUS [get_runs design_1_ov5640_0_0_synth_1]]"
