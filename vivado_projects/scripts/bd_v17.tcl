# bd_v17.tcl — 终极方案：物理删除 BD → regen 重建 → 全部修正叠加 → 位流
set out [open {E:/yoloProject/vivado_projects/yoloproject/bd_v17.log} w]
proc L {msg} { global out; puts $out $msg; puts $msg; flush $out }
set ERR 0

open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}

# ---------- 1. 移除旧 BD 并物理删除 ----------
set oldbds [get_files -quiet -of_objects [get_filesets sources_1] *design_1.bd*]
foreach f $oldbds {
  L "remove bd: $f"
  catch { remove_files $f }
}
catch { file delete -force {E:/yoloProject/vivado_projects/yoloproject/yoloproject.srcs/sources_1/bd/design_1} }
catch { file delete -force {E:/yoloProject/vivado_projects/yoloproject/yoloproject.gen/sources_1/bd/design_1} }
close_project
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}

# ---------- 2. IP 仓库 + RTL + XDC ----------
if {[catch {
  set_property ip_repo_paths [list \
    {E:/dpu_ip_repo/zcu102-dpu-trd-2019-1-timer/pl/srcs/dpu_ip} \
    {E:/yoloProject/rtl}] [current_project]
  update_ip_catalog
} e]} { L "ERR repo: $e"; incr ERR }
foreach f {ov5640_cam_top.v async_fifo_18b.v I2C_OV5640_1280720_Config.v i2c_timing_ctrl_reg16_dat8_wronly.v} {
  if {[llength [get_files -quiet *$f]] == 0} {
    if {[catch { add_files -fileset sources_1 -norecurse E:/yoloProject/rtl/$f } e]} { L "ERR add $f: $e"; incr ERR }
  }
}
if {[llength [get_files -quiet *camera.xdc]] == 0} {
  if {[catch { add_files -fileset constrs_1 -norecurse E:/yoloProject/rtl/camera.xdc } e]} { L "ERR add xdc: $e"; incr ERR }
}
if {[llength [get_files -quiet *clock_route_fix_impl.xdc]] == 0} {
  if {[catch { add_files -fileset constrs_1 -norecurse E:/yoloProject/rtl/clock_route_fix_impl.xdc } e]} { L "ERR add xdc2: $e"; incr ERR }
}

# ---------- 3. regen 重建 BD（原设计拓扑） ----------
L "regen 重建 BD..."
if {[catch { source {E:/yoloProject/design_1_regen.tcl} } e]} { L "ERR regen: $e"; incr ERR }
set bd [lindex [get_files -quiet -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd
set ps7 [get_bd_cells /processing_system7_0]

# ---------- 4. PS 修正叠加（hw7 字典之外的增量） ----------
set add {}
lappend add CONFIG.PCW_USE_S_AXI_HP0 1
lappend add CONFIG.PCW_USE_S_AXI_HP1 1
lappend add CONFIG.PCW_USE_S_AXI_HP2 1
lappend add CONFIG.PCW_USE_S_AXI_HP3 1
lappend add CONFIG.PCW_ENET0_RESET_ENABLE 1
lappend add CONFIG.PCW_ENET0_RESET_IO {MIO 51}
lappend add CONFIG.PCW_ENET_RESET_ENABLE 1
lappend add CONFIG.PCW_ENET_RESET_SELECT {Share reset pin}
lappend add CONFIG.PCW_IRQ_F2P_INTR 1
lappend add CONFIG.PCW_IRQ_F2P_MODE DIRECT
lappend add CONFIG.PCW_GPIO_MIO_GPIO_ENABLE 1
lappend add CONFIG.PCW_GPIO_MIO_GPIO_IO {MIO}
foreach {k v} $add {
  if {[catch { set_property CONFIG.$k $v $ps7 } e]} { L "ERR $k: $e"; incr ERR } else { L "SET $k = $v" }
}
# 关键项验证
foreach {k exp} {PCW_UART1_PERIPHERAL_ENABLE 1 PCW_SD0_PERIPHERAL_ENABLE 1 \
  PCW_ENET0_PERIPHERAL_ENABLE 1 PCW_QSPI_PERIPHERAL_ENABLE 1 \
  PCW_SD1_PERIPHERAL_ENABLE 1 PCW_IRQ_F2P_INTR 1 \
  PCW_USE_S_AXI_HP0 1 PCW_USE_S_AXI_HP3 1 \
  PCW_UIPARAM_DDR_PARTNO {MT41K256M16 RE-125} PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V}} {
  set cur [get_property CONFIG.$k $ps7]
  if {$cur ne $exp} { L "REGRESS $k = $cur (期望 $exp)"; incr ERR } else { L "KEEP $k = $cur" }
}
# 时钟引脚连接（FCLK 网已在 regen 中）
foreach {hp c} {0 clk_wiz_0/clk_out2 1 clk_wiz_0/clk_out2 2 clk_wiz_0/clk_out2 3 clk_wiz_0/clk_out1} {
  if {[catch { connect_bd_net [get_bd_pins $c] [get_bd_pins processing_system7_0/S_AXI_HP${hp}_ACLK] } e]} { L "ERR ACLK$hp: $e"; incr ERR }
}

# ---------- 5. 摄像头模块 + VDMA ----------
if {[catch { create_bd_cell -type module -reference ov5640_cam_top ov5640_0 } e]} {
  L "ERR module: $e"; incr ERR
}
set clk100 [get_bd_pins clk_wiz_0/clk_out1]
set rst100 [get_bd_pins proc_sys_reset_1/peripheral_aresetn]
if {[catch { connect_bd_net $clk100 [get_bd_pins ov5640_0/ACLK] } e]} { L "ERR cam clk: $e"; incr ERR }
if {[catch { connect_bd_net $rst100 [get_bd_pins ov5640_0/ARESETN] } e]} { L "ERR cam rst: $e"; incr ERR }
foreach p {cmos_pclk cmos_vsync cmos_href cmos_xclk cmos_scl cmos_sda cam_cfg_done} {
  if {[catch {
    make_bd_pins_external [get_bd_pins ov5640_0/$p]
    set_property NAME $p [get_bd_ports -quiet -filter "NAME =~ *${p}*"]
  } e]} { L "ERR ext $p: $e"; incr ERR }
}
if {[catch {
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma_0
  set_property -dict [list \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_num_fstores {1} \
    CONFIG.c_m_axi_s2mm_data_width {64} \
    CONFIG.c_s2mm_genlock_mode {0}] [get_bd_cells axi_vdma_0]
  connect_bd_intf_net [get_bd_intf_pins ov5640_0/m_axis_video] [get_bd_intf_pins axi_vdma_0/S_AXIS_S2MM]
  connect_bd_net $clk100 [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk]
  connect_bd_net $clk100 [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk]
  connect_bd_net $rst100 [get_bd_pins axi_vdma_0/s_axis_s2mm_resetn]
} e]} { L "ERR VDMA: $e"; incr ERR }

# ---------- 6. 验证保存 ----------
if {[catch {validate_bd_design} e]} { L "VALIDATE FAIL: $e"; incr ERR } else { L "VALIDATE OK" }
if {[catch {save_bd_design} e]} { L "SAVE FAIL: $e"; incr ERR }
if {[catch { generate_target all [get_bd_designs] } e]} { L "gen(warn): $e" }
if {[catch { write_hwdef -force -file {E:/yoloProject/petalinux_projects/zturn_hw/design_1_wrapper_fixed.hdf} } e]} { L "hwdef ERR: $e" } else { L "hwdef OK" }
close_project

# ---------- 7. 启动位流构建（综合+实现+位流，约 30-50 分钟） ----------
if {[catch {
  launch_runs impl_1 -to_step write_bitstream -jobs 4
  wait_on_run impl_1
} e]} { L "RUN ERR: $e"; incr ERR }
L "impl_1 STATUS: [get_property STATUS impl_1]  PROGRESS: [get_property PROGRESS impl_1]"
if {[catch { write_hwdef -force -file {E:/yoloProject/petalinux_projects/zturn_hw/design_1_wrapper_fixed.hdf} } e]} { L "hwdef ERR: $e" } else { L "hwdef OK (含位流)" }
close_project
L "BD_V17_DONE err=$ERR"
close $out
exit
