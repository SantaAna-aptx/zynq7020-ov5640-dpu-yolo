# BD unlock v6: regenerate the locked dpu_eu IP output products, validate, save.
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]
report_ip_status
set locked [get_ips -quiet -filter {IS_LOCKED == 1}]
puts "locked ips: $locked"
foreach ip $locked {
    puts "unlocking $ip via upgrade_ip"
    catch { upgrade_ip $ip } eu
    puts "upgrade result: $eu"
}
# also force regenerate target products
catch { generate_target all [get_files design_1.bd] } eg
puts "generate: $eg"
if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v" } else { puts "validate OK" }
report_ip_status
save_bd_design
puts "BD_UNLOCK_DONE"
