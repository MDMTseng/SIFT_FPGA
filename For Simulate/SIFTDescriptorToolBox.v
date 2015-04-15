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
	wire signed[5-1:0]CTY=CircleTableY[i*4+:4];
	wire signed[5-1:0]CTX=CircleTableX[i*4+:4];
	assign ExtractRegion[(regionPixNum-i-1)*dataW+:dataW]=
	window[((
		CTY+(winHW-regionHW)/2+yoffSet)*winHW+//Y
		CTX+(winHW-regionHW)/2+xoffSet//X
		)*dataW+:dataW
		
	];
end
endgenerate



endmodule


module HistogramPipeLine_StreamData
#(parameter
dataW=8,
dataL=4,
histoDataW=dataW,
histoL=8
)
(
input clk,en,clr,
input [histoBitW*dataL-1:0]LocArr,
input [dataW*dataL-1:0]MagArr,
output [histoL*histoDataW-1:0]Histo
);
parameter histoBitW=$clog2(histoL);

integer i;
generate
genvar gi;

for(gi=0;gi<dataL;gi=gi+1)begin:HisV
		reg [histoDataW-1:0]H[0:histoL-1];
		
		wire [histoDataW-1:0]H0=H[0];
		wire [histoBitW-1:0]LocVar=LocArr[gi*histoBitW+:histoBitW];
		wire [dataW-1:0]MagVar=MagArr[gi*dataW+:dataW];
		if(gi==0)begin
		  always@(posedge clk)if(en)begin
				for(i=0;i<histoL;i=i+1)H[i]=0;
				H[LocVar]=MagVar;
			end
		end else begin
			always@(posedge clk)if(en)begin
				
				for(i=0;i<histoL;i=i+1)
					if(i!=LocVar)H[i]=HisV[gi-1].H[i];
				H[LocVar]=HisV[gi-1].H[LocVar]+MagVar;
			end
		end 
end
	for(gi=0;gi<histoL;gi=gi+1)begin:setWire
		assign Histo[gi*histoDataW+:histoDataW]=HisV[dataL-1].H[gi];
	end
endgenerate
/*
always@(posedge clk)begin
	if(clr)begin
		for(i=0;i<histoL;i=i+1)HistoV[i]<=0;
	end else if(en)begin
		HistoV[Loc]=HistoV[Loc]+Mag;
	end 
end*/

endmodule

module HistogramPipeLine
#(parameter
dataW=8,
dataL=4,
histoDataW=dataW,
histoL=8
)
(
input clk,en,clr,
input [histoBitW*dataL-1:0]LocArr,
input [dataW*dataL-1:0]MagArr,
output [histoL*histoDataW-1:0]Histo
);
parameter histoBitW=$clog2(histoL);

integer i;
generate
genvar gi;
for(gi=0;gi<dataL;gi=gi+1)begin:HisV
		reg [histoDataW-1:0]H[0:dataL-1];
		reg [histoBitW*(dataL-gi)-1:0]Loc;
		reg [dataW*(dataL-gi)-1:0]Mag;
		wire [histoBitW-1:0]LocVar=Loc[0+:histoBitW];
		wire [dataW-1:0]MagVar=Mag[0+:dataW];
		if(gi==0)begin
		  always@(posedge clk)if(en)begin
				Loc=LocArr;
				Mag=MagArr;
				for(i=0;i<histoL;i=i+1)H[i]=0;
				H[LocVar]=MagVar;
			end
		end else begin
			always@(posedge clk)if(en)begin
				Loc=HisV[gi-1].Loc[histoBitW*(dataL-gi+1)-1:histoBitW];
				Mag=HisV[gi-1].Mag[dataW*(dataL-gi+1)-1:dataW];
				H[LocVar]=HisV[gi-1].H[LocVar]+MagVar;
			end
		end 
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

module regionsFor19WinExtractor
#(parameter
dataW=8
)
(
input [winW*winW*dataW-1:0]window,
output [regionSize*9-1:0]ExtractRegion
);

localparam 
regionSize=89*dataW,
winW=19
;

/*


003000200
000000000
400000001

    0
	
500000008
000000000
0060007
pos:offsetX,offsetY
0:  0   0
1:  4  -2
2:  2  -4
3: -2  -4
4: -4  -2
5: -4   2
6: -2   4
7:  2   4
8:  4   2


*/
regionExtractor#(.winHW(winW),.xoffSet(0),.yoffSet(0))
rE0(window,ExtractRegion[regionSize*0+:regionSize]);
regionExtractor#(.winHW(winW),.xoffSet(4),.yoffSet(-2))
rE1(window,ExtractRegion[regionSize*1+:regionSize]);
regionExtractor#(.winHW(winW),.xoffSet(2),.yoffSet(-4))
rE2(window,ExtractRegion[regionSize*2+:regionSize]);
regionExtractor#(.winHW(winW),.xoffSet(-2),.yoffSet(-4))
rE3(window,ExtractRegion[regionSize*3+:regionSize]);
regionExtractor#(.winHW(winW),.xoffSet(-4),.yoffSet(-2))
rE4(window,ExtractRegion[regionSize*4+:regionSize]);

regionExtractor#(.winHW(winW),.xoffSet(-4),.yoffSet(2))
rE5(window,ExtractRegion[regionSize*5+:regionSize]);
regionExtractor#(.winHW(winW),.xoffSet(-2),.yoffSet(4))
rE6(window,ExtractRegion[regionSize*6+:regionSize]);
regionExtractor#(.winHW(winW),.xoffSet(2),.yoffSet(4))
rE7(window,ExtractRegion[regionSize*7+:regionSize]);
regionExtractor#(.winHW(winW),.xoffSet(4),.yoffSet(2))
rE8(window,ExtractRegion[regionSize*8+:regionSize]);

endmodule


module HistogramFor9Regions
#(parameter
dataW=8
)
(input clk,en,clr,
input [winW*winW*dataW-1:0]window,
output [regionSize*9-1:0]ExtractRegion
);

localparam 
regionSize=89*dataW,
winW=19;

wire [regionSize*9-1:0]ExtractRegions;
regionsFor19WinExtractor
#(.dataW(dataW))rF16WE(window,ExtractRegions);


endmodule