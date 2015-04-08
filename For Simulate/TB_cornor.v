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


wire [dataW*3*3-1:0]Buff3x3;
ShiftReg_window
    #(.pixel_depth(dataW),.frame_width(200),.block_width(3),.block_height(3)) sobelWin
    (pixClk,1,{OutPixel_R[0+:dataW]},Buff3x3);//padding 0 for signed bit


	
	

parameter FilterOutW=dataW;
wire signed[dataW-1:0]SobelXY[0:2-1];

wire signed [8+2+1-1:0]DH1=(Buff3x3[0*dataW+:dataW]+Buff3x3[1*dataW+:dataW]*2+Buff3x3[2*dataW+:dataW])/4;
wire signed [8+2+1-1:0]DH2=(Buff3x3[6*dataW+:dataW]+Buff3x3[7*dataW+:dataW]*2+Buff3x3[8*dataW+:dataW])/4;
wire signed [8+2+1-1:0]DV1=(Buff3x3[0*dataW+:dataW]+Buff3x3[3*dataW+:dataW]*2+Buff3x3[6*dataW+:dataW])/4;
wire signed [8+2+1-1:0]DV2=(Buff3x3[2*dataW+:dataW]+Buff3x3[5*dataW+:dataW]*2+Buff3x3[8*dataW+:dataW])/4;

assign SobelXY[0]=(DV1-DV2)/2;
assign SobelXY[1]=(DH1-DH2)/2;

parameter corWinDataW=2*dataW;
parameter cornorwindowSize=3;
parameter cornorwindowDim=cornorwindowSize*cornorwindowSize;

wire [corWinDataW*cornorwindowDim-1:0]corWin;
ShiftReg_window
    #(.pixel_depth(corWinDataW),.frame_width(200),.block_width(cornorwindowSize),.block_height(cornorwindowSize)) corWinSW
    (pixClk,1,{SobelXY[0],SobelXY[1]},corWin);//padding 0 for signed bit

generate
	for(gi=0;gi<cornorwindowDim;gi=gi+1)begin:addL
			wire signed[dataW-1:0]Ix,Iy;
			assign Ix=corWin[gi*corWinDataW+:dataW];
			assign Iy=corWin[gi*corWinDataW+dataW+:dataW];
			
			wire [dataW-1:0]absDataX;
		//	ABSData#(.dataW(dataW))absX(Ix,absDataX);
			
			XMul #(.dataW(dataW),.outW(dataW)) xmX(
			Ix,Ix,absDataX);
			wire [10:0]aij;
			if(gi==0)
				assign aij=absDataX;
			else
				assign aij=addL[gi-1].aij+absDataX;
				
			
			wire [dataW-1:0]absDataY;
			//ABSData#(.dataW(dataW))absY(Iy,absDataY);
			XMul #(.dataW(dataW),.outW(dataW)) xmY(
			Iy,Iy,absDataY);
			wire [10:0]cij;
			if(gi==0)
				assign cij=absDataY;
			else
				assign cij=addL[gi-1].cij+absDataY;
				
				
			wire signed[dataW-1:0]MulIxIy;
			
			XMul #(.dataW(dataW),.outW(dataW)) xm(
			Ix,Iy,MulIxIy);
			wire signed[12:0]bij;
			if(gi==0)
				assign bij=MulIxIy;
			else
				assign bij=addL[gi-1].bij+MulIxIy;
				
	end
	//assign DataOutPix[0]=addL[cornorwindowSize*cornorwindowSize-1].aij*2/cornorwindowDim;
	wire [dataW-1+1:0]aij=addL[cornorwindowDim-1].aij*2/cornorwindowDim;
	wire [dataW-1+1:0]cij=addL[cornorwindowDim-1].cij*2/cornorwindowDim;
	
	wire signed[dataW-1+1:0]bij=addL[cornorwindowDim-1].bij*2/cornorwindowDim;
	
	wire signed[dataW-1+3:0]aijcij;
	XMul #(.dataW(dataW+1),.outW(dataW+3)) xmac(
			aij,cij,aijcij);
			
	wire signed[dataW-1+3:0]bijbij;
	XMul #(.dataW(dataW+1),.outW(dataW+3)) xmbb(
			bij,bij,bijbij);
	wire signed[dataW-1+1:0]acSbb=aijcij-bijbij;
	
	assign DataOutPix[1]=acSbb;
	
	assign DataOutPix[0]=128-(bij);
	assign DataOutPix[2]=cij;
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
