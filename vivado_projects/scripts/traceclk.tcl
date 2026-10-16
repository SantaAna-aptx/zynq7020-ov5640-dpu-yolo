set dcp [lindex [glob -nocomplain E:/yoloProject/vivado_projects/yoloproject/yoloproject.runs/impl_1/*routed.dcp] 0]
puts "DCP: $dcp mtime [clock format [file mtime $dcp]]"
open_checkpoint $dcp
set p [get_pins -quiet design_1_i/dpu_eu_0/dpu_2x_clk]
set n [get_nets -quiet -of_objects $p]
puts "NET NAME: [get_property NAME $n]"
set drv [get_pins -leaf -quiet -of_objects $n -filter {DIRECTION == OUT}]
puts "DRIVER: $drv"
set p2 [get_pins -quiet design_1_i/dpu_eu_0/m_axi_dpu_aclk]
set n2 [get_nets -quiet -of_objects $p2]
puts "M_AXI NET NAME: [get_property NAME $n2]"
set drv2 [get_pins -leaf -quiet -of_objects $n2 -filter {DIRECTION == OUT}]
puts "M_AXI DRIVER: $drv2"
puts TRACE_DONE
