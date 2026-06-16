// ============================================================================
// MODULE: video_timing
// ============================================================================
module video_timing #(
    //default values
    parameter int H_ACTIVE   = 320,  
    parameter int H_FRONT    = 16,
    parameter int H_SYNC     = 48,
    parameter int H_BACK     = 16,

    parameter int V_ACTIVE   = 240,
    parameter int V_FRONT    = 10,
    parameter int V_SYNC     = 2,
    parameter int V_BACK     = 10,

    parameter int H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK,
    parameter int V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK,

    parameter bit H_SYNC_POL = 1'b0,
    parameter bit V_SYNC_POL = 1'b0,

    parameter int H_BITS = $clog2(H_TOTAL),
    parameter int V_BITS = $clog2(V_TOTAL)
)(
    input  logic clk, rst_n,
    output logic [H_BITS-1:0] cx,   //counter x
    output logic [V_BITS-1:0] cy,   //counter y
    output logic hsync, vsync, vde
);

    //internal signals
    logic hsync_int, vsync_int;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cx <= '0; cy <= '0;
        end 
        else begin
            if (cx == H_TOTAL - 1) begin
                cx <= '0;
                cy <= (cy == V_TOTAL - 1) ? '0 : cy + 1;
            end 
            else begin
                cx <= cx + 1;
            end
        end
    end

    // logic to decide when activate sync signals
    assign hsync_int  = (cx >= H_ACTIVE + H_FRONT) && (cx < H_ACTIVE + H_FRONT + H_SYNC);  
    assign vsync_int = (cy >= V_ACTIVE + V_FRONT) && (cy < V_ACTIVE + V_FRONT + V_SYNC);  

    //polarity depends on resolution
    assign hsync = H_SYNC_POL ? hsync_int : ~hsync_int;     //when next row
    assign vsync = V_SYNC_POL ? vsync_int : ~vsync_int;     //when next frame
    assign vde   = (cx < H_ACTIVE) && (cy < V_ACTIVE);      // Video Data Enable
endmodule

