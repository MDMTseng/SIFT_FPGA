`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:29:57 03/31/2015 
// Design Name: 
// Module Name:    MAC1D 
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
module MAC1D
#(
parameter 
winW=3,
winDataW=8,
kernelDataW=winDataW,

winDataW_Reduce=winDataW,
kernelDataW_Reduce=kernelDataW,
productW=winDataW_Reduce+kernelDataW_Reduce,
outputW=productW+$clog2(winW)
)(
input [winW*winDataW-1:0]Arr,
input [winW*kernelDataW-1:0]kernel,
output[outputW-1:0]outputData
    );
/*
winHW=3

@@@    
@@@  * ooo 
@@@    
*/




endmodule
