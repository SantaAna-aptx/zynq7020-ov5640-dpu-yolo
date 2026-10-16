# Repair locked subcore in dpu_eu, regenerate, show run states
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set dip [get_ips -quiet design_1_dpu_eu_0_0]
if {[llength $dip]} {
    puts "===== UPGRADE IP ====="
    if {[catch {upgrade_ip $dip} umsg]} { puts "UPGRADE_ERR: $umsg" } else { puts "UPGRADE_OK" }
} else {
    puts "IP not found in catalog"
}
set bdfile [get_files design_1.bd]
open_bd_design $bdfile
puts "===== GENERATE ====="
if {[catch {generate_target all $bdfile} gmsg]} { puts "GEN_ERR: $gmsg" } else { puts "GEN_OK" }
catch {export_ip_user_files -of_objects $bdfile -no_script -sync -force -quiet}
puts "===== RUN STATUS ====="
foreach r [get_runs] { puts "RUN $r : [get_property STATUS $r]" }
puts "IPFIX2_DONE"
