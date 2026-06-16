// ============================================================================
// MODULO: framebuffer_video_pipeline
// DESCRIPTION:
// Dynamic framebuffer using SINGLE PORT RAM.
//
// Technique:
// - Read framebuffer only every SCALE clocks
// - Reuse cached pixel during idle cycles
// - Use idle cycles to WRITE new framebuffer data
//
// This allows simultaneous video output + framebuffer update
// using only ONE single-port BRAM.
// ============================================================================

module framebuffer_video_pipeline #(
    parameter int H_ACTIVE = 640,
    parameter int V_ACTIVE = 480,

    // Upscaling factor
    parameter int SCALE = 4,

    // Derived parameters
    parameter int H_BITS = $clog2(H_ACTIVE),
    parameter int V_BITS = $clog2(V_ACTIVE),

    // Small framebuffer
    parameter int FB_WIDTH  = H_ACTIVE / SCALE,   // 160
    parameter int FB_HEIGHT = V_ACTIVE / SCALE,   // 120
    parameter int FRAME_SIZE = FB_WIDTH * FB_HEIGHT,
    parameter int ADDR_BITS  = $clog2(FRAME_SIZE)
)(
    input logic clk,
    input logic rst_n,

    input logic [H_BITS-1:0] cx,
    input logic [V_BITS-1:0] cy,

    input logic vde,

    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue
);

    // =========================================================================
    // FRAMEBUFFER COORDINATES
    // =========================================================================
    logic [$clog2(FB_WIDTH)-1:0]  fb_x;
    logic [$clog2(FB_HEIGHT)-1:0] fb_y;
    logic [ADDR_BITS-1:0] fb_addr;

    localparam int SCALE_BITS = $clog2(SCALE);

    always_comb begin
        // Upscaling 4x
        fb_x = cx >> SCALE_BITS;
        fb_y = cy >> SCALE_BITS;

        fb_addr = (fb_y * FB_WIDTH) + fb_x;
    end

    // =========================================================================
    // READ ONLY EVERY 4 PIXELS
    // =========================================================================
    logic read_cycle;

    //The framebuffer read cycle only occurs when we are within the vde and when cx is a multiple of SCALE
    assign read_cycle = vde && (cx[SCALE_BITS-1:0] == '0);

    // =========================================================================
    // RAM INTERFACE
    // =========================================================================
    logic [ADDR_BITS-1:0] ram_addr;
    logic [7:0]           ram_dout;
    logic                 ram_wre;
    logic [7:0]           ram_din;

    // =========================================================================
    // PIXEL CACHE
    // =========================================================================
    logic [7:0] cached_pixel;   //last RGB332 pixel read from RAM

    // =========================================================================
    // DYNAMIC FRAMEBUFFER WRITER: continuously writes a moving color pattern
    // =========================================================================

    logic [ADDR_BITS-1:0]  wr_ptr;         //framebuffer write pointer
    logic [7:0]            frame_counter;

    logic [7:0]    pattern_pixel;

    always_comb begin
        case ((frame_counter / 8'd60) & 2'b11)
            2'b00: pattern_pixel = 8'b11100000; // RED
            2'b01: pattern_pixel = 8'b00011100; // GREEN
            2'b10: pattern_pixel = 8'b00000011; // BLUE
            2'b11: pattern_pixel = 8'b11111111; // WHITE
            default: pattern_pixel = 8'b00000000;
        endcase
    end

    // =========================================================================
    // RAM ACCESS MULTIPLEXER
    // If we are in the read_cycle during the visible area:
    //   - read fb_addr
    //
    // Otherwise:
    //   - write pattern_pixel to wr_ptr
    // =========================================================================

    always_comb begin
        if (read_cycle) begin
            ram_wre  = 1'b0;
            ram_addr = fb_addr;
            ram_din  = 8'h00;
        end else begin
            ram_wre  = 1'b1;
            ram_addr = wr_ptr;
            ram_din  = pattern_pixel;
        end
    end

    // =========================================================================
    // FRAME COUNTER AND WRITE POINTER
    // =========================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr        <= '0;
            frame_counter <= 8'd0;
        end else begin

            // Increase once at the start of the frame
            if ((cx == '0) && (cy == '0)) begin
                frame_counter <= frame_counter + 8'd1;
            end

            // Update the write pointer only when we are writing
            if (!read_cycle) begin
                if (wr_ptr == FRAME_SIZE - 1) begin
                    wr_ptr <= '0;
                end else begin
                    wr_ptr <= wr_ptr + 1'b1;
                end
            end
        end
    end

    // =========================================================================
    // SINGLE PORT RAM
    // =========================================================================
    framebuffer #(
        .FRAME_SIZE (FRAME_SIZE),
        .ADDR_BITS  (ADDR_BITS)
    ) fb (
        .clk     (clk),
        .rst_n   (rst_n),
        .addr    (ram_addr),
        .rd_data (ram_dout),
        .wr_en   (ram_wre),
        .wr_data (ram_din)
    );

    // =========================================================================
    // READ DATA CACHE
    // RAM is synchronous: the data being read arrives with a delay.
    // Update `cached_pixel` if a read operation was requested in the previous cycle
    // =========================================================================
    logic read_cycle_d;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_cycle_d <= 1'b0;
            cached_pixel <= 8'h00;
        end else begin
            read_cycle_d <= read_cycle;  //to synchronise

            if (read_cycle_d) begin
                cached_pixel <= ram_dout;
            end
        end
    end

    // =========================================================================
    // RGB332 -> RGB888
    // =========================================================================

    logic [7:0] r_tmp;
    logic [7:0] g_tmp;
    logic [7:0] b_tmp;

    rgb332_to_rgb888 rgb_conv (
        .pixel_in(cached_pixel),
        .red(r_tmp),
        .green(g_tmp),
        .blue(b_tmp)
    );

    // =========================================================================
    // OUTPUT RGB: Display the converted colour within the active area. Outside the active area, the colour is black.
    // =========================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            red   <= 8'h00;
            green <= 8'h00;
            blue  <= 8'h00;
        end else begin
            if (vde) begin
                red   <= r_tmp;
                green <= g_tmp;
                blue  <= b_tmp;
            end else begin
                red   <= 8'h00;
                green <= 8'h00;
                blue  <= 8'h00;
            end
        end
    end

endmodule