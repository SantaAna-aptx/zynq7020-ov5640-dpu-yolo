# fix_clk2x_and_build.tcl -- correct dpu_2x_clk from 150 MHz to 200 MHz, then rebuild.
#
# SYMPTOM: with the DPU feature set finally correct (dexplorer -w shows all six Enabled), the app
# ran but produced non-deterministic garbage - identical=0 with a different checksum every run,
# 15 nonsense classes, boxes like (-1510,-5858)-(1997,6246). The D3 bitstream on the same board,
# kernel, CMA and app is identical=1 with correct boxes.
#
# ROOT CAUSE: the DPU IP generates its own timing constraints (dpu_ip/dpu/ttcl/timing_clocks_xdc.ttcl):
#     ##########################
#     # constrains for DDR-DSP #
#     ##########################
#     set clk_2x [get_clocks -of_objects [get_ports dpu_2x_clk     ]]
#     set clk_1x [get_clocks -of_objects [get_ports m_axi_dpu_aclk ]]
#     set_multicycle_path 2 -setup -start -from $clk_2x -to $clk_1x
#     set_multicycle_path 2 -setup -end   -from $clk_1x -to $clk_2x
# A multicycle of 2 between these two clocks only holds if dpu_2x_clk is EXACTLY twice
# m_axi_dpu_aclk. The unified BD ran m_axi_dpu_aclk = 100 MHz with dpu_2x_clk = 150 MHz - a 1.5x
# ratio between two clocks that are not integer-related, so their phase drifts and the 2x-domain
# state machine that paces the 1x domain misfires. That is precisely a non-deterministic result.
#
# PROOF by comparison with the bitstream that works (vivado_projects/yoloproject, the source of
# dpu_fclk0.bin):
#     PRIM_IN_FREQ 50.000, MMCM_CLKFBOUT_MULT_F 20, CLKOUT0/1/2 divides 10/10/5  -> VCO 1000 MHz
#     clk_out1 = 100 (s_axi), clk_out2 = 100 (m_axi_dpu_aclk), clk_out3 = 200 (dpu_2x_clk)
# i.e. 100/200, exactly 2x. The unified design's only deviation from that validated clocking is
# clk_out3 = 150 instead of 200, and nothing else in the design consumes clk_out3 except the DPU's
# dpu_2x_clk and the reset synchroniser.
#
# 200 MHz is also the SAFER choice: D3 closed timing with the same all-features DPU at 200 MHz.

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
proc ClkWiz {} {
    set c [get_bd_cells clk_wiz_0]
    foreach p {CLKOUT1_REQUESTED_OUT_FREQ CLKOUT2_REQUESTED_OUT_FREQ CLKOUT3_REQUESTED_OUT_FREQ
               CLKOUT1_ACTUAL_OUT_FREQ CLKOUT2_ACTUAL_OUT_FREQ CLKOUT3_ACTUAL_OUT_FREQ
               PRIM_IN_FREQ MMCM_CLKFBOUT_MULT_F MMCM_CLKOUT0_DIVIDE_F MMCM_CLKOUT1_DIVIDE
               MMCM_CLKOUT2_DIVIDE} {
        set v "?"
        if {[catch {set v [get_property CONFIG.$p $c]}]} { set v "<absent>" }
        puts [format "   %-32s = %s" $p $v]
    }
}
proc DpuFeat {} {
    set c [get_bd_cells dpu_eu_0]
    foreach p {CONV_RELU_ADDON CONV_LEAKYRELU CONV_RELU6 POOL_AVERAGE LOAD_AUGM DWCV_ENA DWCV_PARALLEL} {
        set v "?"
        if {[catch {set v [get_property CONFIG.$p $c]}]} { set v "<absent>" }
        puts [format "   %-18s = %s" $p $v]
    }
}

puts "########## locked IPs before: [LockedIPs] ##########"
for {set a 1} {$a <= 4} {incr a} {
    foreach ip [get_ips -quiet] { catch {upgrade_ip -quiet $ip} }
    if {[llength [LockedIPs]] == 0} { break }
}
puts "   locked after upgrade: [LockedIPs]"

puts ""
puts "########## clk_wiz_0 BEFORE ##########"
ClkWiz

puts ""
puts "########## setting CLKOUT3 (dpu_2x_clk) 150 -> 200 MHz ##########"
set_property CONFIG.CLKOUT3_REQUESTED_OUT_FREQ 200 [get_bd_cells clk_wiz_0]
# let the wizard re-solve the MMCM (expect VCO 1000 MHz, MULT_F 20, divides 10/10/5)
catch {set_property CONFIG.CLKOUT3_USED true [get_bd_cells clk_wiz_0]}

puts ""
puts "########## clk_wiz_0 AFTER ##########"
ClkWiz

# ---- verify the ratio is exactly 2x, and that the DPU feature fix survived ----
set cw [get_bd_cells clk_wiz_0]
set r1 [get_property CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $cw]
set r3 [get_property CONFIG.CLKOUT3_REQUESTED_OUT_FREQ $cw]
set a1 "?"
set a3 "?"
catch {set a1 [get_property CONFIG.CLKOUT2_ACTUAL_OUT_FREQ $cw]}
catch {set a3 [get_property CONFIG.CLKOUT3_ACTUAL_OUT_FREQ $cw]}
puts ""
puts "########## ratio check ##########"
puts "   m_axi_dpu_aclk : requested=$r1  actual=$a1"
puts "   dpu_2x_clk     : requested=$r3  actual=$a3"
set okClk 1
if {[expr {double($r3)}] != [expr {2.0 * double($r1)}]} {
    puts "   FAIL: requested clocks are not in an exact 2x ratio"
    set okClk 0
} else {
    puts "   OK: requested 2x ratio"
}
# ACTUAL_OUT_FREQ is only populated once the IP's output products are regenerated, so it is read
# as empty here. It is checked again after generate_target below - do not fail on it now.
puts "   (actual frequencies are verified after generate_target)"

puts ""
puts "########## DPU feature flags (must still be the fixed set) ##########"
DpuFeat
set d [get_bd_cells dpu_eu_0]
set okFeat 1
if {[get_property CONFIG.CONV_RELU_ADDON $d] != 3} { set okFeat 0 }
if {[get_property CONFIG.POOL_AVERAGE $d]    != 1} { set okFeat 0 }
if {[get_property CONFIG.LOAD_AUGM $d]       != 1} { set okFeat 0 }
set v [get_property CONFIG.DNNDK_PRINT $d]
foreach f {"Channel Augmentation:Enabled" "DepthWiseConv:Enabled" "AveragePool:Enabled" \
           "ReLU + LeakyReLU + ReLU6"} {
    if {[string match "*$f*" $v]} { puts "   OK    $f" } else { puts "   MISS  $f"; set okFeat 0 }
}

if {!$okClk || !$okFeat} {
    puts "ABORT: okClk=$okClk okFeat=$okFeat - nothing saved"
    exit 1
}

save_bd_design
if {[catch {validate_bd_design} e]} { puts "ABORT validate: $e"; exit 1 }
puts "saved + validated"

puts "regenerating BD target products ..."
if {[catch {generate_target all $bd} e]} { puts "generate_target error: [string range $e 0 300]" }
set lk [LockedIPs]
puts "   locked after regenerate: $lk"
if {[llength $lk] > 0} { puts "ABORT: still locked: $lk"; exit 1 }

# Now the actual frequencies exist - this is the real 2x verification.
set a1b ""
set a3b ""
catch {set a1b [get_property CONFIG.CLKOUT2_ACTUAL_OUT_FREQ [get_bd_cells clk_wiz_0]]}
catch {set a3b [get_property CONFIG.CLKOUT3_ACTUAL_OUT_FREQ [get_bd_cells clk_wiz_0]]}
puts "   ACTUAL after regenerate: m_axi_dpu_aclk=$a1b  dpu_2x_clk=$a3b"
if {$a1b ne "" && $a3b ne ""} {
    if {[expr {double($a3b)}] != [expr {2.0 * double($a1b)}]} {
        puts "ABORT: actual clocks are not in an exact 2x ratio"
        exit 1
    }
    puts "   OK: actual 2x ratio"
} else {
    puts "   WARNING: actual frequencies still empty - relying on the requested ratio and the MMCM solve"
}
save_bd_design

puts "PREP_OK - building"
foreach r [get_runs -quiet -filter {IS_SYNTHESIS && NAME =~ "design_1_*"}] {
    if {[catch {reset_run $r} e]} { puts "  reset $r failed" } else { puts "  reset $r" }
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
