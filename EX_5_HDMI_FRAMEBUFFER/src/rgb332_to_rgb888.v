// ============================================================================
// MODULE: rgb332_to_rgb888
// DESCRIPTION: Converts RGB332 pixel format to RGB888.
// RGB332:
// [7:5] = RED   (3 bits)
// [4:2] = GREEN (3 bits)
// [1:0] = BLUE  (2 bits)
// ============================================================================

module rgb332_to_rgb888(
    input  logic [7:0] pixel_in,

    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue
);

    always_comb begin

        // RED 3-bit -> 8-bit
        red = {
            pixel_in[7:5],
            pixel_in[7:5],
            pixel_in[7:6]
        };

        // GREEN 3-bit -> 8-bit
        green = {
            pixel_in[4:2],
            pixel_in[4:2],
            pixel_in[4:3]
        };

        // BLUE 2-bit -> 8-bit
        blue = {
            pixel_in[1:0],
            pixel_in[1:0],
            pixel_in[1:0],
            pixel_in[1:0]
        };
    end

endmodule