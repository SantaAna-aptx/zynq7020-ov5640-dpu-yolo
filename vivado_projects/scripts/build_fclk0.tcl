# Build bitstream with clk_wiz input on FCLK_CLK0, then verify wiring in the
# actual netlist and copy the bit out.
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
    exit 1
} else {
    set w [get_timing_paths -delay_type max -max_paths 1]
    puts "WNS_SETUP: [get_property SLACK $w]"
    catch {report_timing_summary -delay_type max -report_unconstrained -max_paths 3 -file E:/yoloProject/vivado_projects/scripts/post_impl_timing_fclk0.rpt}
}
# GATE 1: dpu_2x_clk must come from clk_wiz (clk_out3), NOT any FCLK
set p [get_pins -quiet design_1_i/dpu_eu_0/dpu_2x_clk]
set n [get_nets -quiet -of_objects $p]
set netname [get_property NAME $n]
set drv [get_pins -leaf -quiet -of_objects $n -filter {DIRECTION == OUT}]
puts "VERIFY_NET dpu_2x_clk: $netname"
puts "VERIFY_DRV dpu_2x_clk: $drv"
if {[string match "*FCLK*" $netname] || [string match "*fclk*" [string tolower $drv]]} {
    puts "CLOCK_WIRING_BAD_2X - refusing to ship"
    exit 1
}
# GATE 2 (new): clk_wiz clk_in1 must be driven by the FCLK_CLK0 net
set ci [get_pins -quiet design_1_i/clk_wiz_0/clk_in1]
if {[llength $ci] == 0} { puts "GATE2_ERR: clk_in1 pin not found"; exit 1 }
set nci [get_nets -quiet -of_objects $ci]
set netci [get_property NAME $nci]
puts "VERIFY_NET clk_in1: $netci"
if {![string match "*FCLK_CLK0*" $netci]} {
    puts "CLKIN_WIRING_BAD - clk_in1 not on FCLK_CLK0, refusing to ship"
    exit 1
}
puts "CLOCK_WIRING_OK"
set bit E:/yoloProject/vivado_projects/yoloproject/yoloproject.runs/impl_1/design_1_wrapper.bit
if {[file exists $bit]} {
    file copy -force $bit E:/yoloProject/board_deploy/sd_delivery/design_1_wrapper_fclk0.bit
    file copy -force $bit E:/yoloProject/web/design_1_wrapper_fclk0.bit
    puts "BIT COPIED: [file size $bit] bytes"
    puts "BIT_MD5: [exec cmd /c certutil -hashfile $bit MD5]"
} else {
    puts "BIT_MISSING: $bit"
    exit 1
}
puts "BUILD_FCLK0_DONE"
