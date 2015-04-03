`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:40:11 03/31/2015 
// Design Name: 
// Module Name:    RegOWire 
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
module RegOWire
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
