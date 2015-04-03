
`include "MFixPointBasic.v"
`include "MFixPointMAC.v"

module TB1();

	parameter In1W=8;
	parameter In2W=8;
	parameter OutW=In1W+In2W-1;
	
	wire [In1W-1:0]In1;
	wire [In2W-1:0]In2;
	wire [OutW-1:0]Out;
	
	MFP_Multi#(.In1W(In1W),.In2W(In2W),.OutW(8)) Mul(128,128,ZZZ);
	MFP_Multi#(.In1W(In1W),.In2W(In2W),.OutW(8),.isUnsigned(1)) Muluns(128,128,ZZZ);
	
	
	MFP_Adder#(.In1W(In1W),.In2W(In2W),.OutW(8)) Adder(127,-127,ZZZ);
	MFP_Adder#(.In1W(In1W),.In2W(In2W),.OutW(8),.isUnsigned(1)) AdderuS(-1,1,ZZZ);
	
	MFP_MAC_par#(.In1W(In1W),.In2W(In2W),.ArrL(2),.AccW_ROUND(8)) MAC(clk_,en_,{8'd127,8'd127},{8'd64,8'd64},RES);
	
	
	MFP_MAC_par#(.In1W(In1W),.In2W(In2W),.ArrL(2),.AccW_ROUND(8),.isUnsigned(1)) MACunS(clk_,en_,{8'd127,8'd127},{8'd128,8'd128},RES);
	


initial
begin
  $dumpfile("wave.vcd");
  $dumpvars;
	#1024 $finish;
end
endmodule 