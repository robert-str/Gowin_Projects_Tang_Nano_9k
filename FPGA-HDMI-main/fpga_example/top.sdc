
create_clock -name clk27  -period 37.037 [get_ports {clk}]

create_clock -name clk125 -period  8.000 [get_nets {pclk_x5}]

set_clock_groups -asynchronous -group {clk27} -group {clk125}
