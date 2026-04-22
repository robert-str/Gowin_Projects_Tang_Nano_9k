module led_counter
(
    input clk,
    output [5:0] led
);

localparam WAIT_TIME = 13500000; //Tclk=37ns, if we want to increment the counter, we need to wait 0.5s/37ns = 13,500,000 clock cycles
reg [5:0] ledCounter = 0;
reg [23:0] clockCounter = 0;

always @(posedge clk) begin
    clockCounter <= clockCounter + 1;
    if (clockCounter == WAIT_TIME) begin
        clockCounter <= 0;
        ledCounter <= ledCounter + 1;
    end
end

assign led = ~ledCounter; 
endmodule