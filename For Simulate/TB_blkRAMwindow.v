
`include "SIFTDescriptorToolBox.v"



module TB1();
reg clk,en,clr;
always #5 clk=~clk;
integer addr;

wire[32-1:0]douta;
integer din;
blkRAM_W32D640_SP ssd(clk,en,1,addr,din,douta);
ScanLWindow_blkRAM_adv
#(.block_width(1),.block_height(5),.frame_width(4)) Sb
(clk,en,din,Win);
always@(posedge clk)din=din+1;

initial
begin
	addr=0;
	din=0;
   $dumpfile("wave.vcd");$dumpvars;
	clr=1;
    #5
     en=1;
    clk=0;
	#30 clr=0;
    #10240 $finish;
end
endmodule


module blkRAM_W32D640_SP(
			input clka,ena,wea,
			input [20:0]addra,
			input [31:0]dina,
			output [31:0]douta);
	reg[31:0]BlkRAM[0:639];
	assign #5  douta=BlkRAM[addra];
	
	 always@(posedge clka)
	if(ena&wea)begin
		  BlkRAM[addra]=dina;
	end
	
endmodule


module ScanLWindow_blkRAM_adv
#(parameter

	 block_width=1,
	 block_height=8,
	 frame_width=640,
	 pixel_depth=8
)
(input clk,input enable,input [pixel_depth-1:0]inData,output reg[block_width*block_height*pixel_depth-1:0] Window);

	
	localparam basic_depth=32;
	
	
	
	localparam stackK=basic_depth/pixel_depth;
	localparam buffRow=block_height-1;
	localparam blksets=buffRow/stackK+((buffRow%stackK==0)?0:1);
	real SSS;
	
	
	initial SSS=blksets;
	localparam RAMAccessSpace=frame_width;
	
	reg [10-1:0]addra_bramR;
	initial addra_bramR=1;
	always@(posedge clk)
	begin
		if(enable)begin
			#1
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
	genvar gj, bri;
	generate
	
		always@(posedge clk)if(enable)
			Window[0+:shiftRegSliceL]={Window[0+:shiftRegSliceL],inData};
		for(bri=0;bri<blksets;bri=bri+1)begin:RAMFEED
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
			if(bri*stackK+gj+1<block_width*block_height)
				always@(posedge clk)if(enable)
					Window[(bri*stackK+gj+1)*shiftRegSliceL+:shiftRegSliceL]<=
					{Window[(bri*stackK+gj+1)*shiftRegSliceL+:shiftRegSliceL],outRAMIf[gj*pixel_depth+:pixel_depth]};
			end
		end
	endgenerate
	

endmodule