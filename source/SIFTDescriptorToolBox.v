module reginClassifier
#(parameter
dataW=8
)
(
input signed[dataW-1:0]X,
input signed[dataW-1:0]Y,
output [2:0]R,
output [dataW-1:0]K
);
	wire [1:0]Dom={Y[dataW-1],X[dataW-1]^Y[dataW-1]};
	wire [dataW-2:0]absX=(X[dataW-1])?-X:X;
	wire [dataW-2:0]absY=(Y[dataW-1])?-Y:Y;
	wire XDY=(absX<absY);
	assign R={Dom,XDY^Dom[0]};

	parameter satBits=3;
	parameter shiftBack=(dataW-1-satBits);
	wire [2*dataW-1:0]AL=(X*X+Y*Y);
	wire [2*dataW-shiftBack-1:0]ALS=AL>>shiftBack;

	assign K=(ALS[2*dataW-shiftBack-1-:satBits])?~0:ALS;


endmodule

/*
diamiter 11 circle
0  4~6:3
1  2~8:7
2  1~9:9
3 
4  0~10:11
5 
7
8  1~9:9
9
10 2~8:7
11 4~6:3

Total 89

    ***
  *******
 *********
 *********
***********
***********
*/
module regionExtractor
#(parameter
dataW=8,
xoffSet=0,
yoffSet=0,
winHW=19
)
(
input [winHW*winHW*dataW-1:0]window,
output [regionPixNum*dataW-1:0]ExtractRegion
);
localparam 
regionPixNum=89,
regionHW=11
;

wire[regionPixNum*4-1:0]CircleTableX={
            4'd4,4'd5,4'd6,
      4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,
   4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,4'd9,
   4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,4'd9,
4'd0,4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,4'd9,4'd10,
4'd0,4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,4'd9,4'd10,
4'd0,4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,4'd9,4'd10,
   4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,4'd9,
   4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,4'd9,
      4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,
            4'd4,4'd5,4'd6
};
wire[regionPixNum*4-1:0]CircleTableY={
            4'd0,4'd0,4'd0,
      4'd1,4'd1,4'd1,4'd1,4'd1,4'd1,4'd1,
   4'd2,4'd2,4'd2,4'd2,4'd2,4'd2,4'd2,4'd2,4'd2,
   4'd3,4'd3,4'd3,4'd3,4'd3,4'd3,4'd3,4'd3,4'd3,
4'd4,4'd4,4'd4,4'd4,4'd4,4'd4,4'd4,4'd4,4'd4,4'd4,4'd4,
4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,4'd5,
4'd6,4'd6,4'd6,4'd6,4'd6,4'd6,4'd6,4'd6,4'd6,4'd6,4'd6,
   4'd7,4'd7,4'd7,4'd7,4'd7,4'd7,4'd7,4'd7,4'd7,
   4'd8,4'd8,4'd8,4'd8,4'd8,4'd8,4'd8,4'd8,4'd8,
      4'd9,4'd9,4'd9,4'd9,4'd9,4'd9,4'd9,
           4'd10,4'd10,4'd10
};
generate
genvar i;
for(i=0;i<regionPixNum;i=i+1)begin:asLoop
	assign ExtractRegion[(regionPixNum-i-1)*dataW+:dataW]=
	window[((
		CircleTableY[i*4+:4]+(winHW-regionHW)/2+yoffSet)*winHW+//Y
		CircleTableX[i*4+:4]+(winHW-regionHW)/2+xoffSet//X
		)*dataW+:dataW
		
	];
end
endgenerate



endmodule






module HistogramSeq
#(parameter
dataW=8,
histoDataW=dataW,
histoL=8
)
(
input clk,en,clr,
input [histoBitW-1:0]Loc,
input [dataW-1:0]Mag,
output [histoL*histoDataW-1:0]Histo
);
parameter histoBitW=$clog2(histoL);
reg [histoDataW-1:0]HistoV[0:histoL-1];
generate
genvar gi;
for(gi=0;gi<histoL;gi=gi+1)begin:setWire
	assign Histo[gi*histoDataW+:histoDataW]=HistoV[gi];
	end
endgenerate
integer i;

always@(posedge clk)begin
	if(clr)begin
		for(i=0;i<histoL;i=i+1)HistoV[i]<=0;
	end else if(en)begin
		HistoV[Loc]=HistoV[Loc]+Mag;
	end 
end

endmodule

