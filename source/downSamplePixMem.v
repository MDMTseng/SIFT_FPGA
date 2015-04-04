/*
try to reproduce the pixel when y is not in the sample row

5  8  7  9  6
2  1  4  5  6

sample

5  5  7  7  6
X  X  X  X  X

use this module

5  5  7  7  6
5  5  7  7  6



*/
module downSamplePixMem
#(
parameter
downSBufferL=100,
dataW=8
)
(input clk,input xs,input ys,input[dataW-1:0] din,output [dataW-1:0] dout);

assign dout=(ys)?din:DelaySBuffer;

reg[dataW*downSBufferL-1:0]downSBuffer;
wire[dataW-1:0]feedData=(ys)?din:downSBuffer[dataW*downSBufferL-1-:dataW];
reg[dataW-1:0]DelaySBuffer;
always@(posedge clk)DelaySBuffer=feedData;
always@(posedge clk)if(xs)begin 
	downSBuffer={downSBuffer,feedData};
end


endmodule