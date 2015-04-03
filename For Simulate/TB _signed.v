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








parameter dataW=9;
parameter windowSize=19;
parameter sigmaInit=1.6;//1.26
parameter sigmaInc=1.414;//1.26
parameter windowRadi=windowSize/2;

parameter GausTableN=5;

integer file2W[0:GausTableN-1-1];
wire [windowSize*dataW-1:0]GaussT[0:GausTableN-1];
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
assign GaussT[0]={9'd0,9'd0,9'd0,9'd0,9'd0,9'd3,9'd11,9'd29,9'd52,9'd64,9'd52,9'd29,9'd11,9'd3,9'd0,9'd0,9'd0,9'd0,9'd0};
assign GaussT[1]={9'd0,9'd0,9'd0,9'd1,9'd4,9'd9,9'd19,9'd30,9'd41,9'd45,9'd41,9'd30,9'd19,9'd9,9'd4,9'd1,9'd0,9'd0,9'd0};
assign GaussT[2]={9'd1,9'd1,9'd3,9'd5,9'd9,9'd15,9'd21,9'd26,9'd30,9'd32,9'd30,9'd26,9'd21,9'd15,9'd9,9'd5,9'd3,9'd1,9'd1};
assign GaussT[3]={9'd3,9'd5,9'd7,9'd10,9'd13,9'd16,9'd19,9'd21,9'd23,9'd23,9'd23,9'd21,9'd19,9'd16,9'd13,9'd10,9'd7,9'd5,9'd3};
assign GaussT[4]={9'd7,9'd8,9'd10,9'd12,9'd14,9'd15,9'd17,9'd18,9'd18,9'd18,9'd18,9'd18,9'd17,9'd15,9'd14,9'd12,9'd10,9'd8,9'd7};





    parameter downS=0;
//^^^^^^^  change downS to get different down sample
//(0:original, 1:down by 2 ,2:down by 4 .... )
parameter downSBufferL=(200/(2**downS));
wire ys=(downS==0)?1:(y[0+:(downS==0)?1:downS]==0);
wire xs=(downS==0)?1:(x[0+:(downS==0)?1:downS]==0);
//
wire en_p=ys&xs;

wire [dataW*windowSize-1:0]VerticleBuff;
ShiftReg_window
    #(.pixel_depth(dataW),.frame_width(downSBufferL),.block_width(1),.block_height(windowSize)) SW_Ver
    (pixClk,en_p,{1'b0,OutPixel_R[8-1:0]},VerticleBuff);//padding 0 for signed bit


parameter FilterOutW=dataW;
wire signed[FilterOutW-1:0]FilterOut[0:GausTableN-1];
wire signed[dataW-1:0]DoGOut[0:GausTableN-1-1];
generate
    for(gi=0;gi<GausTableN;gi=gi+1)
    begin:FilterL

        wire [19-1:0]accSum1ZZZ,accSum2ZZZ;
        wire [FilterOutW-1:0]MAC_Ver_rounded;
       // MFP_MAC_symmetric_par #(.In1W(dataW),.ArrL(windowSize),.PordW_ROUND(FilterOutW+2),.AccW_ROUND(FilterOutW),.pipeInterval(3))MACpV(pixClk,en_p,VerticleBuff,GaussT[gi],FilterOut[gi]);
			
			 MFP_MAC_par #(.In1W(dataW),.ArrL(windowSize),.PordW_ROUND(FilterOutW+2),.AccW_ROUND(FilterOutW),.pipeInterval(3))MACpV(pixClk,en_p,VerticleBuff,GaussT[gi],FilterOut[gi]);
       /* reg [FilterOutW*windowSize-1:0]HerizontalBuff;
		always@(posedge pixClk)if(en_p)HerizontalBuff<={HerizontalBuff,MAC_Ver_rounded};
				

        MFP_MAC_symmetric_par #(.In1W(FilterOutW),.In2W(dataW),.ArrL(windowSize),.PordW_ROUND(FilterOutW+4),.AccW_ROUND(FilterOutW),.pipeInterval(3))MACpH(pixClk,en_p,HerizontalBuff,GaussT[gi],FilterOut[gi]);

*/
    end

    for(gi=0;gi<GausTableN-1;gi=gi+1)
    begin:DogL
      //wire signed[dataW-1:0]DoG=;
		//assign DoGOut[gi]=128+(FilterOut[gi+1]-FilterOut[gi]);
		
		assign DoGOut[gi]=FilterOut[gi];
        //assign DoGOut[gi]=FilterOut[gi+1]>>2;
    end
    endgenerate




        always
        begin
            #10 pixClk=~pixClk;
        end
        ///////////////////////////Important don't change it, unless you know what are you doing.
        initial begin
           // $dumpfile("wave.vcd");$dumpvars;
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

