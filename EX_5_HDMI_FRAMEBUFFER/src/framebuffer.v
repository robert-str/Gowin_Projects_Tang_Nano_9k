// ============================================================================
// MODULO: framebuffer
// DESCRIPTION: Simple synchronous framebuffer stored in BRAM.
//
// Pixel format: RGB332 (8-bit)
//
// One clock latency on read.
// ============================================================================

module framebuffer #( 
    parameter int FRAME_SIZE = 19200,
    parameter int ADDR_BITS  = $clog2(FRAME_SIZE), 

    parameter string MEM_FILE = ""
)(
    input logic clk, rst_n,

    input logic [ADDR_BITS-1:0] rd_addr,
    output logic [7:0] rd_data,

    input logic wr_en,
    input logic [ADDR_BITS-1:0] wr_addr,
    input logic [7:0] wr_data
);

        Gowin_SP ram(
        .dout(rd_data), //output [7:0] dout
        .clk(clk), //input clk
        .oce(1'b1), //input oce
        .ce(1'b1), //input ce
        .reset(~rst_n), //input reset
        .wre(wr_en), //input wre
        .ad(rd_addr), //input [14:0] ad
        .din(wr_data) //input [7:0] din  
    );
    
    /*always_ff @(posedge clk) begin

        if (wr_en)//to overwrite the memory
            mem[wr_addr] <= wr_data;

        rd_data <= mem[rd_addr];  //Store the pixel value in RGB332 format in rd_data
    end*/

endmodule