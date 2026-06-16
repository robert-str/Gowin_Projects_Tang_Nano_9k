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

assign red   = {pixel_in[7:5], pixel_in[7:5], pixel_in[7:6]};   //red 3bit->8bit
assign green = {pixel_in[4:2], pixel_in[4:2], pixel_in[4:3]};   //green 3bit->8bit
assign blue  = {pixel_in[1:0], pixel_in[1:0], pixel_in[1:0], pixel_in[1:0]};  //blue 2bit->8bit

endmodule