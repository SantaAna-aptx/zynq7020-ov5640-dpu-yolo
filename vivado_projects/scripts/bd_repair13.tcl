# BD repair v13: shave resources so DPU+camera fit on 7020.
# 1) dpu_eu DWCV_ENA=0 (tiny_yolo has no depthwise layers -> safe)
# 2) vdma_icc: DATA_FIFO 2->0, REGSLICE 1->0 (same-domain; keep only protocol converter)
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]
set dpu [get_bd_cells dpu_eu_0]
puts "DWCV before: [get_property CONFIG.DWCV_ENA $dpu]"
catch { set_property CONFIG.DWCV_ENA {0} $dpu } e1
puts "dwcv off: $e1"
set icc [get_bd_cells vdma_icc]
catch { set_property -dict [list CONFIG.S00_HAS_DATA_FIFO {0} CONFIG.M00_HAS_DATA_FIFO {0} \
  CONFIG.S00_HAS_REGSLICE {0} CONFIG.M00_HAS_REGSLICE {0}] $icc } e2
puts "icc slim: $e2"
if {[catch {validate_bd_design} v]} { puts "VALIDATE_ERR: $v"; exit 1 } else { puts "validate OK" }
catch { generate_target all [get_files design_1.bd] } eg
puts "generate: $eg"
save_bd_design
puts "DWCV: [get_property CONFIG.DWCV_ENA [get_bd_cells dpu_eu_0]]"
puts "BD_REPAIR13_DONE"
