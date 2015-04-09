
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
	
	
parameter tableDataW=6;
parameter windowSize=19;
reg[windowSize*In1W-1:0]MACIn;
reg clk_;

wire [windowSize*tableDataW-1:0]GaussT={6'd6,6'd7,6'd10,6'd12,6'd14,6'd15,6'd17,6'd18,6'd18,6'd18,6'd18,6'd18,6'd17,6'd15,6'd14,6'd12,6'd10,6'd8,6'd6};

wire [In1W-1:0]MACOut;
	MFP_MAC_symmetric_par #(.In1W(In1W),.In2W(tableDataW),.In2EQW(In1W),.ArrL(windowSize),.PordW_ROUND(In1W+2),.AccW_ROUND(In1W),.pipeInterval(2),.isFloor(0),.isUnsigned(1))MACSymUnsigned(clk_,1,MACIn,GaussT,MACOut);
	
	
reg[windowSize*In1W-1:0]MACIn2;

	/*MFP_MAC_symmetric_par #(.In1W(In1W),.In2W(tableDataW),.In2EQW(In1W),.ArrL(windowSize),.PordW_ROUND(In1W+2),.AccW_ROUND(In1W),.pipeInterval(0),.isFloor(0),.isUnsigned(1))MACSymUnsigned2(clk_,1,MACIn2,GaussT,XXX);*/
	MFP_MAC_par #(.In1W(In1W),.In2W(tableDataW),.In2EQW(In1W),.ArrL(windowSize),.PordW_ROUND(In1W+2),.AccW_ROUND(In1W),.pipeInterval(2),.isFloor(0),.isUnsigned(1))MACSymUnsigned2(clk_,1,MACIn,GaussT,XXX);
integer counter;
reg [In1W-1:0]In1WNum=0;

always@(posedge clk_)MACIn<={MACIn,In1WNum};
always@(posedge clk_)MACIn2<={MACIn2,MACOut};
always@(posedge clk_)begin
	counter=counter+1;
	In1WNum<=counter[5:0]?0:255;
end

	
always #2 clk_=!clk_;
	
initial
begin
	MACIn=~0;
	counter=0;
	MACIn2=0;
	clk_=0;
  $dumpfile("wave.vcd");
  $dumpvars;
	#1024 $finish;
end
endmodule 