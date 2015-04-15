
`include "SIFTDescriptorToolBox.v"



module TB1();
reg clk,en,clr;
always #5 clk=~clk;
parameter TableL=80;
wire [TableL*8-1:0]YTable={-8'd0,-8'd4,-8'd8,-8'd12,-8'd16,-8'd19,-8'd23,-8'd26,-8'd30,-8'd33,-8'd36,-8'd38,-8'd41,-8'd43,-8'd45,-8'd46,-8'd48,-8'd49,-8'd50,-8'd50,-8'd50,-8'd50,-8'd49,-8'd48,-8'd47,-8'd46,-8'd44,-8'd42,-8'd40,-8'd37,-8'd34,-8'd31,-8'd28,-8'd25,-8'd21,-8'd18,-8'd14,-8'd10,-8'd6,-8'd2,8'd2,8'd6,8'd10,8'd14,8'd18,8'd21,8'd25,8'd28,8'd31,8'd34,8'd37,8'd40,8'd42,8'd44,8'd46,8'd47,8'd48,8'd49,8'd50,8'd50,8'd50,8'd50,8'd49,8'd48,8'd46,8'd45,8'd43,8'd41,8'd38,8'd36,8'd33,8'd30,8'd26,8'd23,8'd19,8'd16,8'd12,8'd8,8'd4,8'd0};

wire [TableL*8-1:0]XTable={8'd50,8'd50,8'd49,8'd49,8'd47,8'd46,8'd44,8'd42,8'd40,8'd38,8'd35,8'd32,8'd29,8'd26,8'd22,8'd18,8'd15,8'd11,8'd7,8'd3,-8'd1,-8'd5,-8'd9,-8'd13,-8'd17,-8'd20,-8'd24,-8'd27,-8'd31,-8'd34,-8'd36,-8'd39,-8'd41,-8'd43,-8'd45,-8'd47,-8'd48,-8'd49,-8'd50,-8'd50,-8'd50,-8'd50,-8'd49,-8'd48,-8'd47,-8'd45,-8'd43,-8'd41,-8'd39,-8'd36,-8'd34,-8'd31,-8'd27,-8'd24,-8'd20,-8'd17,-8'd13,-8'd9,-8'd5,-8'd1,8'd3,8'd7,8'd11,8'd15,8'd18,8'd22,8'd26,8'd29,8'd32,8'd35,8'd38,8'd40,8'd42,8'd44,8'd46,8'd47,8'd49,8'd49,8'd50,8'd50};

parameter dataW=8;
reg [TableL*dataW-1:0]XTableReg;
wire signed[dataW-1:0]XVar=XTableReg;

reg [TableL*dataW-1:0]YTableReg;
wire signed[dataW-1:0]YVar=YTableReg;

wire[2:0]R;
wire[dataW-1:0]K;

reginClassifier rT(XVar,YVar,R,K);

wire [8*dataW-1:0]Histo;
HistogramSeq HSDD(clk,en,clr,R,K>>3,Histo);

parameter winW=19;
reg [winW*winW*dataW-1:0]window;


always@(posedge clk)begin
	XTableReg={XVar,XTableReg[TableL*dataW-1:dataW]};
	YTableReg={YVar,YTableReg[TableL*dataW-1:dataW]};
end
/*
wire [89*dataW-1:0]ExtractRegion;
regionExtractor#(.winHW(winW),.xoffSet(-4),.yoffSet(-4))
rE(window,ExtractRegion);


parameter regionSize=89*dataW;
wire [regionSize*9-1:0]ExtractRegions;
regionsFor19WinExtractor
#(.dataW(dataW))rF16WE(window,ExtractRegions);*/


wire [8*8-1:0]HistoP;
HistogramPipeLine_StreamData
#(.dataW(dataW),.dataL(20))
HPSD(clk,en,clr,{20{R}},{20{K>>3}},HistoP);

integer i,j;
initial
begin

	for(i=0;i<winW;i=i+1) for(j=0;j<winW;j=j+1)begin
		window[(i*winW+j)*dataW+:dataW]=i*16+j;
	end

   $dumpfile("wave.vcd");$dumpvars;
	clr=1;
    #5
	XTableReg=XTable;
	YTableReg=YTable;
     en=1;
    clk=0;
	#30 clr=0;
    #1024 $finish;
end
endmodule
