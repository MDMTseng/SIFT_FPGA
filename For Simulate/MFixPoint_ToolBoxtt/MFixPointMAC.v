`ifndef MFIXPOINT_MAC_
`define MFIXPOINT_MAC_
	`ifndef MFIXPOINT_BASIC_ //dependency
	`include "MFixPointBasic.v"
	`endif
    module MFP_MAC_Seq
    #(
        parameter
        In1W=8,
        In2W=In1W,//signed

        PordW_ROUND=PordW,
        //no round by default, to save resource decrease this but lose precision
        AccW_ROUND=PordW_ROUND//select output width with round
    )

    (clock, aclr, In1, In2,  product, product_rounded, acc_sum, acc_sum_rounded);
localparam PordW=In1W+In2W-1;//(7+1)bit X (7+1)bit =(14+1)bit
localparam AccW=PordW_ROUND;
input clock;
input aclr;
input [In1W-1:0]In1;
input [In2W-1:0]In2;
output [PordW-1:0]product;
output [PordW_ROUND-1:0]product_rounded;
output reg [AccW-1:0]acc_sum;
output [AccW_ROUND-1:0]acc_sum_rounded;
wire [AccW-1:0]acc_sum_pre;
MFP_Multi #(.In1W(In1W),.In2W(In2W)) m1(In1,In2,product);
MFP_Round #(.InW(PordW),.OutW(PordW_ROUND)) round_prod ( product, product_rounded );
MFP_Adder #(.In1W(AccW),.In2W(PordW_ROUND),.OutW(AccW)) aS(acc_sum,product_rounded,acc_sum_pre);


always@(posedge clock)
   acc_sum=(aclr)?product_rounded:acc_sum_pre;

MFP_Round #(.InW(AccW),.OutW(AccW_ROUND))round_acc ( acc_sum, acc_sum_rounded );

endmodule





    module MFP_MAC_par
    #(
        parameter
        In1W=8,
        In2W=In1W,//signed

        ArrL=2,//signed
        PordW_ROUND=PordW,
        //no round by default, to save resource decrease this but it will lose some precision
        AccW_ROUND=PordW_ROUND,//select output width with round
		  
		  levelIdx=0,
		  pipeInterval=0
    )

    ( 
				input clk,en,
input [In1W*ArrL-1:0]In1Arr, 
input [In2W*ArrL-1:0]In2Arr,   
output [AccW-1:0]acc_sum, 
output [AccW_ROUND-1:0]acc_sum_rounded);


localparam PordW=In1W+In2W-1;
localparam AccW=PordW_ROUND;



assign acc_sum=productArr_roundedSum;
wire [PordW_ROUND*ArrL-1:0]productArr_rounded;
wire [PordW_ROUND-1:0]productArr_roundedSum;

genvar i;
generate
	for(i=0;i<ArrL;i=i+1) begin:MACLOOP
	
		wire [PordW-1:0]productArr;
		MFP_Multi #(.In1W(In1W),.In2W(In2W),.OutW(PordW_ROUND)) m1(In1Arr[i*In1W+:In1W],In2Arr[i*In2W+:In2W],productArr_rounded[i*PordW_ROUND+:PordW_ROUND]);
		
		//MFP_Round #(.InW(PordW),.OutW(PordW_ROUND)) round_prod ( productArr, productArr_rounded[i*PordW_ROUND+:PordW_ROUND]);
	end
endgenerate
MFP_AdderTree#(.data_depth(PordW_ROUND),.ArrL(ArrL),.levelIdx(levelIdx),.pipeInterval(pipeInterval)) ATFP(clk,en,productArr_rounded,productArr_roundedSum);
MFP_Round #(.InW(PordW_ROUND),.OutW(AccW_ROUND))round_acc ( productArr_roundedSum, acc_sum_rounded );

endmodule


module MFP_AdderTree
       #(parameter
         data_depth=8,
         ArrL = 4,
			levelIdx=0,
			pipeInterval=0
        )(
				input clk,en,
           input [data_depth*ArrL-1:0]DIn,
           output [data_depth-1:0]Sum
       );
parameter Sp1=ArrL/2;
parameter Sp2=ArrL-Sp1;

wire [data_depth-1:0]subLevelSum1;
wire [data_depth-1:0]subLevelSum2;
wire [data_depth-1:0]Sum_;

MFP_Adder #(.In1W(data_depth),.In2W(data_depth),.OutW(data_depth)) aS(subLevelSum1,subLevelSum2,Sum_);

MFP_RegOWire#(.dataW(data_depth),.levelIdx(levelIdx),.regInterval(pipeInterval)) RoW(clk,en,Sum_,Sum);


generate
    if(Sp1==1)
        assign subLevelSum1=DIn[0+:data_depth];

else
    MFP_AdderTree #(.data_depth(data_depth),.ArrL(Sp1),.levelIdx(levelIdx+1),.pipeInterval(pipeInterval))
              ATI1(clk,en,DIn[0+:Sp1*data_depth],subLevelSum1);

if(Sp2==1)
    assign subLevelSum2=DIn[Sp1*data_depth+:data_depth];
else
    MFP_AdderTree #(.data_depth(data_depth),.ArrL(Sp2),.levelIdx(levelIdx+1),.pipeInterval(pipeInterval))
              ATI1(clk,en,DIn[Sp1*data_depth+:Sp2*data_depth],subLevelSum2);


endgenerate


    endmodule

`endif