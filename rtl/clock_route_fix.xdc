# clock_route_fix.xdc — FCLK->MMCM 直连的标准豁免（REQP-1578）
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets -filter {NAME =~ *clk_in1*}]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets -filter {NAME =~ *FCLK_CLK0*}]
