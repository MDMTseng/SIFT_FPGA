
`include "MFixPointBasic.v"
`include "MFixPointMAC.v"

module TB1();

	parameter In1W=8;
	parameter In2W=8;
	parameter OutW=In1W+In2W-1;
	
	wire [In1W-1:0]In1;
	wire [In2W-1:0]In2;
	wire [OutW-1:0]Out;
	integer counter;
	
	wire[7:0]AA=0,BB=255;
	wire signed[7+1:0]CC=AA-BB;
	
	MFP_Multi#(.In1W(8-1),.OutW(8)) Mul(-63,-63,ZZZ);
	MFP_Multi#(.In1W(In1W),.In2W(In2W),.OutW(8),.isUnsigned(1)) Muluns(128,128,ZZZ);
	
	
	MFP_Adder#(.In1W(In1W),.In2W(In2W),.OutW(8)) Adder(127,-127,ZZZ);
	MFP_Adder#(.In1W(In1W),.In2W(In2W),.OutW(8),.isUnsigned(1)) AdderuS(-1,1,ZZZ);
	
	
	wire signed[OutW-1:0]satOut;
	MFP_Saturate#(.InW(OutW),.Sat2W(3),.OutW(OutW),.isUnsigned(0)) sat(counter,satOut);


	reg clk_;
always #2 clk_=!clk_;
always @(posedge clk_)begin
	counter=counter+1;
end
initial
begin
	counter=-100;
	clk_=0;
  $dumpfile("wave.vcd");
  $dumpvars;
	#1024 $finish;
end
endmodule 