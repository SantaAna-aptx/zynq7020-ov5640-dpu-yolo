# diagnose_ip_lock.tcl -- find WHY the IPs are locked and clear it.
#
# State: every IP under design_1 reports "generated file not found ...dcp". Please regenerate",
# IS_LOCKED is 1 for ps7 / dpu_eu / dbg_gpio / rst_100 / rst_cam, and reset_target/generate_target
# on the BD are refused because "Block design contains locked IPs" - a chicken-and-egg.
#
# This prints report_ip_status, then tries the three standard remedies per-IP (reset_target,
# generate_target, upgrade_ip) reporting what each one says.

open_project E:/yoloProject/vivado_projects/unified/unified.xpr
open_bd_design [get_files design_1.bd]

puts "########## report_ip_status ##########"
catch {report_ip_status -return_string} rs
if {[info exists rs]} { puts $rs }

puts ""
puts "########## per-IP state ##########"
foreach ip [get_ips -quiet] {
    set name [file tail [get_property IP_FILE $ip]]
    set lk "?"
    if {[catch {set lk [get_property IS_LOCKED $ip]} e]} { set lk "<$e>" }
    puts [format "   %-34s IS_LOCKED=%s" $name $lk]
}

puts ""
puts "########## attempt 1: upgrade_ip (clears version locks) ##########"
foreach ip [get_ips -quiet] {
    if {[catch {upgrade_ip -quiet $ip} e]} {
        puts "   [file tail [get_property IP_FILE $ip]] : upgrade failed -> [string range $e 0 120]"
    } else {
        puts "   [file tail [get_property IP_FILE $ip]] : upgrade ok"
    }
}

puts ""
puts "########## attempt 2: per-IP reset_target + generate_target ##########"
foreach ip [get_ips -quiet] {
    set name [file tail [get_property IP_FILE $ip]]
    if {[catch {reset_target all $ip} e1]} {
        puts "   $name : reset_target -> [string range $e1 0 110]"
    } else {
        puts "   $name : reset_target ok"
    }
}
foreach ip [get_ips -quiet] {
    set name [file tail [get_property IP_FILE $ip]]
    if {[catch {generate_target all $ip} e2]} {
        puts "   $name : generate_target -> [string range $e2 0 110]"
    } else {
        puts "   $name : generate_target ok"
    }
}

puts ""
puts "########## lock state after ##########"
set n 0
foreach ip [get_ips -quiet] {
    set name [file tail [get_property IP_FILE $ip]]
    set lk "?"
    if {[catch {set lk [get_property IS_LOCKED $ip]} e]} { set lk "<$e>" }
    if {$lk eq "1"} { incr n }
    puts [format "   %-34s IS_LOCKED=%s" $name $lk]
}
puts "   total still locked: $n"

puts ""
puts "########## BD-level generate_target retry ##########"
if {[catch {generate_target all [get_files design_1.bd]} e3]} {
    puts "   BD generate_target -> [string range $e3 0 200]"
} else {
    puts "   BD generate_target OK"
}

puts ""
puts "########## DPU dcp products ##########"
foreach f [glob -nocomplain "E:/yoloProject/vivado_projects/unified/unified.srcs/sources_1/bd/design_1/ip/design_1_dpu_eu_0_0/*.dcp"] {
    puts "   [file tail $f]  [file size $f] bytes"
}
puts "DIAG_DONE"
