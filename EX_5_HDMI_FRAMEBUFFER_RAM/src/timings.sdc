# 1. Set the input clock on the port
create_clock -name clk_27MHz -period 37.037 [get_ports {clk_27MHz}]

# 2. Set the TMDS clock by connecting to the 'clk_tmds' signal (net) instead of the pin
create_generated_clock -name clk_tmds -source [get_ports {clk_27MHz}] -multiply_by 14 -divide_by 3 [get_nets {clk_tmds}]

# 3. Set the pixel clock by targeting the 'clk_pixel' net
create_generated_clock -name clk_pixel -source [get_nets {clk_tmds}] -divide_by 5 [get_nets {clk_pixel}]