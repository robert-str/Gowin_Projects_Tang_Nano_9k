// ============================================================================
// MODULE: framebuffer.sv
// DESCRIPTION: Simple single-port framebuffer memory.
// Stores one RGB332 pixel per address (8 bit/pixel).
//
// Memory organization:
// pixel = { R[7:5], G[4:2], B[1:0] }
//
// Example:
// 111_000_00 = bright red
// 000_111_00 = bright green
// 000_000_11 = bright blue
// ============================================================================

module framebuffer #(
    parameter int H_ACTIVE = 160,
    parameter int V_ACTIVE = 120,

    parameter int FRAME_SIZE = H_ACTIVE * V_ACTIVE,
    parameter int ADDR_BITS  = $clog2(FRAME_SIZE),

    // Optional memory initialization file
    parameter string MEM_FILE = ""
)(
    input  logic clk,

    // READ PORT
    input  logic [ADDR_BITS-1:0] rd_addr,
    output logic [7:0] rd_data,

    // WRITE PORT
    input  logic                  wr_en,
    input  logic [ADDR_BITS-1:0]  wr_addr,
    input  logic [7:0]            wr_data
);

    // ------------------------------------------------------------------------
    // Framebuffer memory
    // ------------------------------------------------------------------------

    logic [7:0] mem [0:FRAME_SIZE-1];

    // ------------------------------------------------------------------------
    // Optional initialization
    // ------------------------------------------------------------------------

    initial begin
        if (MEM_FILE != "")
            $readmemh(MEM_FILE, mem);
    end

    // ------------------------------------------------------------------------
    // Synchronous RAM
    // ------------------------------------------------------------------------

    always_ff @(posedge clk) begin

        // WRITE
        if (wr_en)
            mem[wr_addr] <= wr_data;

        // READ
        rd_data <= mem[rd_addr];
    end

endmodule