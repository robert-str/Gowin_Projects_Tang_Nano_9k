 // ============================================================================
// MODULE: framebuffer_video_pipeline.sv
// DESCRIPTION: Complete framebuffer scanout pipeline.
// INPUT: cx/cy from video timing
// OUTPUT: RGB888 pixels for HDMI encoder
// ============================================================================

module framebuffer_video_pipeline #(
    parameter int H_ACTIVE = 640,
    parameter int V_ACTIVE = 480,
    
    // Inseriamo lo SCALE anche nel livello superiore
    parameter int SCALE = 4,
    parameter int FB_WIDTH  = H_ACTIVE / SCALE,
    parameter int FB_HEIGHT = V_ACTIVE / SCALE,

    // Ora la memoria totale è 160 * 120 = 19.200 (Entra nella Tang Nano!)
    parameter int FRAME_SIZE = FB_WIDTH * FB_HEIGHT, 
    parameter int ADDR_BITS  = $clog2(FRAME_SIZE),

    parameter int H_BITS = $clog2(H_ACTIVE),
    parameter int V_BITS = $clog2(V_ACTIVE),

    parameter string MEM_FILE = ""
)(
    input logic clk,
    input logic rst_n,

    // Current pixel coordinates (Monitor)
    input logic [H_BITS-1:0] cx,
    input logic [V_BITS-1:0] cy,
    input logic vde,

    // RGB output
    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue
);

    // ------------------------------------------------------------------------
    // Address generation
    // ------------------------------------------------------------------------
    logic [ADDR_BITS-1:0] fb_addr;

    framebuffer_addr_gen #(
        .H_ACTIVE(H_ACTIVE),
        .V_ACTIVE(V_ACTIVE),
        .SCALE(SCALE) // Passiamo la scala al modulo!
    ) addr_gen (
        .cx(cx),
        .cy(cy),
        .addr(fb_addr)
    );

    // ------------------------------------------------------------------------
    // Framebuffer read
    // ------------------------------------------------------------------------
    logic [7:0] pixel_rgb332;

    framebuffer #(
        // ATTENZIONE: Passiamo le dimensioni SCALATE, non quelle del monitor!
        .H_ACTIVE(FB_WIDTH),  // 160
        .V_ACTIVE(FB_HEIGHT), // 120
        .MEM_FILE(MEM_FILE)
    ) fb (
        .clk(clk),
        .rd_addr(fb_addr),
        .rd_data(pixel_rgb332),

        // no writes for now
        .wr_en(1'b0),
        .wr_addr('0),
        .wr_data('0)
    );

    // ------------------------------------------------------------------------
    // RGB332 -> RGB888
    // ------------------------------------------------------------------------
    logic [7:0] r_tmp;
    logic [7:0] g_tmp;
    logic [7:0] b_tmp;

    rgb332_to_rgb888 rgb_conv (
        .pixel_in(pixel_rgb332),
        .red(r_tmp),
        .green(g_tmp),
        .blue(b_tmp)
    );

    // ------------------------------------------------------------------------
    // Output register
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            red   <= 8'h00;
            green <= 8'h00;
            blue  <= 8'h00;
        end
        else begin
            if (vde) begin
                red   <= r_tmp;
                green <= g_tmp;
                blue  <= b_tmp;
            end
            else begin
                red   <= 8'h00;
                green <= 8'h00;
                blue  <= 8'h00;
            end
        end
    end
endmodule

/*module framebuffer_video_pipeline #(
    parameter int H_ACTIVE = 320,
    parameter int V_ACTIVE = 240,

    parameter int FRAME_SIZE = H_ACTIVE * V_ACTIVE,
    parameter int ADDR_BITS  = $clog2(FRAME_SIZE),

    parameter int H_BITS = $clog2(H_ACTIVE),
    parameter int V_BITS = $clog2(V_ACTIVE),

    parameter string MEM_FILE = ""
)(
    input logic clk,
    input logic rst_n,

    // Current pixel coordinates
    input logic [H_BITS-1:0] cx,
    input logic [V_BITS-1:0] cy,

    input logic vde,

    // RGB output
    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue
);

    // ------------------------------------------------------------------------
    // Address generation
    // ------------------------------------------------------------------------

    logic [ADDR_BITS-1:0] fb_addr;

    framebuffer_addr_gen #(
        .H_ACTIVE(H_ACTIVE),
        .V_ACTIVE(V_ACTIVE)
    ) addr_gen (
        .cx(cx),
        .cy(cy),
        .addr(fb_addr)
    );

    // ------------------------------------------------------------------------
    // Framebuffer read
    // ------------------------------------------------------------------------

    logic [7:0] pixel_rgb332;

    framebuffer #(
        .H_ACTIVE(H_ACTIVE),
        .V_ACTIVE(V_ACTIVE),
        .MEM_FILE(MEM_FILE)
    ) fb (
        .clk(clk),

        .rd_addr(fb_addr),
        .rd_data(pixel_rgb332),

        // no writes for now
        .wr_en(1'b0),
        .wr_addr('0),
        .wr_data('0)
    );

    // ------------------------------------------------------------------------
    // RGB332 -> RGB888
    // ------------------------------------------------------------------------

    logic [7:0] r_tmp;
    logic [7:0] g_tmp;
    logic [7:0] b_tmp;

    rgb332_to_rgb888 rgb_conv (
        .pixel_in(pixel_rgb332),

        .red(r_tmp),
        .green(g_tmp),
        .blue(b_tmp)
    );

    // ------------------------------------------------------------------------
    // Output register
    // ------------------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            red   <= 8'h00;
            green <= 8'h00;
            blue  <= 8'h00;
        end
        else begin
            if (vde) begin
                red   <= r_tmp;
                green <= g_tmp;
                blue  <= b_tmp;
            end
            else begin
                red   <= 8'h00;
                green <= 8'h00;
                blue  <= 8'h00;
            end
        end
    end
endmodule*/