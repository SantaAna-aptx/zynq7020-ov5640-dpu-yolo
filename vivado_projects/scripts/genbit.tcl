# genbit.tcl -- open routed checkpoint and write bitstream
open_checkpoint {E:/yoloProject/vivado_projects/yolo2/yolo2.runs/impl_1/design_1_wrapper_routed.dcp}
write_bitstream -force E:/yoloProject/vivado_projects/yolo2/yolo2.runs/impl_1/design_1_wrapper.bit
set bit E:/yoloProject/vivado_projects/yolo2/yolo2.runs/impl_1/design_1_wrapper.bit
if {[file exists $bit]} {
    file copy -force $bit E:/yoloProject/web/design_1_wrapper_vdma.bit
    puts "BIT COPIED: [file size $bit] bytes"
} else { puts "BIT_MISSING"; exit 1 }
puts "GENBIT_DONE"
