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
dataW=8,
outoutW=dataW,
frameW=640
)
(
input clk,en,
input [dataW-1:0]dataIn,
output [dataW*5-1:0]dataOut
);



parameter windowSize=19;
parameter windowDataW=6;

parameter sigmaInit=1.6;//1.26
parameter sigmaInc=1.414;//1.26
parameter windowRadi=windowSize/2;

wire [32*windowSize-1:0]WinX;
parameter GausTableN=5;


wire [windowSize*dataW-1:0]GaussT[0:GausTableN-1];


assign GaussT[0]={6'd0,6'd0,6'd0,6'd0,6'd0,6'd3,6'd11,6'd29,6'd52,6'd63,6'd52,6'd29,6'd11,6'd3,6'd0,6'd0,6'd0,6'd0,6'd0};
assign GaussT[1]={6'd0,6'd0,6'd0,6'd1,6'd4,6'd9,6'd19,6'd30,6'd41,6'd45,6'd41,6'd30,6'd19,6'd9,6'd4,6'd1,6'd0,6'd0,6'd0};
assign GaussT[2]={6'd1,6'd1,6'd3,6'd5,6'd9,6'd15,6'd21,6'd26,6'd30,6'd31,6'd30,6'd26,6'd21,6'd15,6'd9,6'd5,6'd3,6'd1,6'd1};
assign GaussT[3]={6'd3,6'd5,6'd7,6'd10,6'd13,6'd16,6'd19,6'd21,6'd23,6'd23,6'd23,6'd21,6'd19,6'd16,6'd13,6'd10,6'd7,6'd5,6'd3};
assign GaussT[4]={6'd7,6'd8,6'd10,6'd12,6'd14,6'd15,6'd17,6'd18,6'd18,6'd18,6'd18,6'd18,6'd17,6'd15,6'd14,6'd12,6'd10,6'd8,6'd7};

	ScanLWindow_blkRAM #(.block_height(windowSize),.block_width(1),.frame_width(frameW)) win1(clk,en,dataIn,WinX);
	 
	
	
	wire [windowSize*dataW-1:0]W1;
	

	groupArrReOrderBABA2BBAA#(
	.Arr1EleW(dataW),.Arr2EleW(32-dataW),.Arr3EleW(0),.Arr4EleW(0),
	.ArrL(windowSize))gARO(WinX,W1);

	genvar gi;
	generate
		 for(gi=0;gi<GausTableN;gi=gi+1)
		 begin:FilterL

			  wire [dataW-1:0]MAC_Ver_rounded;
			  wire [dataW-1:0]FilterOut;
			  MFP_MAC_par #(.In1W(dataW),.In2W(windowDataW),.In2EQW(dataW),.ArrL(windowSize),.isUnsigned(1)
			  ,.PordW_ROUND(dataW+1),.AccW_ROUND(dataW),.pipeInterval(2),.isFloor(0))
			  MACpV(clk,en,W1,GaussT[gi],MAC_Ver_rounded);
			  
			  

			  reg [dataW*windowSize-1:0]HerizontalBuff;
			  always@(posedge clk)if(en)HerizontalBuff<={HerizontalBuff,MAC_Ver_rounded};
					
				
				
			  MFP_MAC_par #(.In1W(dataW),.In2W(windowDataW),.In2EQW(dataW),.ArrL(windowSize),.isUnsigned(1)
			  ,.PordW_ROUND(dataW+1),.AccW_ROUND(dataW),.pipeInterval(2),.isFloor(0))
			  MACpH(clk,en,HerizontalBuff,GaussT[gi],FilterOut);

			  reg [outoutW-1:0]FilterOutReg;
			  always@(posedge clk)if(en)FilterOutReg<=FilterOut;
			  assign dataOut[gi*outoutW+:outoutW]=FilterOutReg;
		 end

	endgenerate
endmodule