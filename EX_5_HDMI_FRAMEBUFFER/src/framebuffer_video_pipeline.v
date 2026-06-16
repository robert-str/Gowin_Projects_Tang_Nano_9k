// ============================================================================
// MODULO: framebuffer_video_pipeline
// DESCRIPTION: Complete framebuffer video pipeline.
//
// Includes:
// - Address generation + upscaling
// - BRAM framebuffer
// - RGB332 -> RGB888 conversion
// - Pipeline synchronization
//
// IMPORTANT:
// BRAM read has 1 clock latency. Therefore sync signals MUST also be delayed.
// ============================================================================

module framebuffer_video_pipeline #(
    parameter int H_ACTIVE = 640,
    parameter int V_ACTIVE = 480,

    //Upscaling factor (must be power of 2)
    parameter int SCALE = 4,

    // Derived parameters
    parameter int H_BITS = $clog2(H_ACTIVE),
    parameter int V_BITS = $clog2(V_ACTIVE),

    // small virtual framebuffer
    parameter int FB_WIDTH  = H_ACTIVE/SCALE,  //160
    parameter int FB_HEIGHT = V_ACTIVE/SCALE,  //120

    parameter int FRAME_SIZE = FB_WIDTH * FB_HEIGHT,
    parameter int ADDR_BITS  = $clog2(FRAME_SIZE),

    parameter string MEM_FILE = ""
)(
    input logic clk,  //pixel clk
    input logic rst_n,

    input  logic [H_BITS-1:0] cx,
    input  logic [V_BITS-1:0] cy,

    input logic vde,

    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue
);

    // ============================================================
    // ADDRESS GENERATION + UPSCALING
    // ============================================================

    //linear framebuffer address
    logic [ADDR_BITS-1:0] fb_addr;

    // Virtual framebuffer coordinates
    logic [$clog2(FB_WIDTH)-1:0]  fb_x;
    logic [$clog2(FB_HEIGHT)-1:0] fb_y;

    always_comb begin
        // Upscaling using bit shift
        // Example with SCALE=4:
        // fb_x = cx >> 2;
        // fb_y = cy >> 2;
        // 0..3 → 0
        // 4..7 → 1 -> same pixel repeated four times
        fb_x = cx >> $clog2(SCALE);  
        fb_y = cy >> $clog2(SCALE);

        // Linear framebuffer address
        fb_addr = (fb_y * FB_WIDTH) + fb_x;
    end


    // ============================================================
    // FRAMEBUFFER
    // ============================================================

    logic [7:0] pixel_rgb332;

    framebuffer #(
        .FRAME_SIZE(FRAME_SIZE),  
        .ADDR_BITS (ADDR_BITS),
        .MEM_FILE  (MEM_FILE)
    ) fb (
        .clk(clk), .rst_n(rst_n),

        .rd_addr(fb_addr), //introduces a latency clock
        .rd_data(pixel_rgb332),

        .wr_en(1'b0),      //to overwrite memory
        .wr_addr('0),
        .wr_data('0)
    );

    /*TEST ROSSO
      always_ff @(posedge clk) begin
        pixel_rgb332 <= 8'hF0;
      end*/

    // ============================================================
    // PIPELINE DELAY
    // ============================================================

    logic vde_d;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            vde_d <= 1'b0;
        else
            vde_d <= vde;
    end

    // ============================================================
    // RGB332 -> RGB888
    // ============================================================

    logic [7:0] r_tmp;
    logic [7:0] g_tmp;
    logic [7:0] b_tmp;

    rgb332_to_rgb888 rgb_conv (
        .pixel_in(pixel_rgb332),

        .red(r_tmp),
        .green(g_tmp),
        .blue(b_tmp)
    );

    // ============================================================
    // OUTPUT
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            red   <= '0;
            green <= '0;
            blue  <= '0;
        end
        else begin
            if (vde_d) begin  //video mode
                red   <= r_tmp;
                green <= g_tmp;
                blue  <= b_tmp;
            end
            else begin       //blanking mode
                red   <= '0;
                green <= '0;
                blue  <= '0;
            end
        end
    end

endmodule