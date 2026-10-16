# inspect_dpu_params.tcl -- read the dpu_eu_0 parameter set that the unified BD actually exposes,
# then dry-run the known-good analytic parameter set (taken from design_1_regen.tcl, the config
# that produced the 8/8 bitstream) and print the resulting DNNDK_PRINT.
#
# Read-only: the BD is deliberately NEVER saved, so the project is left untouched.
#
# Why this matters: the unified BD only carries ARCH/DWCV_ENA/LOAD_AUGM/POOL_AVERAGE/
# CONV_RELU_ADDON. Its DNNDK_PRINT says "AveragePool:Disabled; ReLU Type:ReLU + ReLU6;
# Channel Augmentation:Disabled" while the model needs AveragePool, Conv+Leakyrelu and Channel
# Augmentation all Enabled - which is exactly what the board reported:
#   [DNNDK] DPU configuration mismatch for kernel tiny_yolo - parameter: Conv+Leakyrelu,
#           DPU kernel: Enabled, DPU IP: Disabled.

set xpr "E:/yoloProject/vivado_projects/unified/unified.xpr"
open_project $xpr
open_bd_design [get_files design_1.bd]

set cell "dpu_eu_0"
if {[llength [get_bd_cells -quiet $cell]] == 0} {
    puts "FATAL: no bd cell $cell"
    exit 1
}

puts "########## 1) ALL CONFIG properties currently exposed on $cell ##########"
foreach p [lsort [list_property [get_bd_cells $cell]]] {
    if {[string match "CONFIG.*" $p]} {
        if {[catch {set v [get_property $p [get_bd_cells $cell]]} e]} { set v "<err:$e>" }
        puts [format "   %-34s = %s" $p $v]
    }
}

puts ""
puts "########## 2) DNNDK_PRINT as the BD stands right now ##########"
if {[catch {set v [get_property CONFIG.DNNDK_PRINT [get_bd_cells $cell]]} e]} {
    puts "   <no DNNDK_PRINT: $e>"
} else {
    puts "   $v"
}

puts ""
puts "########## 3) dry run: apply the design_1_regen.tcl analytic set ##########"
# design_1_regen.tcl (top level of E:\yoloProject) built the bitstream whose DNNDK_PRINT read
# "Channel Augmentation:Enabled; DepthWiseConv:Enabled; AveragePool:Enabled;
#  ReLU Type:ReLU + LeakyReLU + ReLU6" - i.e. exactly the model's requirement list.
set want [list \
    CONFIG.ARCH          1152 \
    CONFIG.ARCH_ICP      12   \
    CONFIG.ARCH_OCP      12   \
    CONFIG.ARCH_PP       4    \
    CONFIG.BANK_IMG_N    8    \
    CONFIG.BANK_WGT_N    13   \
    CONFIG.BBANK_IMG_N   8    \
    CONFIG.BBANK_WGT_N   13   \
    CONFIG.CONV_DSP_NUM  192  \
    CONFIG.DWCV_DSP_NUM  18   \
    CONFIG.DWCV_PARALLEL 2    \
    CONFIG.SUM_BRAM_N    123.0 \
    CONFIG.SUM_DSP_NUM   212  \
]
foreach {k v} $want {
    if {[catch {set_property $k $v [get_bd_cells $cell]} e]} {
        puts [format "   %-22s FAILED  (%s)" $k [string trim $e]]
    } else {
        puts [format "   %-22s = %s  OK" $k $v]
    }
}
# POOL_AVERAGE was explicitly pinned to 0 in the unified BD; the good config leaves it alone.
if {[catch {set_property CONFIG.POOL_AVERAGE 1 [get_bd_cells $cell]} e]} {
    puts "   CONFIG.POOL_AVERAGE     FAILED  ($e)"
} else {
    puts "   CONFIG.POOL_AVERAGE     = 1  OK"
}

puts ""
puts "########## 4) DNNDK_PRINT after the dry run ##########"
if {[catch {set v [get_property CONFIG.DNNDK_PRINT [get_bd_cells $cell]]} e]} {
    puts "   <no DNNDK_PRINT: $e>"
} else {
    puts "   $v"
    puts ""
    foreach feature {"Channel Augmentation:Enabled" "DepthWiseConv:Enabled" \
                     "AveragePool:Enabled" "ReLU + LeakyReLU + ReLU6"} {
        if {[string match "*$feature*" $v]} {
            puts "   OK    $feature"
        } else {
            puts "   MISS  $feature"
        }
    }
}

puts ""
puts "########## 5) validate_bd_design (does the new config even build?) ##########"
if {[catch {validate_bd_design} e]} {
    puts "   validate FAILED: $e"
} else {
    puts "   validate OK"
}
puts "   (NOT saving - this run only inspects)"
close_bd_design [current_bd_design]
close_project
puts "DONE_INSPECT"
