# ipstatus.tcl -- report_ip_status in yolo2 + try upgrade/unlock paths
open_project {E:/yoloProject/vivado_projects/yolo2/yolo2.xpr}
open_bd_design [get_files design_1.bd]
puts "=== report_ip_status ==="
catch {report_ip_status} st
puts $st
puts "=== try upgrade_ip ==="
catch {upgrade_ip [get_ips *dpu_eu*]} u1
puts "upgrade: $u1"
puts "=== locked cells? ==="
foreach c [get_bd_cells] {
    if {[catch {get_property IS_LOCKED $c} lv]} { set lv "n/a" }
    if {$lv != "n/a" && $lv != 0} { puts "LOCKED CELL: $c = $lv" }
}
puts "=== ips locked? ==="
foreach i [get_ips] {
    if {[string match -nocase *dpu* $i]} {
        puts "IP: $i  LOCKED=[get_property IS_LOCKED $i]"
    }
}
