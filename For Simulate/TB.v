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

parameter GausTableN=5;

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
assign GaussT[0]={6'd0,6'd0,6'd0,6'd0,6'd0,6'd3,6'd11,6'd29,6'd52,6'd63,6'd52,6'd29,6'd11,6'd3,6'd0,6'd0,6'd0,6'd0,6'd0};
assign GaussT[1]={6'd0,6'd0,6'd0,6'd1,6'd4,6'd9,6'd19,6'd30,6'd41,6'd45,6'd41,6'd30,6'd19,6'd9,6'd4,6'd1,6'd0,6'd0,6'd0};
assign GaussT[2]={6'd1,6'd1,6'd3,6'd5,6'd9,6'd15,6'd21,6'd26,6'd30,6'd31,6'd30,6'd26,6'd21,6'd15,6'd9,6'd5,6'd3,6'd1,6'd1};
assign GaussT[3]={6'd2,6'd4,6'd7,6'd10,6'd13,6'd16,6'd19,6'd21,6'd23,6'd23,6'd23,6'd21,6'd19,6'd16,6'd13,6'd10,6'd7,6'd4,6'd2};
assign GaussT[4]={6'd6,6'd7,6'd10,6'd12,6'd14,6'd15,6'd17,6'd18,6'd18,6'd18,6'd18,6'd18,6'd17,6'd15,6'd14,6'd12,6'd10,6'd8,6'd6};





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
    (pixClk,en_p,{OutPixel_R[8-1:0]},VerticleBuff);//padding 0 for signed bit


parameter FilterOutW=dataW;
wire signed[FilterOutW-1:0]FilterOut[0:GausTableN-1];
wire signed[dataW-1:0]DoGOut[0:GausTableN-1-1];
generate
    for(gi=0;gi<GausTableN;gi=gi+1)
    begin:FilterL

        wire [FilterOutW-1:0]MAC_Ver_rounded;
        MFP_MAC_symmetric_par #(.In1W(dataW),.In2W(tableDataW),.In2EQW(dataW),.ArrL(windowSize),.PordW_ROUND(FilterOutW+2),.AccW_ROUND(FilterOutW),.pipeInterval(2),.isFloor(0),.isUnsigned(1))MACpV(pixClk,en_p,VerticleBuff,GaussT[gi],FilterOut[gi]);
			
			//MFP_MAC_par #(.In1W(dataW),.In2W(tableDataW),.In2EQW(dataW),.ArrL(windowSize),.PordW_ROUND(FilterOutW+2),.AccW_ROUND(FilterOutW),.pipeInterval(3),.isFloor(0),.isUnsigned(1))MACpV(pixClk,en_p,VerticleBuff,GaussT[gi],FilterOut[gi]);
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

