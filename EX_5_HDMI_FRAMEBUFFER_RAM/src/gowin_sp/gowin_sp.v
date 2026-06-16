//Copyright (C)2014-2026 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.12.02_SP1 (64-bit)
//IP Version: 1.0
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Tue May 19 18:39:25 2026

module Gowin_SP (dout, clk, oce, ce, reset, wre, ad, din);

output [7:0] dout;
input clk;
input oce;
input ce;
input reset;
input wre;
input [14:0] ad;
input [7:0] din;

wire [27:0] sp_inst_0_dout_w;
wire [3:0] sp_inst_0_dout;
wire [27:0] sp_inst_1_dout_w;
wire [3:0] sp_inst_1_dout;
wire [27:0] sp_inst_2_dout_w;
wire [3:0] sp_inst_2_dout;
wire [27:0] sp_inst_3_dout_w;
wire [3:0] sp_inst_3_dout;
wire [27:0] sp_inst_4_dout_w;
wire [3:0] sp_inst_4_dout;
wire [27:0] sp_inst_5_dout_w;
wire [7:4] sp_inst_5_dout;
wire [27:0] sp_inst_6_dout_w;
wire [7:4] sp_inst_6_dout;
wire [27:0] sp_inst_7_dout_w;
wire [7:4] sp_inst_7_dout;
wire [27:0] sp_inst_8_dout_w;
wire [7:4] sp_inst_8_dout;
wire [27:0] sp_inst_9_dout_w;
wire [7:4] sp_inst_9_dout;
wire dff_q_0;
wire dff_q_1;
wire dff_q_2;
wire mux_o_0;
wire mux_o_1;
wire mux_o_3;
wire mux_o_6;
wire mux_o_7;
wire mux_o_9;
wire mux_o_12;
wire mux_o_13;
wire mux_o_15;
wire mux_o_18;
wire mux_o_19;
wire mux_o_21;
wire mux_o_24;
wire mux_o_25;
wire mux_o_27;
wire mux_o_30;
wire mux_o_31;
wire mux_o_33;
wire mux_o_36;
wire mux_o_37;
wire mux_o_39;
wire mux_o_42;
wire mux_o_43;
wire mux_o_45;
wire ce_w;
wire gw_gnd;

assign ce_w = ~wre & ce;
assign gw_gnd = 1'b0;

SP sp_inst_0 (
    .DO({sp_inst_0_dout_w[27:0],sp_inst_0_dout[3:0]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .WRE(wre),
    .BLKSEL({ad[14],ad[13],ad[12]}),
    .AD({ad[11:0],gw_gnd,gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[3:0]})
);

defparam sp_inst_0.READ_MODE = 1'b0;
defparam sp_inst_0.WRITE_MODE = 2'b00;
defparam sp_inst_0.BIT_WIDTH = 4;
defparam sp_inst_0.BLK_SEL = 3'b000;
defparam sp_inst_0.RESET_MODE = "SYNC";

SP sp_inst_1 (
    .DO({sp_inst_1_dout_w[27:0],sp_inst_1_dout[3:0]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .WRE(wre),
    .BLKSEL({ad[14],ad[13],ad[12]}),
    .AD({ad[11:0],gw_gnd,gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[3:0]})
);

defparam sp_inst_1.READ_MODE = 1'b0;
defparam sp_inst_1.WRITE_MODE = 2'b00;
defparam sp_inst_1.BIT_WIDTH = 4;
defparam sp_inst_1.BLK_SEL = 3'b001;
defparam sp_inst_1.RESET_MODE = "SYNC";

SP sp_inst_2 (
    .DO({sp_inst_2_dout_w[27:0],sp_inst_2_dout[3:0]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .WRE(wre),
    .BLKSEL({ad[14],ad[13],ad[12]}),
    .AD({ad[11:0],gw_gnd,gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[3:0]})
);

defparam sp_inst_2.READ_MODE = 1'b0;
defparam sp_inst_2.WRITE_MODE = 2'b00;
defparam sp_inst_2.BIT_WIDTH = 4;
defparam sp_inst_2.BLK_SEL = 3'b010;
defparam sp_inst_2.RESET_MODE = "SYNC";

SP sp_inst_3 (
    .DO({sp_inst_3_dout_w[27:0],sp_inst_3_dout[3:0]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .WRE(wre),
    .BLKSEL({ad[14],ad[13],ad[12]}),
    .AD({ad[11:0],gw_gnd,gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[3:0]})
);

defparam sp_inst_3.READ_MODE = 1'b0;
defparam sp_inst_3.WRITE_MODE = 2'b00;
defparam sp_inst_3.BIT_WIDTH = 4;
defparam sp_inst_3.BLK_SEL = 3'b011;
defparam sp_inst_3.RESET_MODE = "SYNC";

SP sp_inst_4 (
    .DO({sp_inst_4_dout_w[27:0],sp_inst_4_dout[3:0]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .WRE(wre),
    .BLKSEL({ad[14],ad[13],ad[12]}),
    .AD({ad[11:0],gw_gnd,gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[3:0]})
);

defparam sp_inst_4.READ_MODE = 1'b0;
defparam sp_inst_4.WRITE_MODE = 2'b00;
defparam sp_inst_4.BIT_WIDTH = 4;
defparam sp_inst_4.BLK_SEL = 3'b100;
defparam sp_inst_4.RESET_MODE = "SYNC";

SP sp_inst_5 (
    .DO({sp_inst_5_dout_w[27:0],sp_inst_5_dout[7:4]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .WRE(wre),
    .BLKSEL({ad[14],ad[13],ad[12]}),
    .AD({ad[11:0],gw_gnd,gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[7:4]})
);

defparam sp_inst_5.READ_MODE = 1'b0;
defparam sp_inst_5.WRITE_MODE = 2'b00;
defparam sp_inst_5.BIT_WIDTH = 4;
defparam sp_inst_5.BLK_SEL = 3'b000;
defparam sp_inst_5.RESET_MODE = "SYNC";

SP sp_inst_6 (
    .DO({sp_inst_6_dout_w[27:0],sp_inst_6_dout[7:4]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .WRE(wre),
    .BLKSEL({ad[14],ad[13],ad[12]}),
    .AD({ad[11:0],gw_gnd,gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[7:4]})
);

defparam sp_inst_6.READ_MODE = 1'b0;
defparam sp_inst_6.WRITE_MODE = 2'b00;
defparam sp_inst_6.BIT_WIDTH = 4;
defparam sp_inst_6.BLK_SEL = 3'b001;
defparam sp_inst_6.RESET_MODE = "SYNC";

SP sp_inst_7 (
    .DO({sp_inst_7_dout_w[27:0],sp_inst_7_dout[7:4]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .WRE(wre),
    .BLKSEL({ad[14],ad[13],ad[12]}),
    .AD({ad[11:0],gw_gnd,gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[7:4]})
);

defparam sp_inst_7.READ_MODE = 1'b0;
defparam sp_inst_7.WRITE_MODE = 2'b00;
defparam sp_inst_7.BIT_WIDTH = 4;
defparam sp_inst_7.BLK_SEL = 3'b010;
defparam sp_inst_7.RESET_MODE = "SYNC";

SP sp_inst_8 (
    .DO({sp_inst_8_dout_w[27:0],sp_inst_8_dout[7:4]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .WRE(wre),
    .BLKSEL({ad[14],ad[13],ad[12]}),
    .AD({ad[11:0],gw_gnd,gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[7:4]})
);

defparam sp_inst_8.READ_MODE = 1'b0;
defparam sp_inst_8.WRITE_MODE = 2'b00;
defparam sp_inst_8.BIT_WIDTH = 4;
defparam sp_inst_8.BLK_SEL = 3'b011;
defparam sp_inst_8.RESET_MODE = "SYNC";

SP sp_inst_9 (
    .DO({sp_inst_9_dout_w[27:0],sp_inst_9_dout[7:4]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .WRE(wre),
    .BLKSEL({ad[14],ad[13],ad[12]}),
    .AD({ad[11:0],gw_gnd,gw_gnd}),
    .DI({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,din[7:4]})
);

defparam sp_inst_9.READ_MODE = 1'b0;
defparam sp_inst_9.WRITE_MODE = 2'b00;
defparam sp_inst_9.BIT_WIDTH = 4;
defparam sp_inst_9.BLK_SEL = 3'b100;
defparam sp_inst_9.RESET_MODE = "SYNC";

DFFE dff_inst_0 (
  .Q(dff_q_0),
  .D(ad[14]),
  .CLK(clk),
  .CE(ce_w)
);
DFFE dff_inst_1 (
  .Q(dff_q_1),
  .D(ad[13]),
  .CLK(clk),
  .CE(ce_w)
);
DFFE dff_inst_2 (
  .Q(dff_q_2),
  .D(ad[12]),
  .CLK(clk),
  .CE(ce_w)
);
MUX2 mux_inst_0 (
  .O(mux_o_0),
  .I0(sp_inst_0_dout[0]),
  .I1(sp_inst_1_dout[0]),
  .S0(dff_q_2)
);
MUX2 mux_inst_1 (
  .O(mux_o_1),
  .I0(sp_inst_2_dout[0]),
  .I1(sp_inst_3_dout[0]),
  .S0(dff_q_2)
);
MUX2 mux_inst_3 (
  .O(mux_o_3),
  .I0(mux_o_0),
  .I1(mux_o_1),
  .S0(dff_q_1)
);
MUX2 mux_inst_5 (
  .O(dout[0]),
  .I0(mux_o_3),
  .I1(sp_inst_4_dout[0]),
  .S0(dff_q_0)
);
MUX2 mux_inst_6 (
  .O(mux_o_6),
  .I0(sp_inst_0_dout[1]),
  .I1(sp_inst_1_dout[1]),
  .S0(dff_q_2)
);
MUX2 mux_inst_7 (
  .O(mux_o_7),
  .I0(sp_inst_2_dout[1]),
  .I1(sp_inst_3_dout[1]),
  .S0(dff_q_2)
);
MUX2 mux_inst_9 (
  .O(mux_o_9),
  .I0(mux_o_6),
  .I1(mux_o_7),
  .S0(dff_q_1)
);
MUX2 mux_inst_11 (
  .O(dout[1]),
  .I0(mux_o_9),
  .I1(sp_inst_4_dout[1]),
  .S0(dff_q_0)
);
MUX2 mux_inst_12 (
  .O(mux_o_12),
  .I0(sp_inst_0_dout[2]),
  .I1(sp_inst_1_dout[2]),
  .S0(dff_q_2)
);
MUX2 mux_inst_13 (
  .O(mux_o_13),
  .I0(sp_inst_2_dout[2]),
  .I1(sp_inst_3_dout[2]),
  .S0(dff_q_2)
);
MUX2 mux_inst_15 (
  .O(mux_o_15),
  .I0(mux_o_12),
  .I1(mux_o_13),
  .S0(dff_q_1)
);
MUX2 mux_inst_17 (
  .O(dout[2]),
  .I0(mux_o_15),
  .I1(sp_inst_4_dout[2]),
  .S0(dff_q_0)
);
MUX2 mux_inst_18 (
  .O(mux_o_18),
  .I0(sp_inst_0_dout[3]),
  .I1(sp_inst_1_dout[3]),
  .S0(dff_q_2)
);
MUX2 mux_inst_19 (
  .O(mux_o_19),
  .I0(sp_inst_2_dout[3]),
  .I1(sp_inst_3_dout[3]),
  .S0(dff_q_2)
);
MUX2 mux_inst_21 (
  .O(mux_o_21),
  .I0(mux_o_18),
  .I1(mux_o_19),
  .S0(dff_q_1)
);
MUX2 mux_inst_23 (
  .O(dout[3]),
  .I0(mux_o_21),
  .I1(sp_inst_4_dout[3]),
  .S0(dff_q_0)
);
MUX2 mux_inst_24 (
  .O(mux_o_24),
  .I0(sp_inst_5_dout[4]),
  .I1(sp_inst_6_dout[4]),
  .S0(dff_q_2)
);
MUX2 mux_inst_25 (
  .O(mux_o_25),
  .I0(sp_inst_7_dout[4]),
  .I1(sp_inst_8_dout[4]),
  .S0(dff_q_2)
);
MUX2 mux_inst_27 (
  .O(mux_o_27),
  .I0(mux_o_24),
  .I1(mux_o_25),
  .S0(dff_q_1)
);
MUX2 mux_inst_29 (
  .O(dout[4]),
  .I0(mux_o_27),
  .I1(sp_inst_9_dout[4]),
  .S0(dff_q_0)
);
MUX2 mux_inst_30 (
  .O(mux_o_30),
  .I0(sp_inst_5_dout[5]),
  .I1(sp_inst_6_dout[5]),
  .S0(dff_q_2)
);
MUX2 mux_inst_31 (
  .O(mux_o_31),
  .I0(sp_inst_7_dout[5]),
  .I1(sp_inst_8_dout[5]),
  .S0(dff_q_2)
);
MUX2 mux_inst_33 (
  .O(mux_o_33),
  .I0(mux_o_30),
  .I1(mux_o_31),
  .S0(dff_q_1)
);
MUX2 mux_inst_35 (
  .O(dout[5]),
  .I0(mux_o_33),
  .I1(sp_inst_9_dout[5]),
  .S0(dff_q_0)
);
MUX2 mux_inst_36 (
  .O(mux_o_36),
  .I0(sp_inst_5_dout[6]),
  .I1(sp_inst_6_dout[6]),
  .S0(dff_q_2)
);
MUX2 mux_inst_37 (
  .O(mux_o_37),
  .I0(sp_inst_7_dout[6]),
  .I1(sp_inst_8_dout[6]),
  .S0(dff_q_2)
);
MUX2 mux_inst_39 (
  .O(mux_o_39),
  .I0(mux_o_36),
  .I1(mux_o_37),
  .S0(dff_q_1)
);
MUX2 mux_inst_41 (
  .O(dout[6]),
  .I0(mux_o_39),
  .I1(sp_inst_9_dout[6]),
  .S0(dff_q_0)
);
MUX2 mux_inst_42 (
  .O(mux_o_42),
  .I0(sp_inst_5_dout[7]),
  .I1(sp_inst_6_dout[7]),
  .S0(dff_q_2)
);
MUX2 mux_inst_43 (
  .O(mux_o_43),
  .I0(sp_inst_7_dout[7]),
  .I1(sp_inst_8_dout[7]),
  .S0(dff_q_2)
);
MUX2 mux_inst_45 (
  .O(mux_o_45),
  .I0(mux_o_42),
  .I1(mux_o_43),
  .S0(dff_q_1)
);
MUX2 mux_inst_47 (
  .O(dout[7]),
  .I0(mux_o_45),
  .I1(sp_inst_9_dout[7]),
  .S0(dff_q_0)
);
endmodule //Gowin_SP
