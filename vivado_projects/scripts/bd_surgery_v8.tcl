# bd_surgery_v7.tcl - ACLK first, then validate(propagate), then data paths + bitstream
set out [open {E:/yoloProject/vivado_projects/yoloproject/bd_v8.log} w]
proc L {msg} { global out; puts $out $msg; puts $msg; flush $out }
set ERR 0

open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bd [lindex [get_files -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd
set ps7 [get_bd_cells /processing_system7_0]

# ---------- 0. cleanup ----------
L "cells before: [llength [get_bd_cells -quiet]]"
foreach c {dpu_icc0 dpu_icc1 dpu_icc2 vdma_icc axi_vdma_0 ov5640_0} {
  if {[catch { delete_bd_objs [get_bd_cells -quiet /$c] } e]} { L "DEL-CELL $c: $e" }
}
if {[catch { delete_bd_objs [get_bd_intf_ports -quiet] } e]} { L "DEL-INTFPORTS: $e" }
if {[catch { delete_bd_objs [get_bd_ports -quiet] } e]} { L "DEL-PORTS(warn ok): $e" }
L "after cleanup: ports=[llength [get_bd_ports -quiet]] intf=[llength [get_bd_intf_ports -quiet]]"

# ---------- 1. enable HP0-3 ----------
foreach hp {0 1 2 3} {
  if {[catch { set_property CONFIG.PCW_USE_S_AXI_HP$hp {1} $ps7 } e]} { L "ERR HP$hp: $e"; incr ERR }
}

# ---------- 1.5 validate#1: 触发 PS7 传播（预期 41-758 失败，忽略）——之后 ACLK 引脚才实体化 ----------
if {[catch { validate_bd_design } e]} { L "validate#1 failed as EXPECTED (41-758), pins now exist" } else { L "validate#1 unexpectedly OK" }

# ---------- 2. connect HPx_ACLK (clk150 for DPU path, clk100 for VDMA path) ----------
foreach {hp clksrc} "0 [get_bd_pins clk_wiz_0/clk_out2] 1 [get_bd_pins clk_wiz_0/clk_out2] 2 [get_bd_pins clk_wiz_0/clk_out2] 3 [get_bd_pins clk_wiz_0/clk_out1]" {
  if {[catch { connect_bd_net $clksrc [get_bd_pins ps7/S_AXI_HP${hp}_ACLK] } e]} { L "ERR ACLK$hp: $e"; incr ERR }
}

# ---------- 3. validate#2 = propagate (clocks now connected) ----------
if {[catch { validate_bd_design } e]} { L "propagate FAIL: $e"; incr ERR } else { L "propagate OK" }
foreach hp {0 1 2 3} {
  L "HP$hp intf: [llength [get_bd_intf_pins -quiet ps7/S_AXI_HP$hp]]"
}

# ---------- 4. RTL + XDC ----------
foreach f {ov5640_cam_top.v async_fifo_18b.v I2C_OV5640_1280720_Config.v i2c_timing_ctrl_reg16_dat8_wronly.v} {
  if {[llength [get_files -quiet *$f]] == 0} {
    if {[catch { add_files -fileset sources_1 -norecurse E:/yoloProject/rtl/$f } e]} { L "ERR add $f: $e"; incr ERR }
  }
}
if {[llength [get_files -quiet *camera.xdc]] == 0} {
  if {[catch { add_files -fileset constrs_1 -norecurse E:/yoloProject/rtl/camera.xdc } e]} { L "ERR add xdc: $e"; incr ERR }
}

# ---------- 5. DPU data paths (ACLK already wired) ----------
foreach {dintf iccname hp} {DPU0_M_AXI_DATA0 dpu_icc0 S_AXI_HP0
                            DPU0_M_AXI_DATA1 dpu_icc1 S_AXI_HP1
                            DPU0_M_AXI_INSTR dpu_icc2 S_AXI_HP2} {
  if {[catch {
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 $iccname
    set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1} \
      CONFIG.STRATEGY {2} CONFIG.M00_HAS_REGSLICE {1} CONFIG.S00_HAS_REGSLICE {1}] [get_bd_cells $iccname]
    connect_bd_intf_net [get_bd_intf_pins dpu_eu_0/$dintf] [get_bd_intf_pins $iccname/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins $iccname/M00_AXI] [get_bd_intf_pins ps7/$hp]
    connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins $iccname/ACLK]
    connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins $iccname/M00_ACLK]
    connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins $iccname/S00_ACLK]
    connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins $iccname/ARESETN]
    connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins $iccname/M00_ARESETN]
    connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins $iccname/S00_ARESETN]
    L "OK  $dintf -> $iccname -> $hp"
  } e]} { L "ERR $dintf: [string range $e 0 200]"; incr ERR }
}

# ---------- 6. camera module ----------
if {[catch { create_bd_cell -type module -reference ov5640_cam_top ov5640_0 } e]} {
  L "ERR module: $e"; incr ERR
}
if {[catch { connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins ov5640_0/ACLK] } e]} { L "ERR cam clk: $e"; incr ERR }
if {[catch { connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins ov5640_0/ARESETN] } e]} { L "ERR cam rst: $e"; incr ERR }
foreach p {cmos_pclk cmos_vsync cmos_href cmos_xclk cmos_scl cmos_sda cam_cfg_done} {
  if {[catch {
    make_bd_pins_external [get_bd_pins ov5640_0/$p]
    set_property NAME $p [get_bd_ports -quiet -filter "NAME =~ *${p}*"]
  } e]} { L "ERR ext $p: [string range $e 0 120]"; incr ERR }
}

# ---------- 7. VDMA -> HP3 (axis pin-to-pin) ----------
if {[catch {
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma_0
  set_property -dict [list \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_num_fstores {1} \
    CONFIG.c_m_axi_s2mm_data_width {64} \
    CONFIG.c_s2mm_data_width {64} \
    CONFIG.c_s2mm_genlock_mode {0} \
    CONFIG.c_include_s2mm_fsync {0}] [get_bd_cells axi_vdma_0]
  connect_bd_intf_net [get_bd_intf_pins ov5640_0/m_axis_video] [get_bd_intf_pins axi_vdma_0/S_AXIS_S2MM]
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 vdma_icc
  set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1} \
    CONFIG.S00_HAS_DATA_FIFO {2} CONFIG.M00_HAS_DATA_FIFO {2} \
    CONFIG.S00_HAS_REGSLICE {1} CONFIG.M00_HAS_REGSLICE {1}] [get_bd_cells vdma_icc]
  connect_bd_intf_net [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM] [get_bd_intf_pins vdma_icc/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins vdma_icc/M00_AXI] [get_bd_intf_pins ps7/S_AXI_HP3]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk]
  connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_vdma_0/s_axis_s2mm_resetn]
  connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_vdma_0/m_axi_s2mm_resetn]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins vdma_icc/ACLK]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins vdma_icc/S00_ACLK]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins vdma_icc/M00_ACLK]
  connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins vdma_icc/ARESETN]
  connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins vdma_icc/S00_ARESETN]
  connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins vdma_icc/M00_ARESETN]
  L "OK  VDMA -> vdma_icc -> HP3"
} e]} { L "ERR VDMA: [string range $e 0 200]"; incr ERR }

# ---------- 8. validate & save ----------
if {[catch {validate_bd_design} e]} { L "VALIDATE FAIL: $e"; incr ERR } else { L "VALIDATE OK" }
if {[catch {save_bd_design} e]} { L "SAVE FAIL: $e"; incr ERR }

if {$ERR == 0} {
  L "launch_runs impl_1 -to_step write_bitstream..."
  if {[catch {
    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1
  } e]} { L "RUN ERR: $e"; incr ERR }
  L "impl_1 STATUS: [get_property STATUS impl_1]  PROGRESS: [get_property PROGRESS impl_1]"
  if {[catch { generate_target all [get_files $bd] } e]} { L "gen ERR: $e" }
  if {[catch { write_hwdef -force -file {E:/yoloProject/petalinux_projects/zturn_hw/design_1_wrapper_fixed.hdf} } e]} { L "write ERR: $e" } else { L "write_hwdef OK" }
} else {
  L "skip bitstream due to errors"
}
close_project
L "SURGERY_V8_DONE err=$ERR"
close $out
exit

