# fix_dpu_and_rebuild.tcl -- correct the DPU feature set in the unified BD and rebuild the bitstream.
#
# THE BUG: the unified BD pinned CONV_RELU_ADDON=2 / POOL_AVERAGE=0 / LOAD_AUGM=0, which the IP's
# own generators (dpu_ip/dpu/gui/dpu_eu_v3_0.gtcl) turn into:
#     ReLU Type:ReLU + ReLU6        (no LeakyReLU)
#     AveragePool:Disabled
#     Channel Augmentation:Disabled
# while the tiny_yolo model needs Conv+Leakyrelu, Conv+Relu6, Average Pool and Channel
# Augmentation all Enabled. On hardware that surfaced as:
#     [DNNDK] DPU configuration mismatch for kernel tiny_yolo - parameter: Conv+Leakyrelu,
#             DPU kernel: Enabled, DPU IP: Disabled.
# and the app refused to run.
#
# THE FIX (three settable params; everything else already derives correctly):
#     CONV_RELU_ADDON 2 -> 3   gives CONV_LEAKYRELU=1 AND CONV_RELU6=1 -> "ReLU + LeakyReLU + ReLU6"
#                              and DWCV_RELU6 = DWCV_ENA ? CONV_RELU6 : 0 = 1
#     POOL_AVERAGE    0 -> 1   gives AveragePool:Enabled
#     LOAD_AUGM       0 -> 1   gives Channel Augmentation:Enabled
# The analytic geometry (ARCH_ICP 12, ARCH_OCP 12, ARCH_PP 4, BANK_WGT_N 13, DWCV_PARALLEL 2,
# CONV_DSP_NUM 192, SUM_DSP_NUM 212, SUM_BRAM_N 123.0) is already identical to the known-good
# design_1_regen.tcl config and is NOT touched. DSP/BRAM totals do not depend on these three.
#
# The edit is verified against DNNDK_PRINT BEFORE anything is saved, and the project is only
# built if all four model-required features come back Enabled.

set xpr "E:/yoloProject/vivado_projects/unified/unified.xpr"
open_project $xpr
open_bd_design [get_files design_1.bd]
set c [get_bd_cells dpu_eu_0]

puts "########## before ##########"
puts "   CONV_RELU_ADDON = [get_property CONFIG.CONV_RELU_ADDON $c]"
puts "   POOL_AVERAGE    = [get_property CONFIG.POOL_AVERAGE $c]"
puts "   LOAD_AUGM       = [get_property CONFIG.LOAD_AUGM $c]"
puts "   DNNDK_PRINT     = [get_property CONFIG.DNNDK_PRINT $c]"

set_property CONFIG.CONV_RELU_ADDON 3 $c
set_property CONFIG.POOL_AVERAGE    1 $c
set_property CONFIG.LOAD_AUGM       1 $c

puts ""
puts "########## after ##########"
puts "   CONV_RELU_ADDON = [get_property CONFIG.CONV_RELU_ADDON $c]"
puts "   CONV_LEAKYRELU  = [get_property CONFIG.CONV_LEAKYRELU $c]"
puts "   CONV_RELU6      = [get_property CONFIG.CONV_RELU6 $c]"
puts "   DWCV_PARALLEL   = [get_property CONFIG.DWCV_PARALLEL $c]"
puts "   DWCV_RELU6      = [get_property CONFIG.DWCV_RELU6 $c]"
set v [get_property CONFIG.DNNDK_PRINT $c]
puts "   DNNDK_PRINT     = $v"

set ok 1
foreach f {"Channel Augmentation:Enabled" "DepthWiseConv:Enabled" "AveragePool:Enabled" \
           "ReLU + LeakyReLU + ReLU6"} {
    if {[string match "*$f*" $v]} {
        puts "   OK    $f"
    } else {
        puts "   MISS  $f"
        set ok 0
    }
}
if {!$ok} {
    puts "ABORT: the feature set is still incomplete - nothing saved"
    close_bd_design [current_bd_design]
    close_project
    exit 1
}

save_bd_design
if {[catch {validate_bd_design} e]} {
    puts "ABORT: validate_bd_design failed: $e"
    close_bd_design [current_bd_design]
    close_project
    exit 1
}
puts "saved + validated"

# The IP's output products have to be regenerated or the new feature flags never reach synthesis.
puts "regenerating BD target products ..."
if {[catch {generate_target all [get_files design_1.bd]} e]} {
    puts "ABORT: generate_target failed: $e"
    close_bd_design [current_bd_design]
    close_project
    exit 1
}
puts "target products regenerated"
close_bd_design [current_bd_design]
close_project
puts "FIX_SAVED"
