# Utilization report from synth checkpoint (hierarchical, top offenders)
open_checkpoint {E:/yoloProject/vivado_projects/yoloproject/yoloproject.runs/synth_1/design_1_wrapper.dcp}
report_utilization -file {E:/yoloProject/vivado_projects/scripts/util_synth.rpt}
report_utilization -hierarchical -hierarchical_depth 2 -file {E:\yoloProject\vivado_projects\scripts\util_hier.rpt}
puts "UTIL_REPORTS_DONE"
