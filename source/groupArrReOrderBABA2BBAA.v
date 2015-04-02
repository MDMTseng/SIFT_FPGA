`timescale 1ns / 1ps

/*
piledArr
{C3,B3,A3, C2,B2,A2, C1,B1,A1, C0,B0,A0}

groupArrReOrderBABA2BBAA

{C3,C2,C1,C0, B3,B2,B1,B0, A3,A2,A1,A0}


*/
module groupArrReOrderBABA2BBAA
#(
parameter 
ArrL=32,
Arr1EleW=8,
Arr2EleW=Arr1EleW,
Arr3EleW=Arr2EleW,
Arr4EleW=Arr3EleW,
piledArrW=Arr1EleW+Arr2EleW+Arr3EleW+Arr4EleW

)(
input [piledArrW*ArrL-1:0]groupArrBABA,
output [piledArrW*ArrL-1:0]groupArrBBAA
    );
	 
	 
localparam//for groupArrBABA
Arr1Offset=0,
Arr2Offset=Arr1Offset+Arr1EleW,
Arr3Offset=Arr2Offset+Arr2EleW,
Arr4Offset=Arr3Offset+Arr3EleW;
	 
	 
	 
localparam// for groupArrBBAA
Arr1Start=0,
Arr2Start=Arr1Start+Arr1EleW*ArrL,
Arr3Start=Arr2Start+Arr2EleW*ArrL,
Arr4Start=Arr3Start+Arr3EleW*ArrL;


generate

genvar i,j;

for(i=0;i<ArrL;i=i+1)
begin:Xloop
	assign groupArrBBAA[Arr1Start+i*Arr1EleW+:Arr1EleW]=
		groupArrBABA[i*piledArrW+Arr1Offset+:Arr1EleW];
	
	if(Arr2EleW>0)
	assign groupArrBBAA[Arr2Start+i*Arr2EleW+:Arr2EleW]=
		groupArrBABA[i*piledArrW+Arr2Offset+:Arr2EleW];
		
		
	if(Arr3EleW>0)
	assign groupArrBBAA[Arr3Start+i*Arr3EleW+:Arr3EleW]=
		groupArrBABA[i*piledArrW+Arr3Offset+:Arr3EleW];
	if(Arr4EleW>0)
	assign groupArrBBAA[Arr4Start+i*Arr4EleW+:Arr4EleW]=
		groupArrBABA[i*piledArrW+Arr4Offset+:Arr4EleW];
		
end

endgenerate





endmodule
