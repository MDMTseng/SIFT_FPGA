`ifndef MFIXPOINT_BASIC_
`define MFIXPOINT_BASIC_

module MFP_Multi_Arr#( 
parameter 
In1W=4,
In2W=In1W,
ArrL=4,
In2EQW=In1W,
OutW=In1W+In2W-1,
isFloor=1,
Saturate=0,
isUnsigned=0
)(input [In1W*ArrL-1:0]In1Arr,input [In2W*ArrL-1:0]In2Arr,output [OutW*ArrL-1:0]OutArr);

generate 
	genvar gi;
	for(gi=0;gi<ArrL;gi=gi+1 )begin:oparr
		MFP_Multi #(.In1W(In1W),.In2W(In2W),.In2EQW(In2EQW),.OutW(OutW),.Saturate(Saturate),.isFloor(isFloor),.isUnsigned(isUnsigned)) m0(
		In1Arr[gi*In1W+:In1W],In2Arr[gi*In2W+:In2W],OutArr[gi*OutW+:OutW]);
	end
endgenerate
endmodule


module MFP_Multi#( 
parameter 
In1W=4,
In2W=In1W,
In2EQW=In2W,
//In2EQW is equivilent width for In2W it's for if your coefficient is basically small, 
//but you don't want to waste long multiplier
//Ex, 8'd127 X 8'd63 you know the 8'd63 only needs 6 bit to contain
//so you set In2W=6 but only this will effect rounding position so you need to set In2EQW=8 to correct the rounding position
OutW=RealOutW,
isFloor=1,
Saturate=0,
isUnsigned=0
)(In1,In2,Out);

input [In1W-1:0]In1;
input [In2W-1:0]In2;
output [OutW-1:0]Out;

localparam RealOutW=In1W+In2EQW+((isUnsigned)?0:-1);


wire [RealOutW-1:0]Out_;

generate
	if(isUnsigned)begin
		assign Out_ = In1*In2;
	end else begin
		wire signed[In1W-1:0]In1_s=In1;
		wire signed[In2W-1:0]In2_s=In2;
		wire signed[RealOutW-1:0]Out_s=In1_s*In2_s;
		assign Out_ =Out_s;
	end
endgenerate


MFP_Round
#(.InW(RealOutW),.OutW(OutW),.isFloor(isFloor),.Saturate(Saturate),.isUnsigned(isUnsigned)) roun(Out_,Out);


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
prescale2=1,
isUnsigned=unsignedAddIn2
)(input [In1W*ArrL-1:0]In1Arr,input [In2W*ArrL-1:0]In2Arr,output [OutW*ArrL-1:0]OutArr);

generate 
	genvar gi;
	for(gi=0;gi<ArrL;gi=gi+1 )begin:oparr
		MFP_Adder #(.In1W(In1W),.In2W(In2W),.OutW(OutW),.Saturate(Saturate),.isUnsigned(isUnsigned)) a0(
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
Saturate=0,
isUnsigned=unsignedAddIn2
)
(
input [In1W-1:0] In1,
input [In2W-1:0] In2,
output [OutW-1:0] Out
);
	wire IsSameSign=!(In1[In1W-1]^In2[In2W-1]);//SS
	wire [OutW-1:0] TestAdd;//=In1+In2;
	wire IsSignChanged=(In1[In1W-1]^TestAdd[OutW-1]);//SC
	localparam maxPosOut=(isUnsigned)?(2**(OutW)-1):(2**(OutW-1)-1);//3bit max pos number is 3(011)=>2^(3-1)-1=4-1
	//SS==1;SC==1 =>overflow
	//SS==1;SC==0 =>no overflow
	//SS==0;SC==x =>must no overflow
	
	generate
		if(isUnsigned)begin
			wire [In2W-1:0] In2_=In2;
			assign TestAdd=In1+In2_;
			if(Saturate==0)
				assign Out=TestAdd;
			else
				assign Out=((~TestAdd[OutW-1])&In1[In1W-1])?maxPosOut:TestAdd;
		end
		else begin
			assign TestAdd=In1+In2;
			if(Saturate==0)
				assign Out=TestAdd;
			else
				assign Out=((IsSignChanged&IsSameSign)|(TestAdd==-(maxPosOut+1)))?
				((In1[In1W-1])?-maxPosOut:maxPosOut)://overflowed do saturate
				(TestAdd);
		end
	endgenerate
	
endmodule


	
module MFP_Round
       #(
           parameter
           InW = 16,
           OutW = 8,
				Saturate=0,
				isFloor=1,
				isUnsigned=0
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
				MFP_Adder #(.In1W(OutW),.In2W(1),.OutW(OutW),.unsignedAddIn2(1),.Saturate(Saturate),.isUnsigned(isUnsigned)) aS(in[InW-1-:OutW],in[InW-OutW-1],out);
			
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