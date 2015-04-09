`include"BMPIO.v"

`include"ShiftReg_window.v"
`include"downSamplePixMem.v"
`include"FakeMul.v"


`include "MFixPoint_ToolBox/MFixPointBasic.v"
`include "MFixPoint_ToolBox/MFixPointMAC.v"
//This example shows how to load 2 image(imL.bmp & imR.bmp) and process the image
//then output the result to an image (Mix.bmp)


module test;
integer file1_R,file1_L;
reg rst,reload,pixClk,wsrst;
wire ReadEnd;
wire [8*60-1:0]  bmp_header;
wire [31:0] x,y;

wire [23:0] OutPixel_R;
wire [23:0] OutPixel_L; 



readBMPStream rS_R(file1_R,pixClk,rst,reload,bmp_header,ReadEnd,OutPixel_R,x,y);







parameter dataW=8;

parameter outPutN=4;

integer file2W[0:outPutN-1];
wire writeEnd;
wire [8-1:0]DataOutPix[0:outPutN-1];
genvar gi,gj;
generate
    for(gi=0;gi<outPutN;gi=gi+1)
    begin:lgen
    	
    	/*MFP_gaussianTableArr #(.xstart(-windowRadi),.xend(windowRadi),
    			.sig(1.26**(gi)),.outputW(dataW),.scale(255.0/255)) gS(GaussT[gi]);*/
				
		
		writeBMPStream wS(.fileHandle(file2W[gi]),.clk(pixClk),.rst(wsrst),.reload(0),.bmp_refheader(bmp_header),.writeEnd(writeEnd),.InPixel({DataOutPix[gi],DataOutPix[gi],DataOutPix[gi]}));	
    end

endgenerate
parameter imageW=200;

wire [dataW*3*3-1:0]Buff3x3;
ShiftReg_window
    #(.pixel_depth(dataW),.frame_width(imageW),.block_width(3),.block_height(3)) sobelWin
    (pixClk,1,{OutPixel_R[0+:dataW]},Buff3x3);//padding 0 for signed bit


	
	

parameter FilterOutW=dataW;

wire  [dataW+1-1:0]DH1=(Buff3x3[0*dataW+:dataW]+Buff3x3[1*dataW+:dataW]*2+Buff3x3[2*dataW+:dataW])/2;
wire  [dataW+1-1:0]DH2=(Buff3x3[6*dataW+:dataW]+Buff3x3[7*dataW+:dataW]*2+Buff3x3[8*dataW+:dataW])/2;
wire  [dataW+1-1:0]DV1=(Buff3x3[0*dataW+:dataW]+Buff3x3[3*dataW+:dataW]*2+Buff3x3[6*dataW+:dataW])/2;
wire  [dataW+1-1:0]DV2=(Buff3x3[2*dataW+:dataW]+Buff3x3[5*dataW+:dataW]*2+Buff3x3[8*dataW+:dataW])/2;

wire signed[dataW+2-1:0]SobelXY_[0:2-1];
assign SobelXY_[0]=(DV1-DV2);
assign SobelXY_[1]=(DH1-DH2);


wire signed[dataW-1:0]SobelXY[0:2-1];
parameter satbits=1;
MFP_Saturate#(.InW(dataW+2),.Sat2W(dataW-satbits),.OutW(dataW),.isUnsigned(0)) 
sobelXsat(SobelXY_[0],SobelXY[0]);

MFP_Saturate#(.InW(dataW+2),.Sat2W(dataW-satbits),.OutW(dataW),.isUnsigned(0)) 
sobelYsat(SobelXY_[1],SobelXY[1]);

parameter corWinDataW=2*dataW;
parameter cornorwindowSize=3;
parameter cornorwindowDim=cornorwindowSize*cornorwindowSize;

wire [corWinDataW*cornorwindowDim-1:0]corWin;
ShiftReg_window
    #(.pixel_depth(corWinDataW),.frame_width(imageW),.block_width(cornorwindowSize),.block_height(cornorwindowSize)) corWinSW
    (pixClk,1,{SobelXY[0],SobelXY[1]},corWin);//padding 0 for signed bit

	 
parameter abcCoeffW=dataW+$clog2(cornorwindowDim)+1+1;
wire [abcCoeffW*cornorwindowDim-1:0]aij_arr;
wire [abcCoeffW*cornorwindowDim-1:0]cij_arr;
wire [abcCoeffW*cornorwindowDim-1:0]bij_arr;

generate
	for(gi=0;gi<cornorwindowDim;gi=gi+1)begin:addL
			wire signed[dataW-satbits-1:0]Ix,Iy;
			assign Ix=corWin[gi*corWinDataW+:dataW-satbits];
			assign Iy=corWin[gi*corWinDataW+dataW+:dataW-satbits];
			
			
			wire [dataW-1:0]IxIx;//signed
			MFP_Multi #(.In1W(dataW-satbits),.OutW(dataW),.isUnsigned(0)) 
			m_a(Ix,Ix,IxIx);
			wire [dataW-1:0]IyIy;
			MFP_Multi #(.In1W(dataW-satbits),.OutW(dataW),.isUnsigned(0)) 
			m_c(Iy,Iy,IyIy);
			wire signed[dataW-1:0]IxIy;
			MFP_Multi #(.In1W(dataW-satbits),.OutW(dataW),.isUnsigned(0)) 
			m_b(Iy,Ix,IxIy);
			
			assign aij_arr[gi*(abcCoeffW)+:abcCoeffW]=IxIx;
			assign cij_arr[gi*(abcCoeffW)+:abcCoeffW]=IyIy;
			
			wire signed[abcCoeffW-1:0]IxIyEx=IxIy;//extend sign
			assign bij_arr[gi*(abcCoeffW)+:abcCoeffW]=IxIyEx;
				
	end
	
	wire [abcCoeffW-1:0]aij;
	wire [abcCoeffW-1:0]cij;
	wire signed[abcCoeffW-1:0]bij;
	 MFP_AdderTree
    #(.data_depth(abcCoeffW),.ArrL(cornorwindowDim),.isUnsigned(0)
     )AdderTree_aij(
       clk_p,en_p,aij_arr,aij);
	 MFP_AdderTree
    #(.data_depth(abcCoeffW),.ArrL(cornorwindowDim),.isUnsigned(0)
     )AdderTree_cij(
       clk_p,en_p,cij_arr,cij);
	 MFP_AdderTree
    #(.data_depth(abcCoeffW),.ArrL(cornorwindowDim),.isUnsigned(0)
     )AdderTree_bij(
		clk_p,en_p,bij_arr,bij);
	 
	 
	
	
	parameter tc=0;
	//assign DataOutPix[0]=addL[cornorwindowSize*cornorwindowSize-1].aij*2/cornorwindowDim;
	wire [dataW-1+1:0]aij_ave=aij*2/cornorwindowDim-tc;
	wire [dataW-1+1:0]cij_ave=cij*2/cornorwindowDim-tc;
	wire signed[dataW-1+1:0]bij_ave=bij*2/cornorwindowDim;
	
	wire signed[dataW-1+3:0]aijcij;
	MFP_Multi #(.In1W(dataW+1),.OutW(dataW+3),.isUnsigned(0)) m_ac(aij_ave,cij_ave,aijcij);		
	
	wire[dataW-1+3:0]bijbij;
	MFP_Multi #(.In1W(dataW+1),.OutW(dataW+3),.isUnsigned(0)) m_bb(bij_ave,bij_ave,bijbij);	
	
	
	wire signed[dataW-1+1:0]acSbb=aijcij/4-bijbij/4;
	
	assign DataOutPix[0]=128+bijbij/8;
	assign DataOutPix[1]=128+aijcij/8;
	assign DataOutPix[2]=//128+bij_abs/2;
	(acSbb[dataW])?0:acSbb;
endgenerate
	
	
	
	
        always
        begin
            #10 pixClk=~pixClk;
        end
        ///////////////////////////Important don't change it, unless you know what are you doing.
        initial begin
            //$dumpfile("wave.vcd");$dumpvars;
            file1_R = $fopen("imR.bmp","rb");
            file2W[0] = $fopen("Mix1.bmp","wb");
            file2W[1]= $fopen("Mix2.bmp","wb");
            file2W[2]= $fopen("Mix3.bmp","wb");
            file2W[3]= $fopen("Mix4.bmp","wb");
            pixClk=0;
            rst=1;
            reload=1;
            #50
             rst=0;
            reload=0;
        end
        always@(posedge pixClk)wsrst=rst;
always@(writeEnd)if(writeEnd)
    begin
        $fclose(file1_R);
        // $fclose(file1_L);
        $fclose(file2W[0]);
        $fclose(file2W[1]);
        $fclose(file2W[2]);
        $fclose(file2W[3]);
        $finish;
    end

///////////////////////////Important end




endmodule
