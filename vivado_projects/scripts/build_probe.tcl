# build_probe.tcl -- camera diagnostic probe bitstream (incremental-safe)
# Vivado 2019.1, xc7z020clg400-2 (MZQ7X). PS7 present only to provide
# M_AXI_GP0 + FCLK0 (bitstream is hot-loaded via fpga_manager at runtime).
# Re-running opens the existing project and reuses finished OOC runs.
set script_dir [file dirname [file normalize [info script]]]
set out_dir    E:/yoloProject/vivado_projects/probe
set rtl_dir    E:/yoloProject/rtl/probe
set xpr        $out_dir/probe.xpr

if { [file exists $xpr] } {
    puts "REOPEN existing project"
    open_project $xpr
    # update gpio1 CH1 width to 2 (bit0 xclk_en, bit1 i2c_en) if needed
    open_bd_design [get_files probe_bd.bd]
    if {[get_property CONFIG.C_GPIO_WIDTH [get_bd_cells gpio1]] != 2} {
        set_property CONFIG.C_GPIO_WIDTH {2} [get_bd_cells gpio1]
        puts "gpio1 width updated to 2"
    }
    validate_bd_design
    save_bd_design
    close_bd_design [current_bd_design]
    # force-regenerate the HDL wrapper so port widths match the BD
    set old_wrap [get_files -quiet */probe_bd_wrapper.v]
    if {[llength $old_wrap]} { export_ip_user_files -of_objects [get_files probe_bd.bd] -no_script -sync -force -quiet }
    make_wrapper -files [get_files probe_bd.bd] -top -force
    puts "wrapper regenerated"
    # ensure the production I2C master sources are in the project
    foreach f [list E:/yoloProject/rtl/i2c_timing_ctrl_reg16_dat8_wronly.v \
                    E:/yoloProject/rtl/I2C_OV5640_1280720_Config.v \
                    E:/yoloProject/rtl/probe/i2c_timing_ctrl_ack.v] {
        if {[catch {get_files -quiet $f} fl] || [llength $fl] == 0} {
            add_files -norecurse $f
            puts "added source: $f"
        }
    }
} else {
    file mkdir $out_dir
    create_project probe $out_dir -part xc7z020clg400-2

    #---------------- Block design: PS7 + 2x AXI GPIO ----------------
    create_bd_design "probe_bd"

    create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7
    set_property -dict [list \
        CONFIG.PCW_USE_M_AXI_GP0 {1} \
        CONFIG.PCW_EN_CLK0_PORT {1} \
        CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
    ] [get_bd_cells ps7]

    # gpio0 @0x41200000: CH1 = 32b input (snapshot), CH2 = 2b tri-state (SCL/SDA)
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 gpio0
    set_property -dict [list \
        CONFIG.C_IS_DUAL {1} \
        CONFIG.C_GPIO_WIDTH {32} \
        CONFIG.C_ALL_INPUTS {1} \
        CONFIG.C_GPIO2_WIDTH {2} \
    ] [get_bd_cells gpio0]

    # gpio1 @0x41210000: CH1 = 2b output (xclk gate + scan arm), CH2 = 32b input (edge counter)
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 gpio1
    set_property -dict [list \
        CONFIG.C_IS_DUAL {1} \
        CONFIG.C_GPIO_WIDTH {2} \
        CONFIG.C_GPIO2_WIDTH {32} \
        CONFIG.C_ALL_INPUTS_2 {1} \
    ] [get_bd_cells gpio1]

    # AXI interconnect GP0 -> 2 slaves
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic
    set_property -dict [list CONFIG.NUM_MI {2} CONFIG.NUM_SI {1}] [get_bd_cells axi_ic]
    connect_bd_intf_net [get_bd_intf_pins ps7/M_AXI_GP0]  [get_bd_intf_pins axi_ic/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins axi_ic/M00_AXI] [get_bd_intf_pins gpio0/S_AXI]
    connect_bd_intf_net [get_bd_intf_pins axi_ic/M01_AXI] [get_bd_intf_pins gpio1/S_AXI]

    # clocks / resets
    create_bd_port -dir O ACLK
    create_bd_port -dir O -type rst ARESETN
    connect_bd_net [get_bd_pins ps7/FCLK_CLK0]     [get_bd_ports ACLK]
    connect_bd_net [get_bd_pins ps7/FCLK_RESET0_N] [get_bd_ports ARESETN]
    connect_bd_net [get_bd_ports ACLK]   [get_bd_pins ps7/M_AXI_GP0_ACLK]
    connect_bd_net [get_bd_ports ACLK]   [get_bd_pins axi_ic/ACLK]
    connect_bd_net [get_bd_ports ACLK]   [get_bd_pins axi_ic/S00_ACLK]
    connect_bd_net [get_bd_ports ACLK]   [get_bd_pins axi_ic/M00_ACLK]
    connect_bd_net [get_bd_ports ACLK]   [get_bd_pins axi_ic/M01_ACLK]
    connect_bd_net [get_bd_ports ACLK]   [get_bd_pins gpio0/s_axi_aclk]
    connect_bd_net [get_bd_ports ACLK]   [get_bd_pins gpio1/s_axi_aclk]
    connect_bd_net [get_bd_ports ARESETN] [get_bd_pins axi_ic/ARESETN]
    connect_bd_net [get_bd_ports ARESETN] [get_bd_pins axi_ic/S00_ARESETN]
    connect_bd_net [get_bd_ports ARESETN] [get_bd_pins axi_ic/M00_ARESETN]
    connect_bd_net [get_bd_ports ARESETN] [get_bd_pins axi_ic/M01_ARESETN]
    connect_bd_net [get_bd_ports ARESETN] [get_bd_pins gpio0/s_axi_aresetn]
    connect_bd_net [get_bd_ports ARESETN] [get_bd_pins gpio1/s_axi_aresetn]

    # gpio0 CH1 input port
    create_bd_port -dir I -from 31 -to 0 ch1_drv
    connect_bd_net [get_bd_ports ch1_drv] [get_bd_pins gpio0/gpio_io_i]
    # gpio0 CH2 tri-state ports (SCL/SDA)
    create_bd_port -dir I -from 1 -to 0 ch2_i
    create_bd_port -dir O -from 1 -to 0 ch2_o
    create_bd_port -dir O -from 1 -to 0 ch2_t
    connect_bd_net [get_bd_ports ch2_i] [get_bd_pins gpio0/gpio2_io_i]
    connect_bd_net [get_bd_ports ch2_o] [get_bd_pins gpio0/gpio2_io_o]
    connect_bd_net [get_bd_ports ch2_t] [get_bd_pins gpio0/gpio2_io_t]
    # gpio1 CH1 output port (xclk gate)
    create_bd_port -dir O xclk_en
    connect_bd_net [get_bd_ports xclk_en] [get_bd_pins gpio1/gpio_io_o]
    # gpio1 CH2 input port (edge counter)
    create_bd_port -dir I -from 31 -to 0 cnt2_in
    connect_bd_net [get_bd_ports cnt2_in] [get_bd_pins gpio1/gpio2_io_i]

    assign_bd_address
    foreach s [get_bd_addr_segs -of_objects [get_bd_addr_spaces ps7/Data]] {
        puts "PROBE_SEG: $s @ [get_property OFFSET $s]"
    }
    validate_bd_design
    save_bd_design
    make_wrapper -files [get_files probe_bd.bd] -top
    add_files -norecurse $out_dir/probe.srcs/sources_1/bd/probe_bd/hdl/probe_bd_wrapper.v
    add_files -norecurse $rtl_dir/probe_top.v
    add_files -fileset constrs_1 -norecurse $script_dir/probe.xdc
}

#---------------- common: ensure all RTL sources present ----------------
foreach f [list E:/yoloProject/rtl/probe/probe_top.v \
                E:/yoloProject/rtl/probe/i2c_timing_ctrl_ack.v \
                E:/yoloProject/rtl/i2c_timing_ctrl_reg16_dat8_wronly.v \
                E:/yoloProject/rtl/I2C_OV5640_1280720_Config.v] {
    if {[catch {get_files -quiet $f} fl] || [llength $fl] == 0} {
        add_files -norecurse $f
        puts "added source: $f"
    }
}

#---------------- build (incremental) ----------------
update_compile_order -fileset sources_1
set_property top probe_top [current_fileset]
reset_runs synth_1
launch_runs synth_1 -jobs 2
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} { puts "SYNTH FAILED"; exit 1 }
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} { puts "IMPL FAILED"; exit 1 }

set bit [file join $out_dir probe.runs impl_1 probe_top.bit]
puts "PROBE_BIT=$bit"
file copy -force $bit E:/yoloProject/web/probe.bit
puts "PROBE BUILD DONE"
