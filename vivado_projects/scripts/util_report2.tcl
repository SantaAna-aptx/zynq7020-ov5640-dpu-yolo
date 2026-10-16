# Utilization v2: open synthesized design in project context (merges OOC IP DCPs)
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_run synth_1
report_utilization -file {E:/yoloProject/vivado_projects/scripts/util_full.rpt}
report_utilization -hierarchical -hierarchical_depth 2 -file {E:\yoloProject\vivado_projects\scripts\util_hier.rpt}
puts "UTIL2_DONE"
