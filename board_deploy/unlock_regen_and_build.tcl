# unlock_regen_and_build.tcl -- clear the IP locks, make sure the DPU feature fix survived, then
# regenerate output products and build the bitstream. One session, self-guarding.
#
# What was wrong (from report_ip_status):
#   design_1_dpu_eu_0_0   "IP contains locked subcore"   -> Upgrade IP or repackage component
#   design_1_ps7_0        "Stale IP file detected"       -> Upgrade IP
#   design_1_dbg_gpio_0   "Stale IP file detected"       -> Upgrade IP
#   design_1_rst_100_0    "Stale IP file detected"       -> Upgrade IP
#   design_1_rst_cam_0    "Stale IP file detected"       -> Upgrade IP
#   design_1_cam_top_0    "Stale module reference"       -> Refresh module reference
#   design_1_frame_writer_0_0 "Stale module reference"   -> Refresh module reference
# Every .dcp output product was missing, and reset_target/generate_target on the BD were refused
# with "Block design contains locked IPs" - chicken and egg. upgrade_ip is what breaks the cycle;
# in the diagnostic run it took the locked count from 5 to 0.
#
# DANGER guarded here: upgrade_ip can reset IP configuration. If the DPU's three feature params
# are lost the whole rebuild is pointless, so they are re-checked (and re-applied) after the
# upgrade and the DNNDK_PRINT must show all four model-required features before anything builds.

set XPR "E:/yoloProject/vivado_projects/unified/unified.xpr"
open_project $XPR
open_bd_design [get_files design_1.bd]
set bd [get_files design_1.bd]

proc LockedIPs {} {
    set out {}
    foreach ip [get_ips -quiet] {
        if {[catch {set l [get_property IS_LOCKED $ip]}]} { continue }
        if {$l} { lappend out [file tail [get_property IP_FILE $ip]] }
    }
    return $out
}

puts "########## locked before upgrade: [LockedIPs] ##########"
for {set attempt 1} {$attempt <= 4} {incr attempt} {
    puts "=== upgrade round $attempt ==="
    foreach ip [get_ips -quiet] { catch {upgrade_ip -quiet $ip} }
    set lk [LockedIPs]
    puts "   locked now: $lk"
    if {[llength $lk] == 0} { break }
}

puts ""
puts "########## did the DPU feature fix survive upgrade_ip? ##########"
set c [get_bd_cells dpu_eu_0]
set addon [get_property CONFIG.CONV_RELU_ADDON $c]
set pool  [get_property CONFIG.POOL_AVERAGE $c]
set augm  [get_property CONFIG.LOAD_AUGM $c]
puts "   CONV_RELU_ADDON=$addon  POOL_AVERAGE=$pool  LOAD_AUGM=$augm"
if {$addon != 3 || $pool != 1 || $augm != 1} {
    puts "   !! upgrade_ip reset them - re-applying the fix"
    set_property CONFIG.CONV_RELU_ADDON 3 $c
    set_property CONFIG.POOL_AVERAGE    1 $c
    set_property CONFIG.LOAD_AUGM       1 $c
    puts "   re-applied: CONV_RELU_ADDON=[get_property CONFIG.CONV_RELU_ADDON $c] POOL_AVERAGE=[get_property CONFIG.POOL_AVERAGE $c] LOAD_AUGM=[get_property CONFIG.LOAD_AUGM $c]"
}

set v [get_property CONFIG.DNNDK_PRINT $c]
puts "   DNNDK_PRINT = $v"
set ok 1
foreach f {"Channel Augmentation:Enabled" "DepthWiseConv:Enabled" "AveragePool:Enabled" \
           "ReLU + LeakyReLU + ReLU6"} {
    if {[string match "*$f*" $v]} { puts "   OK    $f" } else { puts "   MISS  $f"; set ok 0 }
}
if {!$ok} {
    puts "ABORT: DPU feature set is not right - refusing to build a useless bitstream"
    exit 1
}
save_bd_design

puts ""
puts "########## generate_target all (rebuilds every missing output product) ##########"
if {[catch {generate_target all $bd} e]} {
    puts "   generate_target error: [string range $e 0 300]"
} else {
    puts "   generate_target OK"
}
set lk2 [LockedIPs]
puts "   locked after regenerate: $lk2"

puts ""
puts "########## DPU OOC products on disk ##########"
set dcps [glob -nocomplain "E:/yoloProject/vivado_projects/unified/unified.srcs/sources_1/bd/design_1/ip/design_1_dpu_eu_0_0/*.dcp"]
if {[llength $dcps] == 0} { puts "   (none yet - they are produced by the OOC synthesis run)" }
foreach f $dcps { puts "   [file tail $f]  [file size $f] bytes" }

if {[llength $lk2] > 0} {
    puts "ABORT: still locked: $lk2"
    exit 1
}

save_bd_design
puts "PREP_OK - building"

puts "=== resetting Block-Design OOC synthesis runs ==="
foreach r [get_runs -quiet -filter {IS_SYNTHESIS && NAME =~ "design_1_*"}] {
    if {[catch {reset_run $r} e]} { puts "  reset $r failed: [string range $e 0 80]" } else { puts "  reset $r" }
}
catch {reset_run synth_1}
catch {reset_run impl_1}

launch_runs synth_1 -jobs 4
wait_on_run synth_1
puts "SYNTH_STATUS: [get_property STATUS [get_runs synth_1]]"

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "IMPL_STATUS: [get_property STATUS [get_runs impl_1]]"
catch {puts "WNS=[get_property STATS.WNS [get_runs impl_1]] WHS=[get_property STATS.WHS [get_runs impl_1]]"}
puts "BUILD_DONE"
exit
