// ============================================================================
// MODULE: rgb332_to_rgb888.sv
// DESCRIPTION: Converts RGB332 pixel format into RGB888.
//
// INPUT FORMAT:
// [7:5] = RED   (3 bit)
// [4:2] = GREEN (3 bit)
// [1:0] = BLUE  (2 bit)
// ============================================================================

module rgb332_to_rgb888 (
    input  logic [7:0] pixel_in,

    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue
);

    logic [2:0] r3;
    logic [2:0] g3;
    logic [1:0] b2;

    always_comb begin

        // Extract fields
        r3 = pixel_in[7:5];
        g3 = pixel_in[4:2];
        b2 = pixel_in[1:0];

        // --------------------------------------------------------------------
        // Expand to 8 bit
        // Bit replication:
        // 3-bit:
        // abc -> abcabcab
        //
        // 2-bit:
        // ab -> abababab
        // --------------------------------------------------------------------

        red   = {r3, r3, r3[1:0]};
        green = {g3, g3, g3[1:0]};
        blue  = {b2, b2, b2, b2};
    end

endmodule