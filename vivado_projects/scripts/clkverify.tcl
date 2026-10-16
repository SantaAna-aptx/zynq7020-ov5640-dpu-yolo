# Verify the routed design has correct DPU clock wiring
set dcp [lindex [glob -nocomplain E:/yoloProject/vivado_projects/yoloproject/yoloproject.runs/impl_1/*routed.dcp] 0]
if {$dcp eq ""} { set dcp [lindex [glob -nocomplain E:/yoloProject/vivado_projects/yoloproject/yoloproject.runs/impl_1/*.dcp] 0] }
puts "DCP: $dcp"
open_checkpoint $dcp
puts "===== CLOCKS ====="
report_clocks
puts "===== DPU PIN CLOCKS ====="
foreach pat {dpu_2x_clk m_axi_dpu_aclk s_axi_aclk} {
    set pins [get_pins -hier -quiet -filter "NAME =~ *$pat"]
    foreach p $pins {
        set clks [get_clocks -quiet -of_objects $p]
        foreach c $clks {
            puts "PIN $p <- CLOCK $c period=[get_property PERIOD $c] wave=[get_property WAVEFORM $c]"
        }
    }
}
puts "CLKVERIFY_DONE"
