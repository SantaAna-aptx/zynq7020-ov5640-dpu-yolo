# Build fixed bitstream: synth + impl + write_bitstream, then report timing and copy bit
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bdfile [get_files design_1.bd]
puts "=== generate targets ==="
if {[catch {generate_target all $bdfile} gmsg]} { puts "GEN_WARN: $gmsg" }
catch {export_ip_user_files -of_objects $bdfile -no_script -sync -force -quiet}
puts "=== launch impl to bitstream ==="
foreach r [get_runs] {
    set st [get_property STATUS $r]
    if {[string match "*fail*" [string tolower $st]]} {
        puts "RESET failed run: $r ($st)"
        catch {reset_run $r}
    }
}
catch {reset_run impl_1}
catch {reset_run synth_1}
foreach r [get_runs -filter {IS_SYNTHESIS && !IS_IMPLEMENTATION}] {
    puts "RESET OOC run: $r"
    catch {reset_run $r}
}
launch_runs synth_1 -jobs 4
wait_on_run synth_1
puts "SYNTH_STATUS: [get_property STATUS [get_runs synth_1]]"
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "IMPL_STATUS: [get_property STATUS [get_runs impl_1]]"
puts "IMPL_PROGRESS: [get_property PROGRESS [get_runs impl_1]]"
if {[catch {open_run impl_1} eo]} {
    puts "OPENRUN_ERR: $eo"
} else {
    set w [get_timing_paths -delay_type max -max_paths 1]
    puts "WNS_SETUP: [get_property SLACK $w]"
    catch {report_timing_summary -delay_type max -report_unconstrained -max_paths 3 -file E:/yoloProject/vivado_projects/scripts/post_impl_timing.rpt}
    # HARD GATE: verify dpu_2x_clk is NOT driven by FCLK_CLK0 buffer
    set p [get_pins -quiet design_1_i/dpu_eu_0/dpu_2x_clk]
    set n [get_nets -quiet -of_objects $p]
    set netname [get_property NAME $n]
    set drv [get_pins -leaf -quiet -of_objects $n -filter {DIRECTION == OUT}]
    puts "VERIFY_NET dpu_2x_clk: $netname"
    puts "VERIFY_DRV dpu_2x_clk: $drv"
    if {[string match "*FCLK*" $netname] || [string match "*fclk*" [string tolower $drv]]} {
        puts "CLOCK_WIRING_BAD - refusing to ship bitstream"
        puts "BUILD_2XFIX_DONE"
        exit 1
    } else {
        puts "CLOCK_WIRING_OK"
    }
}
set bit E:/yoloProject/vivado_projects/yoloproject/yoloproject.runs/impl_1/design_1_wrapper.bit
if {[file exists $bit]} {
    file copy -force $bit E:/yoloProject/board_deploy/sd_delivery/design_1_wrapper_2xfix.bit
    file copy -force $bit E:/yoloProject/web/design_1_wrapper_2xfix.bit
    puts "BIT COPIED: [file size $bit] bytes"
} else {
    puts "BIT_MISSING: $bit"
}
puts "BUILD_2XFIX_DONE"
