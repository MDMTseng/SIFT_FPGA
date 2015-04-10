`include"BMPIO.v"

`include"ShiftReg_window.v"
`include"downSamplePixMem.v"


`include "MFixPoint_ToolBox/MFixPointBasic.v"
`include "MFixPoint_ToolBox/MFixPointMAC.v"
`include "MFixPoint_ToolBox/MFixPointTables.v"
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

wire [23:0]mixPixel={3{DoGOut[0][7:0]}};//mix the row data
wire [23:0]mixPixel2={3{DoGOut[1][7:0]}};//mix the row data








parameter dataW=8;
parameter tableDataW=6;
parameter windowSize=19;
parameter sigmaInit=1.6;//1.26
parameter sigmaInc=1.414;//1.26
parameter windowRadi=windowSize/2;

parameter GausTableN=4;

integer file2W[0:GausTableN-1-1];
wire [windowSize*tableDataW-1:0]GaussT[0:GausTableN-1];
wire writeEnd;
genvar gi;
generate
    for(gi=0;gi<GausTableN-1;gi=gi+1)
    begin:lgen
    	
    	/*MFP_gaussianTableArr #(.xstart(-windowRadi),.xend(windowRadi),
    			.sig(1.26**(gi)),.outputW(dataW),.scale(255.0/255)) gS(GaussT[gi]);*/
				
		
		writeBMPStream wS(.fileHandle(file2W[gi]),.clk(pixClk),.rst(wsrst),.reload(0),.bmp_refheader(bmp_header),.writeEnd(writeEnd),.InPixel({3{DoGOut[gi][7:0]}}));	
    end

endgenerate




    parameter downS=0;
//^^^^^^^  change downS to get different down sample
//(0:original, 1:down by 2 ,2:down by 4 .... )
parameter downSBufferL=(200/(2**downS));
wire ys=(downS==0)?1:(y[0+:(downS==0)?1:downS]==0);
wire xs=(downS==0)?1:(x[0+:(downS==0)?1:downS]==0);
//
wire en_p=ys&xs;


reg signed[dataW-1:0]DoGOut[0:GausTableN-1-1];



wire [8*3*3-1:0]LPWin;
ShiftReg_window
    #(.pixel_depth(8),.frame_width(200),.block_width(3),.block_height(3)) corWinLP
    (pixClk,1,{OutPixel_R[0+:8]},LPWin);//padding 0 for signed bit


	
wire [8-1:0]LPData={
LPWin[0*8+:8]+LPWin[1*8+:8]+LPWin[2*8+:8]+
LPWin[3*8+:8]+LPWin[4*8+:8]+LPWin[5*8+:8]+
LPWin[6*8+:8]+LPWin[7*8+:8]+LPWin[8*8+:8]
}/9
;
	
wire [8*3*3-1:0]corWin;
ShiftReg_window
    #(.pixel_depth(8),.frame_width(200),.block_width(3),.block_height(3)) corWinSW
    (pixClk,1,LPData,corWin);//padding 0 for signed bit


wire [8*8-1:0]corWin_skipCenter={corWin[5*8+:4*8],corWin[0+:4*8]};	
	genvar pix; 
generate 
	wire [8-1:0]centerpix=corWin[4*8+:8];
	
	wire [8-1:0]compArrMax;
	wire [8-1:0]compArrMin;
    for (pix=0;pix<9-1;pix=pix+1) begin:maxpixel
		
	  wire [8-1:0]a= corWin_skipCenter[pix*8+:8];
	  assign compArrMin[pix]=(centerpix < a);
	  assign compArrMax[pix]=(centerpix > a);
	  	
	end

endgenerate
wire localEx=(compArrMin==8'hFF)||(compArrMax==8'hFF); 
	 
always@(posedge pixClk)begin
	#1
	if((compArrMin==8'hFF))
		DoGOut[1]=0;
	else if((compArrMax==8'hFF))
		DoGOut[1]=255;
	else
		DoGOut[1]=128;
end




        always
        begin
            #10 pixClk=~pixClk;
        end
        ///////////////////////////Important don't change it, unless you know what are you doing.
        initial begin
            //$dumpfile("wave.vcd");$dumpvars;
            file1_R = $fopen("Mix3.bmp","rb");
            file2W[0] = $fopen("O0.bmp","wb");
            file2W[1]= $fopen("O1.bmp","wb");
            file2W[2]= $fopen("O2.bmp","wb");
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
        $finish;
    end

///////////////////////////Important end




endmodule

