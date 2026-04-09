module arith_comb(A,Y);
input wire [31:0] A;   output wire [15:0] Y;
wire [15:0] tmp1,tmp2;

assign tmp1=A[7:0]*A[15:8];
assign tmp2=A[31:24]*A[23:16];
assign Y=(tmp1>tmp2)?(tmp1-tmp2):(tmp2-tmp1);
endmodule