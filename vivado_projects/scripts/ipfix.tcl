# Diagnose and repair locked dpu_eu IP, then rebuild
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
puts "===== REPORT IP STATUS ====="
report_ip_status
set dip [get_ips -quiet design_1_dpu_eu_0_0]
if {[llength $dip]} {
    puts "IP_STATUS: [get_property IP_STATUS $dip]"
    puts "IPlocked? attempting upgrade_ip"
    if {[catch {upgrade_ip $dip} umsg]} { puts "UPGRADE_ERR: $umsg" } else { puts "UPGRADE_OK" }
} else {
    puts "IP design_1_dpu_eu_0_0 not in catalog"
}
puts "===== REGENERATE BD TARGETS ====="
set bdfile [get_files design_1.bd]
open_bd_design $bdfile
if {[catch {reset_target all [get_bd_cells dpu_eu_0] force} rmsg]} { puts "RESET_TARGET_WARN: $rmsg" }
if {[catch {generate_target all $bdfile} gmsg]} { puts "GEN_ERR: $gmsg" } else { puts "GEN_OK" }
catch {export_ip_user_files -of_objects $bdfile -no_script -sync -force -quiet}
puts "===== RUN STATUS ====="
foreach r [get_runs] { puts "RUN $r : [get_property STATUS $r] : [get_property NEEDS_REFRESH $r]" }
puts "IPFIX_DONE"
