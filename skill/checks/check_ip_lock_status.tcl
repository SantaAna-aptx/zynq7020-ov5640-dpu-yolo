# check_ip_lock_status.tcl -- build gate: is any IP in this Block Design locked?
#
# WHY THIS EXISTS
#   An IP that is locked does NOT get its synthesis checkpoint updated. Vivado
#   emits only WARNINGs and then builds successfully against the STALE netlist:
#
#     WARNING: [Vivado 12-4801] ... the IP is locked.
#     WARNING: [Project 1-577]  ... the out-of-date checkpoint will be used and
#                               it may result in incorrect behavior.
#
#   The result is a bitstream that does not contain your parameter change. You
#   find out only by reading the configuration back on the board, after a full
#   build. This script turns that silent warning into a hard failure.
#
# USAGE
#   vivado -mode batch -source check_ip_lock_status.tcl -tclargs <project.xpr> [bd_file]
#
#   <project.xpr>  path to the .xpr
#   [bd_file]      Block Design file name, default design_1.bd
#
# EXIT CODES
#   0 = no IP locked (safe to build)
#   1 = at least one IP locked (do NOT trust the resulting bitstream)
#
# AFTER THE FIX, RE-CHECK YOUR PARAMETERS.
#   upgrade_ip can RESET IP configuration. Always re-read the parameters you
#   care about after upgrading and refuse to build if they changed.

set proj  [lindex $argv 0]
set bdfile [expr {[llength $argv] > 1 ? [lindex $argv 1] : "design_1.bd"}]

if {$proj eq ""} {
    puts "usage: check_ip_lock_status.tcl <project.xpr> \[bd_file\]"
    exit 2
}

open_project $proj

set bds [get_files -quiet $bdfile]
if {[llength $bds] == 0} {
    puts "NOTE: $bdfile not found in this project; scanning get_ips directly."
} else {
    open_bd_design [lindex $bds 0]
}

puts ""
puts "########## report_ip_status ##########"
if {[catch {report_ip_status -return_string} rs]} {
    puts "   report_ip_status failed: $rs"
} else {
    puts $rs
}

puts ""
puts "########## per-IP lock state ##########"
set locked  0
set total   0
set locked_names {}
foreach ip [get_ips -quiet] {
    incr total
    set name [file tail [get_property IP_FILE $ip]]
    set lk "?"
    if {[catch {set lk [get_property IS_LOCKED $ip]} e]} { set lk "<$e>" }
    if {$lk eq "1"} {
        incr locked
        lappend locked_names $name
    }
    puts [format "   %-40s IS_LOCKED=%s" $name $lk]
}

puts ""
puts [format "   IPs=%d  locked=%d" $total $locked]

if {$locked > 0} {
    puts ""
    puts "########## how to clear it ##########"
    puts "   upgrade_ip clears version/subcore locks; reset_target+generate_target"
    puts "   fix stale products. Note that generate_target on the BD is REFUSED"
    puts "   while any IP is locked, so upgrade_ip has to come first."
    puts ""
    puts "   locked: $locked_names"
    puts ""
    puts "AFTER upgrading, re-read every parameter you depend on and fail the"
    puts "build if it changed - upgrade_ip can silently reset configuration."
    puts ""
    puts "RESULT: LOCKED ips - do not trust a bitstream built now"
    exit 1
}

puts ""
puts "RESULT: OK - no IP locked, safe to build"
exit 0
