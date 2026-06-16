module tb_hdmi_top;

    logic clk;
    logic rst_n;

    logic [7:0] red;
    logic [7:0] green;
    logic [7:0] blue;

    logic [9:0] cx;
    logic [9:0] cy;

    logic hsync;
    logic vsync;
    logic vde;

    // CLOCK
    initial clk = 0;
    always #20 clk = ~clk; // 25 MHz

    // VIDEO TIMING
    video_timing timing_inst (
        .clk(clk),
        .rst_n(rst_n),

        .cx(cx),
        .cy(cy),

        .hsync(hsync),
        .vsync(vsync),
        .vde(vde)
    );

    // FRAMEBUFFER PIPELINE
    framebuffer_video_pipeline #(
        .SCALE(4)
    ) fb_pipeline (

        .clk(clk),
        .rst_n(rst_n),

        .cx(cx),
        .cy(cy),

        .vde(vde),

        .red(red),
        .green(green),
        .blue(blue)
    );

endmodule