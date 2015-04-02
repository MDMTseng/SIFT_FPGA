`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:05:04 03/31/2015 
// Design Name: 
// Module Name:    windowConvCore 
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
module windowConvCore//TODO.....
#(
parameter 
winHW=3,a
winDataW=8,
convkernelW=8,
outputW=convkernelW*winDataW+$clog2(winHW)
)(
input [winHW*winHW*winDataW-1:0]window,
input [winHW*winHW*convkernelW-1:0]kernelwindow,
output[outputW-1:0]outputData
    );
/*
winHW=3

@@@    
@@@  * ooo 
@@@    
*/




endmodule
