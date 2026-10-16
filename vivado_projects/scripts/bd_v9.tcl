# bd_v9.tcl — 推倒重建 BD + 官方预设 + DPU 数据通路 + 摄像头 + VDMA + 位流
set out [open {E:/yoloProject/vivado_projects/yoloproject/bd_v9.log} w]
proc L {msg} { global out; puts $out $msg; puts $msg; flush $out }
set ERR 0

open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}

# ---------- 1. 移除旧 BD ----------
set oldbds [get_files -quiet -of_objects [get_filesets sources_1] *design_1.bd*]
foreach f $oldbds {
  L "remove old bd: $f"
  catch { remove_files $f }
}
catch { file delete -force {E:/yoloProject/vivado_projects/yoloproject/yoloproject.srcs/sources_1/bd/design_1} }

# ---------- 2. IP 仓库 + RTL + XDC ----------
if {[catch {
  set_property ip_repo_paths [list \
    {E:/dpu_ip_repo/zcu102-dpu-trd-2019-1-timer/pl/srcs/dpu_ip} \
    {E:/yoloProject/rtl}] [current_project]
  update_ip_catalog
} e]} { L "ERR repo: $e"; incr ERR }
foreach f {ov5640_cam_top.v async_fifo_18b.v I2C_OV5640_1280720_Config.v i2c_timing_ctrl_reg16_dat8_wronly.v} {
  catch { add_files -fileset sources_1 -norecurse E:/yoloProject/rtl/$f }
}
catch { add_files -fileset constrs_1 -norecurse E:/yoloProject/rtl/camera.xdc }

# ---------- 3. 干净重建 BD ----------
L "重建 BD..."
if {[catch { source {E:/yoloProject/design_1_regen.tcl} } e]} { L "ERR regen: $e"; incr ERR }
set bds [get_files -quiet -filter {FILE_TYPE == "Block Designs"}]
L "BD now: $bds"
set bd [lindex $bds 0]
if {[catch { open_bd_design $bd } e]} { L "ERR open: $e" }
set ps7 [get_bd_cells /processing_system7_0]

# ---------- 4. 官方预设一键应用 ----------
if {[catch {
  source {E:/xilinxFPGAlessonFacilities/Milianke7x.tcl}
  set d [apply_preset {}]
  set_property -dict $d $ps7
} e]} { L "ERR preset: $e"; incr ERR }
L "预设应用完成 UART1=[get_property CONFIG.PCW_UART1_PERIPHERAL_ENABLE $ps7] DDR=[get_property CONFIG.PCW_UIPARAM_DDR_PARTNO $ps7]"

# ---------- 5. 官方预设之上的补充（网口复位 MIO51）----------
catch { set_property CONFIG.PCW_ENET0_RESET_ENABLE {1} $ps7 }
catch { set_property CONFIG.PCW_ENET0_RESET_IO {MIO 51} $ps7 }
catch { set_property CONFIG.PCW_ENET_RESET_ENABLE {1} $ps7 }
catch { set_property CONFIG.PCW_ENET_RESET_SELECT {Share reset pin} $ps7 }

# ---------- 6. 使能 HP0-3 ----------
foreach hp {0 1 2 3} {
  if {[catch { set_property CONFIG.PCW_USE_S_AXI_HP$hp {1} $ps7 } e]} { L "ERR HP$hp: $e"; incr ERR }
}

# ---------- 7. validate#1（预期 41-758；HP ACLK 引脚实体化） ----------
if {[catch { validate_bd_design } e]} { L "validate#1 failed as expected (pins materialized)" } else { L "validate#1 OK" }

# ---------- 8. 时钟/复位 + 连接 HP ACLK ----------
set clk100 [get_bd_pins clk_wiz_0/clk_out1]
set clk150 [get_bd_pins clk_wiz_0/clk_out2]
set rst100 [get_bd_pins proc_sys_reset_1/peripheral_aresetn]
set rst150 [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
foreach {hp clksrc} "0 $clk150 1 $clk150 2 $clk150 3 $clk100" {
  if {[catch { connect_bd_net $clksrc [get_bd_pins ps7/S_AXI_HP${hp}_ACLK] } e]} { L "ERR ACLK$hp: $e"; incr ERR }
}

# ---------- 9. validate#2（传播，S_AXI_HP* 接口出现） ----------
if {[catch { validate_bd_design } e]} { L "validate#2 FAIL: $e"; incr ERR } else { L "validate#2 OK" }
foreach hp {0 1 2 3} {
  L "HP$hp intf: [llength [get_bd_intf_pins -quiet ps7/S_AXI_HP$hp]]"
}

# ---------- 10. DPU 数据通路 ----------
foreach {dintf iccname hp} {DPU0_M_AXI_DATA0 dpu_icc0 S_AXI_HP0
                            DPU0_M_AXI_DATA1 dpu_icc1 S_AXI_HP1
                            DPU0_M_AXI_INSTR dpu_icc2 S_AXI_HP2} {
  if {[catch {
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 $iccname
    set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1} \
      CONFIG.M00_HAS_REGSLICE {1} CONFIG.S00_HAS_REGSLICE {1}] [get_bd_cells $iccname]
    connect_bd_intf_net [get_bd_intf_pins dpu_eu_0/$dintf] [get_bd_intf_pins $iccname/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins $iccname/M00_AXI] [get_bd_intf_pins ps7/$hp]
    connect_bd_net $clk150 [get_bd_pins $iccname/ACLK]
    connect_bd_net $clk150 [get_bd_pins $iccname/M00_ACLK]
    connect_bd_net $clk150 [get_bd_pins $iccname/S00_ACLK]
    connect_bd_net $rst150 [get_bd_pins $iccname/ARESETN]
    connect_bd_net $rst150 [get_bd_pins $iccname/M00_ARESETN]
    connect_bd_net $rst150 [get_bd_pins $iccname/S00_ARESETN]
    L "OK  $dintf -> $iccname -> $hp"
  } e]} { L "ERR $dintf: [string range $e 0 200]"; incr ERR }
}

# ---------- 11. 摄像头模块 ----------
if {[catch { create_bd_cell -type module -reference ov5640_cam_top ov5640_0 } e]} {
  L "ERR module: $e"; incr ERR
}
if {[catch { connect_bd_net $clk100 [get_bd_pins ov5640_0/ACLK] } e]} { L "ERR cam clk: $e"; incr ERR }
if {[catch { connect_bd_net $rst100 [get_bd_pins ov5640_0/ARESETN] } e]} { L "ERR cam rst: $e"; incr ERR }
foreach p {cmos_pclk cmos_vsync cmos_href cmos_xclk cmos_scl cmos_sda cam_cfg_done} {
  if {[catch {
    make_bd_pins_external [get_bd_pins ov5640_0/$p]
    set_property NAME $p [get_bd_ports -quiet -filter "NAME =~ *${p}*"]
  } e]} { L "ERR ext $p: [string range $e 0 120]"; incr ERR }
}

# ---------- 12. VDMA -> HP3 ----------
if {[catch {
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma_0
  set_property -dict [list \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_num_fstores {1} \
    CONFIG.c_m_axi_s2mm_data_width {64} \
    CONFIG.c_s2mm_genlock_mode {0}] [get_bd_cells axi_vdma_0]
  connect_bd_intf_net [get_bd_intf_pins ov5640_0/m_axis_video] [get_bd_intf_pins axi_vdma_0/S_AXIS_S2MM]
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 vdma_icc
  set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1} \
    CONFIG.S00_HAS_DATA_FIFO {2} CONFIG.M00_HAS_DATA_FIFO {2} \
    CONFIG.S00_HAS_REGSLICE {1} CONFIG.M00_HAS_REGSLICE {1}] [get_bd_cells vdma_icc]
  connect_bd_intf_net [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM] [get_bd_intf_pins vdma_icc/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins vdma_icc/M00_AXI] [get_bd_intf_pins ps7/S_AXI_HP3]
  connect_bd_net $clk100 [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk]
  connect_bd_net $clk100 [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk]
  connect_bd_net $rst100 [get_bd_pins axi_vdma_0/s_axis_s2mm_resetn]
  connect_bd_net $rst100 [get_bd_pins axi_vdma_0/m_axi_s2mm_resetn]
  connect_bd_net $clk100 [get_bd_pins vdma_icc/ACLK]
  connect_bd_net $clk100 [get_bd_pins vdma_icc/S00_ACLK]
  connect_bd_net $clk100 [get_bd_pins vdma_icc/M00_ACLK]
  connect_bd_net $rst100 [get_bd_pins vdma_icc/ARESETN]
  connect_bd_net $rst100 [get_bd_pins vdma_icc/S00_ARESETN]
  connect_bd_net $rst100 [get_bd_pins vdma_icc/M00_ARESETN]
  L "OK  VDMA -> vdma_icc -> HP3"
} e]} { L "ERR VDMA: [string range $e 0 200]"; incr ERR }

# ---------- 13. 验证保存 ----------
if {[catch {validate_bd_design} e]} { L "VALIDATE FAIL: $e"; incr ERR } else { L "VALIDATE OK" }
if {[catch {save_bd_design} e]} { L "SAVE FAIL: $e"; incr ERR }

if {$ERR == 0} {
  L "launch_runs impl_1 -to_step write_bitstream..."
  if {[catch {
    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1
  } e]} { L "RUN ERR: $e"; incr ERR }
  L "impl_1 STATUS: [get_property STATUS impl_1]  PROGRESS: [get_property PROGRESS impl_1]"
  if {[catch { write_hwdef -force -file {E:/yoloProject/petalinux_projects/zturn_hw/design_1_wrapper_fixed.hdf} } e]} { L "write ERR: $e" } else { L "write_hwdef OK" }
} else {
  L "skip bitstream due to errors"
}
close_project
L "BD_V9_DONE err=$ERR"
close $out
exit
