# BD surgery: connect axi_vdma_0/S_AXI_LITE to the GP0 interconnect so software
# can program the VDMA. Current topology: PS M_AXI_GP0 -> axi_smc(S00) -> dpu_eu/S_AXI.
# Plan: axi_smc NUM_SI 1->2, NUM_CLOCKS 1->2; VDMA LITE -> S01_AXI on clk_out1 domain
# (VDMA s_axi_lite_aclk = clk_out1 100MHz, camera domain); assign 0x43C00000 / 64K.
open_project {E:/yoloProject/vivado_projects/yoloproject/yoloproject.xpr}
open_bd_design [get_files design_1.bd]

# sanity dump
puts "BEFORE: axi_smc NUM_SI=[get_property CONFIG.NUM_SI [get_bd_cells axi_smc]] NUM_CLKS=[get_property CONFIG.NUM_CLOCKS [get_bd_cells axi_smc]]"

# 1) widen smartconnect
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_CLOCKS {2}] [get_bd_cells axi_smc]
catch { set_property CONFIG.S01_HAS_REGSLICE {1} [get_bd_cells axi_smc] }
# associate clocks: aclk = FCLK0 domain (S00=dpu ctrl), new clock = clk_out1 (S01=vdma ctrl)
catch { set_property CONFIG.aclk_ASSOCIATED_BUSIF {S00_AXI} [get_bd_cells axi_smc] } e1
puts "assoc aclk: $e1"
catch { set_property CONFIG.aclk2_ASSOCIATED_BUSIF {S01_AXI} [get_bd_cells axi_smc] } e2
puts "assoc aclk2: $e2"
catch { set_property CONFIG.aclk1_ASSOCIATED_BUSIF {S01_AXI} [get_bd_cells axi_smc] } e3
puts "assoc aclk1: $e3"

# 2) wire new clock pin to clk_out1 (find the pin the re-customize created)
set clkpins [get_bd_pins -quiet -of_objects [get_bd_cells axi_smc] -filter {NAME =~ aclk*}]
foreach p $clkpins { puts "smc clk pin: $p  net=[get_bd_nets -quiet -of_objects [get_bd_pins $p]]" }
foreach p {aclk1 aclk2} {
    set cp [get_bd_pins -quiet -of_objects [get_bd_cells axi_smc] -filter "NAME == $p"]
    if {[llength $cp] && [llength [get_bd_nets -quiet -of_objects $cp]] == 0} {
        connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] $cp
        puts "connected $p <- clk_out1"
    }
}

# 3) connect VDMA LITE
set lite [get_bd_intf_pins -quiet axi_vdma_0/S_AXI_LITE]
if {[llength $lite] == 0} { puts "FATAL: no S_AXI_LITE pin on vdma"; exit 1 }
if {[llength [get_bd_intf_nets -quiet -of_objects $lite]] == 0} {
    connect_bd_intf_net [get_bd_intf_pins axi_vdma_0/S_AXI_LITE] [get_bd_intf_pins axi_smc/S01_AXI]
    puts "vdma LITE -> smc S01 connected"
} else { puts "vdma LITE already connected" }

# 4) validate, then assign address after validate materializes segs
if {[catch {validate_bd_design} v]} { puts "VALIDATE1_ERR: $v" }
set seg [get_bd_addr_segs -quiet axi_vdma_0/s_axi_lite/Reg]
puts "vdma seg: $seg"
if {[llength $seg]} {
    assign_bd_address -target_address_space /processing_system7_0/Data [get_bd_addr_segs $seg] -offset 0x43C00000 -range 64K
    puts "assigned 0x43C00000"
} else { puts "ADDR_SEG_MISSING" }
catch { validate_bd_design } v2
if {[string match "*ERROR*" $v2]} { puts "VALIDATE2_ERR: $v2" } else { puts "validate2 OK" }
save_bd_design
puts "BD_VDMA_LITE_DONE"
