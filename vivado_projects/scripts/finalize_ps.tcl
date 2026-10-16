# finalize_ps.tcl — 按 Milianke7x 官方预设补齐剩余配置（QSPI/SD1-EMMC/ENET复位/DDR训练/MIO GPIO）
set out [open {E:/yoloProject/vivado_projects/yoloproject/finalize_ps.log} w]
proc L {msg} { global out; puts $out $msg; puts $msg; flush $out }
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
set bd [lindex [get_files -filter {FILE_TYPE == "Block Designs"}] 0]
open_bd_design $bd
set ps7 [get_bd_cells /processing_system7_0]

set err 0
foreach {k v} [list \
  PCW_QSPI_PERIPHERAL_ENABLE      {1} \
  PCW_QSPI_QSPI_IO                {MIO 1 .. 6} \
  PCW_QSPI_GRP_SINGLE_SS_ENABLE   {1} \
  PCW_QSPI_GRP_SINGLE_SS_IO       {MIO 1 .. 6} \
  PCW_SINGLE_QSPI_DATA_MODE       {x4} \
  PCW_QSPI_GRP_FBCLK_ENABLE       {1} \
  PCW_QSPI_GRP_FBCLK_IO           {MIO 8} \
  PCW_QSPI_PERIPHERAL_FREQMHZ     {125} \
  PCW_SD1_PERIPHERAL_ENABLE       {1} \
  PCW_SD1_SD1_IO                  {MIO 10 .. 15} \
  PCW_SD1_GRP_CD_ENABLE           {1} \
  PCW_SD1_GRP_CD_IO               {MIO 9} \
  PCW_ENET0_RESET_ENABLE          {1} \
  PCW_ENET0_RESET_IO              {MIO 51} \
  PCW_UIPARAM_DDR_MEMORY_TYPE     {DDR 3 (Low Voltage)} \
  PCW_UIPARAM_DDR_DEVICE_CAPACITY {4096 MBits} \
  PCW_UIPARAM_DDR_DRAM_WIDTH      {16 Bits} \
  PCW_UIPARAM_DDR_SPEED_BIN       {DDR3_1066F} \
  PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL {1} \
  PCW_UIPARAM_DDR_TRAIN_READ_GATE   {1} \
  PCW_UIPARAM_DDR_TRAIN_DATA_EYE    {1} \
  PCW_GPIO_MIO_GPIO_ENABLE        {1} \
  PCW_GPIO_MIO_GPIO_IO            {MIO} \
] {
  if {[catch {set_property CONFIG.$k $v $ps7} e]} {
    L "ERR  $k --> [string range $e 0 130]"
    incr err
  } else { L "SET  $k = $v" }
}

# 启动三要素 + 网口回归检查
foreach {k exp} {PCW_UART1_PERIPHERAL_ENABLE 1 PCW_SD0_PERIPHERAL_ENABLE 1 \
  PCW_ENET0_PERIPHERAL_ENABLE 1 PCW_ENET0_GRP_MDIO_ENABLE 1 \
  PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} PCW_SD0_GRP_CD_IO {MIO 47} \
  PCW_UIPARAM_DDR_PARTNO {MT41K256M16 RE-125} PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V}} {
  set cur [get_property CONFIG.$k $ps7]
  if {$cur ne $exp} { L "REGRESS $k = $cur (期望 $exp)"; incr err } else { L "KEEP $k" }
}

if {[catch {validate_bd_design} e]} { L "VALIDATE FAIL: $e" } else { L "VALIDATE OK" }
if {[catch {generate_target all [get_files $bd]} e]} { L "gen ERR: $e" }
if {[catch {write_hwdef -force -file {E:/yoloProject/petalinux_projects/zturn_hw/design_1_wrapper_fixed.hdf}} e]} { L "write ERR: $e" } else { L "write OK" }
save_bd_design
close_project
L "DONE err=$err"
close $out
exit
