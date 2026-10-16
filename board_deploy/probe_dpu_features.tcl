# probe_dpu_features.tcl -- learn exactly which CONFIG booleans drive the three missing features.
#
# The unified dpu_eu_0 reports:
#   Channel Augmentation:Disabled ; AveragePool:Disabled ; ReLU Type:ReLU + ReLU6
# The model (and the known-good design_1_regen.tcl config) needs all three present:
#   Channel Augmentation:Enabled  ; AveragePool:Enabled  ; ReLU + LeakyReLU + ReLU6
# Everything else already matches the good config bit for bit (DSP Slice Count:212,
# Block-RAM Count:123.0, RAM Usage:Low, ARCH_ICP 12 / BANK_WGT_N 13 / DWCV_PARALLEL 2).
#
# There is no CHANNEL_AUG / POOL_AVERAGE-named param for augmentation, so this walks the
# candidates and prints DNNDK_PRINT after each step to see which one flips which feature.
# READ-ONLY: never saves.

open_project E:/yoloProject/vivado_projects/unified/unified.xpr
open_bd_design [get_files design_1.bd]
set c [get_bd_cells dpu_eu_0]

proc report {} {
    global c
    if {[catch {set v [get_property CONFIG.DNNDK_PRINT $c]} e]} { puts "   <err $e>"; return }
    foreach {label pat} {
        "ChannelAug"    "*Channel Augmentation:Enabled*"
        "DepthWiseConv" "*DepthWiseConv:Enabled*"
        "AvgPool"       "*AveragePool:Enabled*"
        "LeakyRelu"     "*ReLU + LeakyReLU + ReLU6*"
        "Relu6only"     "*ReLU Type:ReLU + ReLU6*"
    } {
        if {[string match $pat $v]} { puts "      $label  YES" } else { puts "      $label  ." }
    }
}

puts "########## candidate parameters present on the cell ##########"
foreach p {CONFIG.CONV_LEAKYRELU CONFIG.CONV_RELU6 CONFIG.CONV_RELU_ADDON \
           CONFIG.POOL_AVERAGE CONFIG.LOAD_AUGM CONFIG.LOAD_IMG_MEAN \
           CONFIG.DWCV_ENA CONFIG.DWCV_PARALLEL CONFIG.DWCV_RELU6 CONFIG.SFM_ENA} {
    if {[catch {set v [get_property $p $c]} e]} { puts "   $p = <absent>" } else { puts "   $p = $v" }
}

puts ""
puts "########## A) baseline ##########"
report

puts ""
puts "########## B) CONV_LEAKYRELU = 1 ##########"
catch {set_property CONFIG.CONV_LEAKYRELU 1 $c}
report

puts ""
puts "########## C) + POOL_AVERAGE = 1 ##########"
catch {set_property CONFIG.POOL_AVERAGE 1 $c}
report

puts ""
puts "########## D) + LOAD_AUGM = 1  (candidate for Channel Augmentation) ##########"
catch {set_property CONFIG.LOAD_AUGM 1 $c}
report

puts ""
puts "########## E) + CONV_RELU_ADDON = 0 (alternative way to get LeakyReLU) ##########"
catch {set_property CONFIG.CONV_RELU_ADDON 0 $c}
report

puts ""
puts "########## F) + LOAD_IMG_MEAN = 1 ##########"
catch {set_property CONFIG.LOAD_IMG_MEAN 1 $c}
report

puts ""
puts "########## final DNNDK_PRINT ##########"
puts "   [get_property CONFIG.DNNDK_PRINT $c]"
puts "PROBE_DONE"
close_bd_design [current_bd_design]
close_project
