`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:40:12 04/01/2015 
// Design Name: 
// Module Name:    octaveModule 
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

module octaveModule
#(parameter
dataW=9,
outoutW=dataW
)
(
input clk,en,
input [dataW-1:0]dataIn,
output [dataW*5-1:0]dataOut
);



parameter windowSize=19;
parameter sigmaInit=1.6;//1.26
parameter sigmaInc=1.414;//1.26
parameter windowRadi=windowSize/2;

wire [32*windowSize-1:0]WinX;
parameter GausTableN=5;


wire [windowSize*dataW-1:0]GaussT[0:GausTableN-1];


assign GaussT[0]={9'd0,9'd0,9'd0,9'd0,9'd0,9'd3,9'd11,9'd29,9'd52,9'd64,9'd52,9'd29,9'd11,9'd3,9'd0,9'd0,9'd0,9'd0,9'd0};
assign GaussT[1]={9'd0,9'd0,9'd0,9'd1,9'd4,9'd9,9'd19,9'd30,9'd41,9'd45,9'd41,9'd30,9'd19,9'd9,9'd4,9'd1,9'd0,9'd0,9'd0};
assign GaussT[2]={9'd1,9'd1,9'd3,9'd5,9'd9,9'd15,9'd21,9'd26,9'd30,9'd32,9'd30,9'd26,9'd21,9'd15,9'd9,9'd5,9'd3,9'd1,9'd1};
assign GaussT[3]={9'd3,9'd5,9'd7,9'd10,9'd13,9'd16,9'd19,9'd21,9'd23,9'd23,9'd23,9'd21,9'd19,9'd16,9'd13,9'd10,9'd7,9'd5,9'd3};
assign GaussT[4]={9'd7,9'd8,9'd10,9'd12,9'd14,9'd15,9'd17,9'd18,9'd18,9'd18,9'd18,9'd18,9'd17,9'd15,9'd14,9'd12,9'd10,9'd8,9'd7};


	ScanLWindow_blkRAM #(.block_height(windowSize),.block_width(1)) win1(clk,en,dataIn,WinX);
	 
	
	
	wire [windowSize*dataW-1:0]W1;
	

	groupArrReOrderBABA2BBAA#(
	.Arr1EleW(dataW),.Arr2EleW(32-dataW),.Arr3EleW(0),.Arr4EleW(0),
	.ArrL(windowSize))gARO(WinX,W1);

	genvar gi;
	parameter FilterOutW=dataW;
	generate
		 for(gi=0;gi<GausTableN;gi=gi+1)
		 begin:FilterL

			  wire [19-1:0]accSum1ZZZ,accSum2ZZZ;
			  wire signed[dataW-1:0]MAC_Ver_rounded;
			  wire signed[dataW-1:0]FilterOut;
			  MFP_MAC_par #(.In1W(dataW),.ArrL(windowSize),.PordW_ROUND(dataW+2),.AccW_ROUND(dataW),.pipeInterval(3))
			  MACpV(clk,en,W1,GaussT[gi],accSum1ZZZ,MAC_Ver_rounded);

			  reg [dataW*windowSize-1:0]HerizontalBuff;
			 /* ShiftReg_window
					#(.pixel_depth(FilterOutW),.frame_width(ImageW),.block_width(windowSize),.block_height(1)) SW_Hor
					(clk,en,MAC_Ver_rounded,HerizontalBuff);*/
			  always@(posedge clk)if(en)HerizontalBuff<={HerizontalBuff,MAC_Ver_rounded};
					
				
				
			  MFP_MAC_par #(.In1W(dataW),.In2W(dataW),.ArrL(windowSize),.PordW_ROUND(outoutW+2),.AccW_ROUND(outoutW),.pipeInterval(3))
			  MACpH(clk,en,HerizontalBuff,GaussT[gi],accSum2ZZZ,FilterOut);

			  reg signed[outoutW-1:0]FilterOutReg;
			  always@(posedge clk)if(en)FilterOutReg<=FilterOut;
			  assign dataOut[gi*outoutW+:outoutW]=FilterOutReg;
		 end

	endgenerate

		




endmodule