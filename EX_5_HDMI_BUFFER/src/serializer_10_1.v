// ============================================================================
// MODULE: serializer_10to1 (High-speed shift register)
// ============================================================================
module serializer_10to1 (
    input  logic rst_n,
    input  logic clk_pixel,
    input  logic clk_tmds,
    input  logic [9:0] data_in,
    output logic serial_out
);

    OSER10 serializer (
    .Q(serial_out),     //Serial output connected to the physical HDMI pin
    .D0(data_in[0]),    // Parallel bits coming from the TMDS encoder...
    .D1(data_in[1]),
    .D2(data_in[2]),
    .D3(data_in[3]),
    .D4(data_in[4]),
    .D5(data_in[5]),
    .D6(data_in[6]),
    .D7(data_in[7]),
    .D8(data_in[8]),
    .D9(data_in[9]),
    .PCLK(clk_pixel),   // pixel clock
    .FCLK(clk_tmds),    // TMDS clock (= pixel clk x 5)
    .RESET(~rst_n)      // The OSER10 has a HIGH-active reset
     );

endmodule