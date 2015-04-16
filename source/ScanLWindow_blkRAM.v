`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:48:44 02/08/2015 
// Design Name: 
// Module Name:    ScanLWindow_blkRAM 
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

module ScanLWindow_blkRAM_adv
#(parameter

	 block_width=1,
	 block_height=4,
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
	always@(posedge clk)if(enable)
	Window[0+:shiftRegSliceL]={Window[0+:shiftRegSliceL],inData};
	genvar bri;
	genvar gj;
	generate
	
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
					if(bri*stackK+gj+1<block_height)
					always@(posedge clk)if(enable)
						Window[(bri*stackK+gj+1)*shiftRegSliceL+:shiftRegSliceL]<=
						{Window[(bri*stackK+gj+1)*shiftRegSliceL+:shiftRegSliceL],outRAMIf[gj*pixel_depth+:pixel_depth]};
					
			end
		end
	endgenerate
	


endmodule
module ScanLWindow_blkRAM_32W
#(parameter

	 block_width=1,
	 block_height=8,
	 frame_width=640

)
(input clk,input enable,input [pixel_depth-1:0]inData,output reg[block_width*block_height*pixel_depth-1:0] Window);

	
	
	localparam pixel_depth=32;//fixed
	localparam RAMAccessSpace=frame_width-block_width;
	
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
	generate
		for(bri=0;bri<block_height-1;bri=bri+1)begin:RAMFEED
			wire [pixel_depth-1:0]inRAMIf,outRAMIf;
			/*
			
			xxxx S S<S>RRRRRRRRRR
			RRRR[S]S<S>RRRRRRRRRR
			RRRR[@]S S

			Window= {S S <S> [S] S <S> [@] S S}
			[@] presents inRAMIf at bri=1
			*/
			assign inRAMIf=Window[(bri+1)*shiftRegSliceL-1-:pixel_depth];
			blkRAM_W32D640_SP RAM(
			.clka(clk),
			.ena(enable),
			.wea(~0),
			.addra(addra_bramR),
			.dina(inRAMIf),
			.douta(outRAMIf)
			);
			
		end
	endgenerate
	
	
	integer i;
	always@(posedge clk)begin
		if(enable)for(i=0;i<block_height;i=i+1)begin
			if(i==0)
				Window[i*shiftRegSliceL+:shiftRegSliceL]={Window[i*shiftRegSliceL+:shiftRegSliceL],inData};
			else
				Window[i*shiftRegSliceL+:shiftRegSliceL]={Window[i*shiftRegSliceL+:shiftRegSliceL],RAMFEED[i-1].outRAMIf};
		
		end
		
	end
	

endmodule