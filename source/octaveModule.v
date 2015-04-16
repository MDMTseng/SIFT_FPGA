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
downS=0,
dataW=8,
outW=dataW,
frameW=640,
cornorwindowSize=5
)
(
input clk,en,
input [dataW-1:0]dataIn,

input [10-1:0]X,
input [10-1:0]Y,
output [outW*GausTableN-1:0]dataOut,
output [outW-1:0]cornorResponse
);



localparam windowSize=19;
parameter windowDataW=6;
/*
parameter sigmaInit=1.6;//1.26
parameter sigmaInc=1.414;//1.26*/
parameter windowRadi=windowSize/2;

parameter GausTableN=5;


wire [windowSize*windowDataW-1:0]GaussT[0:GausTableN-1];


assign GaussT[0]={6'd0,6'd0,6'd0,6'd0,6'd0,6'd3,6'd11,6'd29,6'd52,6'd63,6'd52,6'd29,6'd11,6'd3,6'd0,6'd0,6'd0,6'd0,6'd0};
assign GaussT[1]={6'd0,6'd0,6'd0,6'd1,6'd4,6'd9,6'd19,6'd30,6'd41,6'd45,6'd41,6'd30,6'd19,6'd9,6'd4,6'd1,6'd0,6'd0,6'd0};
/*
assign GaussT[2]={6'd1,6'd1,6'd3,6'd5,6'd9,6'd15,6'd21,6'd26,6'd30,6'd31,6'd30,6'd26,6'd21,6'd15,6'd9,6'd5,6'd3,6'd1,6'd1};
assign GaussT[3]={6'd3,6'd5,6'd7,6'd10,6'd13,6'd16,6'd19,6'd21,6'd23,6'd23,6'd23,6'd21,6'd19,6'd16,6'd13,6'd10,6'd7,6'd5,6'd3};
assign GaussT[4]={6'd7,6'd8,6'd10,6'd12,6'd14,6'd15,6'd17,6'd18,6'd18,6'd18,6'd18,6'd18,6'd17,6'd15,6'd14,6'd12,6'd10,6'd8,6'd7};*/

//for even smaller resorce usage we use 5 bits to contain the gaussian coeff
assign GaussT[2]={5'd1,5'd1,5'd3,5'd5,5'd9,5'd15,5'd21,5'd26,5'd30,5'd31,5'd30,5'd26,5'd21,5'd15,5'd9,5'd5,5'd3,5'd1,5'd1};
assign GaussT[3]={5'd3,5'd5,5'd7,5'd10,5'd13,5'd16,5'd19,5'd21,5'd23,5'd23,5'd23,5'd21,5'd19,5'd16,5'd13,5'd10,5'd7,5'd5,5'd3};
assign GaussT[4]={5'd7,5'd8,5'd10,5'd12,5'd14,5'd15,5'd17,5'd18,5'd18,5'd18,5'd18,5'd18,5'd17,5'd15,5'd14,5'd12,5'd10,5'd8,5'd7};

	//^^^^^^^  change downS to get different down sample
	//(0:original, 1:down by 2 ,2:down by 4 .... )
	parameter downSBufferL=(frameW/(2**downS));
	wire ys=(downS==0)?1:(Y[0+:(downS==0)?1:downS]==0);
	wire xs=(downS==0)?1:(X[0+:(downS==0)?1:downS]==0);
	//
	wire en_op=ys&xs&en;


	wire [windowSize*dataW-1:0]W1;


	ScanLWindow_blkRAM_adv #(.block_height(windowSize),.block_width(1),.frame_width(downSBufferL),.pixel_depth(dataW)) win1(clk,en_op,dataIn,W1);
	 //vertical sliding window extracter
	 //19X1 window
	
	
	
	parameter cornerDelayX=9;
	parameter cornerDelayY=7;//Hard coding delay balance with GAUSSIAN
	wire [outW-1:0]cornorResponseO;
	harrisCornerResponse  #(.dataW(dataW),.ImageW(downSBufferL),
	.cornorwindowSize(cornorwindowSize),.outW(outW),.ts(15))hCornor
	(clk,en_op,rst_p,
	W1[cornerDelayY*dataW+:dataW*3],
	cornorResponseO);
	reg[cornerDelayX*outW-1:0]cornorResponseRegs;
	always@(posedge clk)if(en_op)cornorResponseRegs<={cornorResponseRegs,cornorResponseO};
	assign cornorResponse=cornorResponseRegs[cornerDelayX*outW-1-:outW];
	
	
	

	wire [outW*GausTableN-1:0]FilterOutData;
	genvar gi;
	generate
		 for(gi=0;gi<2;gi=gi+1)//6bit table
		 begin:FilterL6b

			  wire [dataW-1:0]MAC_Ver_rounded;
			  
			  MFP_MAC_symmetric_par #(.In1W(dataW),.In2W(windowDataW),.In2EQW(dataW),
			  .ArrL(windowSize),.PordW_ROUND(dataW+2),.AccW_ROUND(dataW),
			  .pipeInterval(2),.isFloor(0),.isUnsigned(1))
			  MACpV(clk,en_op,W1,GaussT[gi],MAC_Ver_rounded);
			  

			  reg [dataW*windowSize-1:0]HerizontalBuff;
			  always@(posedge clk)if(en_op)HerizontalBuff<={HerizontalBuff,MAC_Ver_rounded};
					

			  MFP_MAC_symmetric_par #(.In1W(dataW),.In2W(windowDataW),.In2EQW(dataW),
			  .ArrL(windowSize),.PordW_ROUND(dataW+2),.AccW_ROUND(outW),
			  .pipeInterval(2),.isFloor(0),.isUnsigned(1))
			  MACpH(clk,en_op,HerizontalBuff,GaussT[gi],FilterOutData[outW*gi+:outW]);
		 end
		 
		for(gi=2;gi<GausTableN;gi=gi+1)//5bit table
		 begin:FilterL5b

			  wire [dataW-1:0]MAC_Ver_rounded;
			  //the In2W must be changed to 5
			  MFP_MAC_symmetric_par #(.In1W(dataW),.In2W(5),.In2EQW(dataW),
			  .ArrL(windowSize),.PordW_ROUND(dataW+2),.AccW_ROUND(dataW),
			  .pipeInterval(2),.isFloor(0),.isUnsigned(1))
			  MACpV(clk,en_op,W1,GaussT[gi],MAC_Ver_rounded);
			  

			  reg [dataW*windowSize-1:0]HerizontalBuff;
			  always@(posedge clk)if(en_op)HerizontalBuff<={HerizontalBuff,MAC_Ver_rounded};
					

			  MFP_MAC_symmetric_par #(.In1W(dataW),.In2W(5),.In2EQW(dataW),
			  .ArrL(windowSize),.PordW_ROUND(dataW+2),.AccW_ROUND(outW),
			  .pipeInterval(2),.isFloor(0),.isUnsigned(1))
			  MACpH(clk,en_op,HerizontalBuff,GaussT[gi],FilterOutData[outW*gi+:outW]);
		 end
		 
		 
		 if(downS==0)MFP_RegOWire#(.dataW(outW*GausTableN),.isWire(0)) RoW(clk,en_op,FilterOutData,dataOut);
		 else
			downSamplePixMem
			#(.downSBufferL(downSBufferL),.dataW(outW*GausTableN)) dSMEM
			(clk, xs&en, ys&en,FilterOutData,dataOut);
	//
	
	endgenerate
	
endmodule