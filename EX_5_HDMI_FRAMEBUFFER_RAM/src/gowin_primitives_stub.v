// ======================================================
// 1. PLL (Gowin_rPLL)
// ======================================================
module Gowin_rPLL (
    input  wire clkin,
    input  wire reset,
    output wire clkout
);
    assign clkout = clkin;

endmodule


// ======================================================
// 2. CLKDIV (DIV_MODE = 5)
// divide by 5 using a real counter 
// ======================================================
module CLKDIV #(
    parameter DIV_MODE = "5",
    parameter GSREN = "false"
)(
    input  wire HCLKIN,
    input  wire RESETN,
    input  wire CALIB,
    output reg  CLKOUT
);

    integer cnt;

    initial begin
        cnt = 0;
        CLKOUT = 0;
    end

    always @(posedge HCLKIN or negedge RESETN) begin
        if (!RESETN) begin
            cnt <= 0;
            CLKOUT <= 0;
        end else begin
            cnt <= cnt + 1;
            if (cnt == 2) begin
                CLKOUT <= ~CLKOUT;
                cnt <= 0;
            end
        end
    end

endmodule


// ======================================================
// 3. ELVDS_OBUF (differential output buffer)
// HDMI differential pair simulation
// ======================================================
module ELVDS_OBUF (
    input  wire I,
    output wire O,
    output wire OB
);

    assign O  = I;
    assign OB = ~I;

endmodule


// ======================================================
// 4. OSER10 (10:1 serializer)
// serializes 10-bit word into bitstream
// ======================================================
module OSER10 (
    input  wire PCLK,
    input  wire FCLK,
    input  wire RESET,

    input  wire D0,
    input  wire D1,
    input  wire D2,
    input  wire D3,
    input  wire D4,
    input  wire D5,
    input  wire D6,
    input  wire D7,
    input  wire D8,
    input  wire D9,

    output reg Q
);

    reg [9:0] shift;
    integer idx;

    // Loading parallel word
    always @(posedge PCLK or posedge RESET) begin
        if (RESET) begin
            shift <= 10'd0;
        end else begin
            shift <= {D9, D8, D7, D6, D5, D4, D3, D2, D1, D0};
        end
    end

    // Serialisation
    always @(posedge FCLK or posedge RESET) begin
        if (RESET) begin
            Q   <= 1'b0;
            idx <= 0;
        end else begin
            Q <= shift[idx];

            if (idx == 9) begin
                idx <= 0;
            end else begin
                idx <= idx + 1;
            end
        end
    end

endmodule


// ======================================================
// 5. Gowin_SP (Single Port RAM)
// FPGA block RAM behavioral model
// ======================================================
module Gowin_SP (
    input  wire clk,
    input  wire oce,
    input  wire ce,
    input  wire reset,
    input  wire wre,
    input  wire [15:0] ad,
    input  wire [7:0] din,
    output reg  [7:0] dout
);

    reg [7:0] mem [0:65535];
    integer i;

    initial begin
        dout = 8'h00;

        // RAM initialisation for simulation
        for (i = 0; i < 65536; i = i + 1) begin
            mem[i] = 8'h00;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            dout <= 8'h00;
        end else if (ce) begin

            // Single-port RAM:
            // if wre=1, writes to the address ad
            if (wre) begin
                mem[ad] <= din;
            end

            // Synchronous reading
            if (oce) begin
                dout <= mem[ad];
            end
        end
    end


endmodule


// ======================================================
// 6. CLKDIV alternative alias safety (if design uses variants)
// ======================================================
module clkdiv (
    input HCLKIN,
    output CLKOUT
);
    assign CLKOUT = HCLKIN;
endmodule


// ======================================================
// 7. MUX2 (often used internally)
// ======================================================
module MUX2 (
    input a,
    input b,
    input sel,
    output y
);
    assign y = sel ? b : a;
endmodule


// ======================================================
// 8. DFFE (flip-flop enable)
// ======================================================
module DFFE (
    input d,
    input clk,
    input ce,
    output reg q
);

    always @(posedge clk)
        if (ce)
            q <= d;

endmodule