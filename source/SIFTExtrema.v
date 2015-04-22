`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:02:08 04/21/2015 
// Design Name: 
// Module Name:    SIFTExtrema 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module SIFTExtrema
#(parameter
frame_width=640,
dataW=8,
localExThres=0,
windowHW=3
)(
input clk,en,
input [dataW*3-1:0]dataIn_3Layer,//three different scale space DoG X Harris
output reg[2:0] ExtremaType
//00: not extrema, 01: min, 10 max
);

	
	wire [windowHW*windowHW*dataW*3-1:0]W1;


	ScanLWindow_blkRAM_adv #(.block_height(windowHW),.block_width(windowHW)
	,.frame_width(frame_width),.pixel_depth(dataW*3))
	win1(clk,en,dataIn_3Layer,W1);
/*
W1={
abc8  abc7  abc6

abc5  abc4  abc3

abc2  abc1  abc0
}
a is layer 0
b is layer 1
c is layer 2




centerpix=b4

Win_skipCenter=>Lenght=LocalScopeSize*dataW
={
abc8  abc7  abc6

abc5  a4


        c4  abc3

abc2  abc1  abc0
}


*/
	localparam LocalScopeSize=(windowHW*windowHW*3-1);//not include center Pix
	wire [LocalScopeSize*dataW-1:0]Win_skipCenter=
	{W1[(LocalScopeSize/2+1)*dataW+:LocalScopeSize/2*dataW],
	W1[0+:LocalScopeSize/2*dataW]};

	genvar pix; 
	generate 
		wire signed[dataW-1:0]centerpix=W1[LocalScopeSize/2*dataW+:dataW];
		wire signed[dataW-1:0]centerpixT=centerpix-localExThres;
		wire signed[dataW-1:0]centerpixB=centerpix+localExThres;
		
		wire [LocalScopeSize-1:0]compArrMax;
		wire [LocalScopeSize-1:0]compArrMin;
		for (pix=0;pix<LocalScopeSize;pix=pix+1) begin:maxpixel
			
		  wire signed[dataW-1:0]a= Win_skipCenter[pix*dataW+:dataW];
		  assign compArrMin[pix]=(centerpixB < a);
		  assign compArrMax[pix]=(centerpixT > a);
			
		end

	endgenerate
	//wire localEx=(compArrMin=={LocalScopeSize{1'b1}})||(compArrMax=={LocalScopeSize{1'b1}}); 
		 
	always@(posedge clk)if(en)begin
		#1
		if((compArrMin=={LocalScopeSize{1'b1}}))
			ExtremaType=1;
		else if((compArrMax=={LocalScopeSize{1'b1}}))
			ExtremaType=2;
		else
			ExtremaType=0;
	end





endmodule


module SIFTExtremaTL//two Layer  TBD
#(parameter
frame_width=640,
dataW=8,
localExThres=0
)(
input clk,en,
input [dataW*4-1:0]dataIn_4Layer,//four scale space DoG X Harris
output reg[2:0] ExtremaType
//000: not extrema,
//001: min, 010 max on layer 1
//101: min, 110 max on layer 2

);

	localparam windowHW=3;
	wire [windowHW*windowHW*dataW*4-1:0]W1;


	ScanLWindow_blkRAM_adv #(.block_height(windowHW),.block_width(windowHW)
	,.frame_width(frame_width),.pixel_depth(dataW*4))
	win1(clk,en,dataIn_3Layer,W1);
/*
W1={
abcd8  abcd7  abcd6

abcd5  abcd4  abcd3

abcd2  abcd1  abcd0
}
a is layer 0
b is layer 1
c is layer 2
d is layer 3



centerpix1=b4
centerpix2=c4

Win_skipCenter=>Lenght=LocalScopeSize*dataW
={
abc8  abc7  abc6

abc5  a4


        c4  abc3

abc2  abc1  abc0
}


*/
	localparam LocalScopeSize=(windowHW*windowHW*3-1);//not include center Pix
	wire [LocalScopeSize*dataW-1:0]Win_skipCenter1,Win_skipCenter2;
	
	
	
	
	
	

	genvar pix; 
	generate 
		wire signed[dataW-1:0]centerpix=W1[LocalScopeSize/2*dataW+:dataW];
		wire signed[dataW-1:0]centerpixT=centerpix-localExThres;
		wire signed[dataW-1:0]centerpixB=centerpix+localExThres;
		
		wire [LocalScopeSize-1:0]compArrMax;
		wire [LocalScopeSize-1:0]compArrMin;
		for (pix=0;pix<LocalScopeSize;pix=pix+1) begin:maxpixel
			
		  wire signed[dataW-1:0]a= Win_skipCenter[pix*dataW+:dataW];
		  assign compArrMin[pix]=(centerpixB < a);
		  assign compArrMax[pix]=(centerpixT > a);
			
		end

	endgenerate
	//wire localEx=(compArrMin=={LocalScopeSize{1'b1}})||(compArrMax=={LocalScopeSize{1'b1}}); 
		 
	always@(posedge clk)if(en)begin
		#1
		if((compArrMin=={LocalScopeSize{1'b1}}))
			ExtremaType=1;
		else if((compArrMax=={LocalScopeSize{1'b1}}))
			ExtremaType=2;
		else
			ExtremaType=0;
	end





endmodule
