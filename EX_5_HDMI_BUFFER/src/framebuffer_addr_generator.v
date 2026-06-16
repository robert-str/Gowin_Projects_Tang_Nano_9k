// ============================================================================
// MODULE: framebuffer_addr_gen.sv
// DESCRIPTION: Converts (cx, cy) coordinates into framebuffer linear address.
//
// addr = cy * H_ACTIVE + cx
// ============================================================================

/*module framebuffer_addr_gen #(
    parameter int H_ACTIVE = 320,
    parameter int V_ACTIVE = 240,

    parameter int H_BITS = $clog2(H_ACTIVE),
    parameter int V_BITS = $clog2(V_ACTIVE),

    parameter int FRAME_SIZE = H_ACTIVE * V_ACTIVE,
    parameter int ADDR_BITS  = $clog2(FRAME_SIZE)
)(
    input  logic [H_BITS-1:0] cx,
    input  logic [V_BITS-1:0] cy,

    output logic [ADDR_BITS-1:0] addr
);

    always_comb begin
        addr = (cy * H_ACTIVE) + cx;
    end

endmodule*/

module framebuffer_addr_gen #(
    parameter int H_ACTIVE = 640,
    parameter int V_ACTIVE = 480,

    parameter int SCALE = 4,

    parameter int FB_WIDTH  = H_ACTIVE / SCALE,
    parameter int FB_HEIGHT = V_ACTIVE / SCALE,

    parameter int H_BITS = $clog2(H_ACTIVE),
    parameter int V_BITS = $clog2(V_ACTIVE),

    parameter int FRAME_SIZE = FB_WIDTH * FB_HEIGHT,
    parameter int ADDR_BITS  = $clog2(FRAME_SIZE)
)(
    input  logic [H_BITS-1:0] cx,
    input  logic [V_BITS-1:0] cy,

    output logic [ADDR_BITS-1:0] addr
);

    logic [$clog2(FB_WIDTH)-1:0]  virtual_x;
    logic [$clog2(FB_HEIGHT)-1:0] virtual_y;

    always_comb begin

        // divide by SCALE (must be power of 2)
        virtual_x = cx >> $clog2(SCALE);
        virtual_y = cy >> $clog2(SCALE);

        addr = (virtual_y * FB_WIDTH) + virtual_x;
    end

endmodule