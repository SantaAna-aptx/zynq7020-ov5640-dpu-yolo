# rebuild_force_ooc.tcl -- force every Block-Design module-reference OOC run to re-synthesize
# before building.
#
# Why this is needed: cam_top is a module reference inside design_1, so it is synthesized in
# its OWN out-of-context run (design_1_cam_top_0_synth_1). Editing rtl/ov5640_cam_top.v does
# NOT invalidate that run, so `reset_run synth_1` alone re-runs the top level against a STALE
# cam_top netlist and the bitstream comes out unchanged. Measured proof: two builds three hours
# apart produced byte-identical bitstream payloads (md5 dbb91ba7...) even though the RTL had
# been rewritten in between.
open_project E:/yoloProject/vivado_projects/unified/unified.xpr

puts "=== runs before ==="
foreach r [get_runs -quiet] { puts "  [get_property NAME $r] : [get_property STATUS $r]" }

puts "=== resetting Block-Design OOC synthesis runs ==="
foreach r [get_runs -quiet -filter {IS_SYNTHESIS && NAME =~ "design_1_*"}] {
    if {[catch {reset_run $r} e]} { puts "  reset $r failed: [string range $e 0 80]" } else { puts "  reset $r" }
}
catch {reset_run synth_1}
catch {reset_run impl_1}
puts "  reset synth_1 / impl_1"

launch_runs synth_1 -jobs 4
wait_on_run synth_1
puts "SYNTH_STATUS: [get_property STATUS [get_runs synth_1]]"

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "IMPL_STATUS: [get_property STATUS [get_runs impl_1]]"
catch {puts "WNS=[get_property STATS.WNS [get_runs impl_1]] WHS=[get_property STATS.WHS [get_runs impl_1]]"}
puts "BUILD_DONE"
exit
