# bd_camera_surgery.tcl — BD 手术：
# 1) 使能 HP0-HP3  2) DPU DATA0/DATA1/INSTR -> 互联 -> HP0/1/2
# 3) ov5640_cam_top 模块参考 + 引脚外联  4) VDMA(S2MM) -> HP3
set out [open {E:/yoloProject/vivado_projects/yoloproject/bd_surgery.log} w]
proc L {msg} { global out; puts $out $msg; puts $msg; flush $out }
set ERR 0
proc C {cmd args} { global ERR; if {[catch {uplevel 1 $cmd $args} e]} { global out; puts $out "ERR: $cmd --> [string range $e 0 140]"; set ::ERR [expr $::ERR+1]; return 0 } else { return 1 } }

open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bd [lindex [get_files -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd
set ps7 [get_bd_cells /processing_system7_0]

# ---------- 1. 使能 4 个 HP 从端口 ----------
foreach hp {0 1 2 3} {
  C set_property CONFIG.PCW_USE_S_AXI_HP$hp {1} $ps7
}
L "HP0=[get_property CONFIG.PCW_USE_S_AXI_HP0 $ps7] HP1=[get_property CONFIG.PCW_USE_S_AXI_HP1 $ps7] HP2=[get_property CONFIG.PCW_USE_S_AXI_HP2 $ps7] HP3=[get_property CONFIG.PCW_USE_S_AXI_HP3 $ps7]"

# ---------- 2. 摄像头 RTL 加入工程 ----------
set rtl_dir {E:/yoloProject/rtl}
foreach f {ov5640_cam_top.v async_fifo_18b.v I2C_OV5640_1280720_Config.v i2c_timing_ctrl_reg16_dat8_wronly.v} {
  C add_files -fileset sources_1 -norecurse $rtl_dir/$f
}
C add_files -fileset constrs_1 -norecurse $rtl_dir/camera.xdc

# ---------- 3. 时钟/复位引用 ----------
set clk100 [get_bd_pins clk_wiz_0/clk_out1]   ;# 100M：控制域 + 摄像头域
set clk150 [get_bd_pins clk_wiz_0/clk_out2]   ;# 150M：DPU 数据域
set rst100 [get_bd_pins proc_sys_reset_1/peripheral_aresetn]
set rst150 [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

# ---------- 4. DPU 三条数据通路 -> HP0/1/2 ----------
set map [list \
  {DPU0_M_AXI_DATA0} {dpu_icc0} {S_AXI_HP0} \
  {DPU0_M_AXI_DATA1} {dpu_icc1} {S_AXI_HP1} \
  {DPU0_M_AXI_INSTR} {dpu_icc2} {S_AXI_HP2}]
foreach {dintf iccname hp} $map {
  if {[catch {
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 $iccname
    set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1} \
      CONFIG.STRATEGY {2} CONFIG.M00_HAS_REGSLICE {1} CONFIG.S00_HAS_REGSLICE {1}] [get_bd_cells $iccname]
    connect_bd_intf_net [get_bd_intf_pins dpu_eu_0/$dintf] [get_bd_intf_pins $iccname/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins $iccname/M00_AXI] [get_bd_intf_pins ps7/$hp]
    connect_bd_net $clk150 [get_bd_pins $iccname/ACLK]
    connect_bd_net $clk150 [get_bd_pins $iccname/M00_ACLK]
    connect_bd_net $clk150 [get_bd_pins $iccname/S00_ACLK]
    connect_bd_net $rst150 [get_bd_pins $iccname/ARESETN]
    connect_bd_net $rst150 [get_bd_pins $iccname/M00_ARESETN]
    connect_bd_net $rst150 [get_bd_pins $iccname/S00_ARESETN]
    connect_bd_net $clk150 [get_bd_pins ps7/${hp}_ACLK]
    L "OK  $dintf -> $iccname -> $hp (150M 域)"
  } e]} { L "ERR $dintf: [string range $e 0 140]"; incr ERR }
}

# ---------- 5. 摄像头模块参考 ----------
if {[catch {
  create_bd_cell -type module -reference ov5640_cam_top ov5640_0
} e]} { L "ERR module ref: $e"; incr ERR }
# 时钟/复位
C connect_bd_net $clk100 [get_bd_pins ov5640_0/ACLK]
C connect_bd_net $rst100 [get_bd_pins ov5640_0/ARESETN]
# 摄像头引脚外联（名字与 XDC 一致）
foreach p {cmos_pclk cmos_data cmos_vsync cmos_href cmos_xclk cmos_scl cmos_sda cam_cfg_done} {
  if {[catch {
    make_bd_pins_external [get_bd_pins ov5640_0/$p]
    set ep [get_bd_ports -of_objects [get_bd_nets -of_objects [get_bd_pins ov5640_0/$p]] -quiet]
    L "EXT $p"
  } e]} { L "ERR ext $p: [string range $e 0 120]"; incr ERR }
}
# 外联端口重命名为 XDC 名（cmos_data 是总线）
foreach {old new} {ov5640_0_cmos_pclk cmos_pclk ov5640_0_cmos_vsync cmos_vsync \
                  ov5640_0_cmos_href cmos_href ov5640_0_cmos_xclk cmos_xclk \
                  ov5640_0_cmos_scl cmos_scl ov5640_0_cmos_sda cmos_sda \
                  ov5640_0_cam_cfg_done cam_cfg_done} {
  catch { set_property NAME $new [get_bd_ports $old] }
}
catch {
  set dport [get_bd_ports -filter {NAME =~ *cmos_data*}]
  set_property NAME cmos_data $dport
}

# ---------- 6. VDMA (S2MM) -> HP3 ----------
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
  connect_bd_net $clk100 [get_bd_pins ps7/S_AXI_HP3_ACLK]
  L "OK  VDMA S2MM -> vdma_icc -> HP3 (100M 域)"
} e]} { L "ERR VDMA: [string range $e 0 200]"; incr ERR }

# ---------- 7. 验证 & 导出 ----------
if {[catch {validate_bd_design} e]} { L "VALIDATE FAIL: $e"; incr ERR } else { L "VALIDATE OK" }
C save_bd_design
C generate_target all [get_files $bd]
C write_hwdef -force -file {E:/yoloProject/petalinux_projects/zturn_hw/design_1_wrapper_fixed.hdf}
close_project
L "SURGERY_DONE err=$ERR"
close $out
exit
