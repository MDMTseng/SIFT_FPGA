
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

wire [89*dataW-1:0]ExtractRegion;
regionExtractor#(.winHW(winW),.xoffSet(-4),.yoffSet(-4))
rE(window,ExtractRegion);

/*
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


module blkRAM_W32D640_SP(
			input clka,ena,wea,
			input [10:0]addra,
			input [31:0]dina,
			output [31:0]douta);
	reg[31:0]BlkRAM[0:639];
	assign douta=BlkRAM[addra];
	always@(posedge clka)
	if(ena)begin
		BlkRAM[addra]=dina;
	end
	
endmodule


module ScanLWindow_blkRAM
#(parameter

	 block_width=1,
	 block_height=8,
	 frame_width=640,
	 pixel_depth=8
)
(input clk,input enable,input [pixel_depth-1:0]inData,output reg[block_width*block_height*pixel_depth-1:0] Window);

	
	localparam basic_depth=32;
	
	
	
	localparam stackK=basic_depth/pixel_depth;
	localparam blksets=block_height/stackK+(block_height%stackK==0)?0:1;
	
	
	localparam RAMAccessSpace=frame_width-0;
	
	reg [10-1:0]addra_bramR;
	always@(posedge clk)
	begin
		if(enable)begin
			if(addra_bramR==RAMAccessSpace-2)
			addra_bramR=0;
			else
			addra_bramR=addra_bramR+1;
		end
	end
	
/*	

xxxxSSSRRRRRRRRRR
RRRRSSSRRRRRRRRRR
RRRRSSS

R: data in the RAM block(blkRAM_W32D640_SP)
S: data in the shift register(Window)
	
	
	

xxxx S S<S>RRRRRRRRRR
RRRR[S]S<S>RRRRRRRRRR
RRRR[S]S S


[?]: data saaign to RAMFEED[?].inRAMIf
<?>: data saaign to RAMFEED[?].outRAMIf

*/	
	localparam shiftRegSliceL=block_width*pixel_depth;
	
	genvar bri;
	genvar gj;
	generate
	
	
	
	
	
	
		for(bri=0;bri<blksets-1;bri=bri+1)begin:RAMFEED
			wire [basic_depth-1:0]inRAMIf,outRAMIf;
			/*
			
			xxxx S S<S>RRRRRRRRRR
			RRRR[S]S<S>RRRRRRRRRR
			RRRR[@]S S

			Window= {S S <S> [S] S <S> [@] S S}
			[@] presents inRAMIf at bri=1
			*/
			wire [pixel_depth-1:0]NewData;
			if(bri==0)assign NewData=inData;
			else		 assign NewData=RAMFEED[bri-1].outRAMIf[(stackK-1)*pixel_depth+:pixel_depth];
			
			
			assign inRAMIf={outRAMIf[0+:basic_depth-pixel_depth],NewData};//Window[(bri+1)*shiftRegSliceL-1-:pixel_depth];
			
			
			blkRAM_W32D640_SP RAM(
			.clka(clk),
			.ena(enable),
			.wea(~0),
			.addra(addra_bramR),
			.dina(inRAMIf),
			.douta(outRAMIf)
			);
			
			for(gj=0;gj<stackK;gj=gj+1)begin:ShiftRegAssign
					always@(posedge clk)if(enable)
						Window[(bri*stackK+gj)*shiftRegSliceL+:shiftRegSliceL]=
						{Window[(bri*stackK+gj)*shiftRegSliceL+:shiftRegSliceL],inRAMIf[gj*pixel_depth+:pixel_depth]};
					
			end
		end
	endgenerate
	

endmodule