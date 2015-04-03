`ifndef MFIXPOINT_BASIC_
`define MFIXPOINT_BASIC_

module MFP_Multi_Arr#( 
parameter 
In1W=4,
In2W=4,
ArrL=4,
OutW=In1W+In2W-1,
isFloor=1,
Saturate=0
)(input [In1W*ArrL-1:0]In1Arr,input [In2W*ArrL-1:0]In2Arr,output [OutW*ArrL-1:0]OutArr);

generate 
	genvar gi;
	for(gi=0;gi<ArrL;gi=gi+1 )begin:oparr
		MFP_Multi #(.In1W(In1W),.In2W(In2W),.OutW(OutW),.Saturate(Saturate),.isFloor(isFloor)) m0(
		In1Arr[gi*In1W+:In1W],In2Arr[gi*In2W+:In2W],OutArr[gi*OutW+:OutW]);
	end
endgenerate
endmodule


module MFP_Multi#( 
parameter 
In1W=4,
In2W=4,
OutW=In1W+In2W-1,
isFloor=1,
Saturate=0
)(In1,In2,Out);

input signed[In1W-1:0]In1;
input signed[In2W-1:0]In2;
output signed[OutW-1:0]Out;
localparam WSS=(In1W+In2W-1-OutW-2)/2;
localparam WSSK=(WSS<0)?0:WSS;

localparam modIn1W=In1W-WSSK;
localparam modIn2W=In2W-WSSK;

localparam modOutW=modIn1W+modIn2W-1;

wire signed[modIn1W-1:0]modIn1;
wire signed[modIn2W-1:0]modIn2;
MFP_Round#(.InW(In1W),.OutW(modIn1W),.isFloor(1),.Saturate(0)) rounI1(In1,modIn1);
MFP_Round#(.InW(In2W),.OutW(modIn2W),.isFloor(1),.Saturate(0)) rounI2(In2,modIn2);

wire signed[modOutW-1:0]Out_;
assign Out_ = modIn1*modIn2;
MFP_Round
#(.InW(modOutW),.OutW(OutW),.isFloor(isFloor),.Saturate(Saturate)) roun(Out_,Out);


endmodule
module MFP_Adder_Arr#( 
parameter 
ArrL=4,
In1W=16,//In1 must has bigger width than In2
In2W=In1W,
OutW=In1W,
unsignedAddIn2=0,//defult is In2 is also signed number
Saturate=0,
prescale1=1,//useful for substraction
prescale2=1
)(input [In1W*ArrL-1:0]In1Arr,input [In2W*ArrL-1:0]In2Arr,output [OutW*ArrL-1:0]OutArr);

generate 
	genvar gi;
	for(gi=0;gi<ArrL;gi=gi+1 )begin:oparr
		MFP_Adder #(.In1W(In1W),.In2W(In2W),.OutW(OutW),.Saturate(Saturate)) a0(
		prescale1*In1Arr[gi*In1W+:In1W],prescale2*In2Arr[gi*In2W+:In2W],OutArr[gi*OutW+:OutW]);
	end
endgenerate
endmodule
module MFP_Adder
#(parameter 
In1W=16,//In1 must has bigger width than In2
In2W=In1W,
OutW=In1W,
unsignedAddIn2=0,//by defult In2 is also signed number
Saturate=0
)
(
input signed[In1W-1:0] In1,
input signed[In2W-1:0] In2,
output signed[OutW-1:0] Out
);
	
	wire IsSameSign=!(In1[In1W-1]^(In2[In2W-1]&(!unsignedAddIn2)));//SS
	wire signed[OutW-1:0] TestAdd;//=In1+In2;
	wire IsSignChanged=(In1[In1W-1]^TestAdd[OutW-1]);//SC
	localparam maxPosOut=2**(OutW-1)-1;//3bit max pos number is 3(011)=>2^(3-1)-1=4-1
	//SS==1;SC==1 =>overflow
	//SS==1;SC==0 =>no overflow
	//SS==0;SC==x =>must no overflow
	
	generate
		if(unsignedAddIn2)begin
			wire [In2W-1:0] In2_=In2;
			assign TestAdd=In1+In2_;
		end
		else 
			assign TestAdd=In1+In2;
			if(Saturate==0)
				assign Out=TestAdd;
			else
				assign Out=((IsSignChanged&IsSameSign)|(TestAdd==-(maxPosOut+1)))?
				((In1[In1W-1])?-maxPosOut:maxPosOut)://overflowed do saturate
				(TestAdd);
	endgenerate
	
endmodule


module MFP_Round
       #(
           parameter
           InW = 16,
           OutW = 8,
				Saturate=0,
				isFloor=1
       )
       (input [InW-1:0] in,
        output [OutW-1:0] out);
/*
exp:
in :(4b) 1101
out:(3b) 110+1
110=in[4-1-:3]
1=in[4-3-1]

*/
generate

    if(OutW<InW)begin
			if(isFloor)
				assign out=in[InW-1-:OutW];
			else
				MFP_Adder #(.In1W(OutW),.In2W(1),.OutW(OutW),.unsignedAddIn2(1),.Saturate(Saturate)) aS(in[InW-1-:OutW],in[InW-OutW-1],out);
			
	 end
	 else
			assign out={in,{(OutW-InW){1'b0}}};
endgenerate


    endmodule
module MFP_RegOWire
#(
parameter
dataW=8,
levelIdx=0,
regInterval=0,
isWire=(regInterval==0)?1:(levelIdx%regInterval!=0)
)
(
input clk,en,
input [dataW-1:0]in,
output [dataW-1:0]out
    );
generate

		if(isWire)begin
		
			assign out=in;
		end else begin
			reg [dataW-1:0]in_reg;
			always@(posedge clk)if(en)begin
				in_reg<=in;
			end
			assign out=in_reg;
		end
endgenerate

endmodule


`endif