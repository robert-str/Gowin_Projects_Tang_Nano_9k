// ============================================================================
// MODULO: serializer_10to1 (Shift Register ad alta velocità)
// ============================================================================
module serializer_10to1 (
    input  logic rst_n,
    input  logic clk_pixel,
    input  logic clk_tmds,
    input  logic [9:0] data_in,
    output logic serial_out
);

    OSER10 serializer (
    .Q(serial_out), // L'uscita seriale che va al pin HDMI fisico (es. hdmi_tx0_p)
    .D0(data_in[0]),     // Bit paralleli in arrivo dall'encoder TMDS...
    .D1(data_in[1]),
    .D2(data_in[2]),
    .D3(data_in[3]),
    .D4(data_in[4]),
    .D5(data_in[5]),
    .D6(data_in[6]),
    .D7(data_in[7]),
    .D8(data_in[8]),
    .D9(data_in[9]),
    .PCLK(clk_pixel),   // Il clock "lento" a 1x (es. 25 MHz)
    .FCLK(clk_tmds),      // Il clock "veloce" a 10x (es. 125 MHz)
    .RESET(~rst_n)      // Attenzione: l'OSER10 ha il reset attivo ALTO
     );
endmodule