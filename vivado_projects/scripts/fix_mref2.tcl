# fix_mref2.tcl -- repo cleaned; refresh catalog, reset OOC, verify launch works
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
catch {set_property ip_repo_paths {e:/dpu_ip_repo/zcu102-dpu-trd-2019-1-timer/pl/srcs/dpu_ip e:/yoloProject/rtl} [current_project]}
catch {update_ip_catalog -force}
puts "repo refreshed"

catch {reset_run design_1_ov5640_0_0_synth_1} emsg
puts "reset msg: $emsg"
puts "OOC STATUS: [get_property STATUS [get_runs design_1_ov5640_0_0_synth_1]]"

puts "=== launch OOC alone ==="
catch {launch_runs design_1_ov5640_0_0_synth_1} lmsg
puts "launch msg: $lmsg"
