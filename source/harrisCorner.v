

module harrisCornerResponse
#(
parameter 
ImageW=640,
dataW=8,
outW=dataW,
cornorwindowSize=5,
suppressSmoothRegion=1,
ts=8
)
(
input clk,input en,input rst,
input [dataW*3-1:0]dataCol3X1,
output [outW-1:0]cornerResponse
);


wire [dataW*3-1:0]Buff3x1=dataCol3X1;

/*

ScanLWindow_blkRAM_adv #(
.block_height(3),
.block_width(1),.frame_width(ImageW),
.pixel_depth(dataW)) win1(clk,en,dataIn,Buff3x1);*/




wire signed[dataW+2+1-1:0]XEdge;
wire signed[dataW+2+1-1:0]YEdge;

sobelEdge
#(.dataW(dataW))
(clk, en,Buff3x1,XEdge,YEdge);

	
wire signed[dataW+2-1:0]XEdge_scale=XEdge/2;
wire signed[dataW+2-1:0]YEdge_scale=YEdge/2;



wire signed[dataW-1:0]Ix;
wire signed[dataW-1:0]Iy;
parameter satbits=1;
MFP_Saturate#(.InW(dataW+2),.Sat2W(dataW-satbits),.OutW(dataW),.isUnsigned(0)) 
sobelXsat(XEdge_scale,Ix);//saturate => prevent big number

MFP_Saturate#(.InW(dataW+2),.Sat2W(dataW-satbits),.OutW(dataW),.isUnsigned(0)) 
sobelYsat(YEdge_scale,Iy);


parameter mulW=dataW;
wire signed[mulW-1:0]IxIx;//signed
MFP_Multi #(.In1W(dataW-satbits),.OutW(mulW),.isUnsigned(0)) 
m_a(Ix,Ix,IxIx);
wire signed[mulW-1:0]IyIy;
MFP_Multi #(.In1W(dataW-satbits),.OutW(mulW),.isUnsigned(0)) 
m_c(Iy,Iy,IyIy);
wire signed[mulW-1:0]IxIy;
MFP_Multi #(.In1W(dataW-satbits),.OutW(mulW),.isUnsigned(0)) 
m_b(Iy,Ix,IxIy);


	
wire [32*cornorwindowSize-1:0]WinX_Coeffs;
wire [mulW*cornorwindowSize-1:0]IxIx_col;
wire [mulW*cornorwindowSize-1:0]IyIy_col;
wire [mulW*cornorwindowSize-1:0]IxIy_col;
/*
ScanLWindow_blkRAM_32W #(.block_height(cornorwindowSize),.block_width(1),
.frame_width(ImageW)) cornorWindow(clk,en,{IxIy,IyIy,IxIx},WinX_Coeffs);

groupArrReOrderBABA2BBAA#
(.Arr1EleW(mulW),.Arr2EleW(mulW),.Arr3EleW(mulW),.Arr4EleW(32-mulW*3),.ArrL(cornorwindowSize))
gARO_cornorWindow(WinX_Coeffs,{IxIy_col,IyIy_col,IxIx_col});
*/


ScanLWindow_blkRAM_adv #(
.block_height(cornorwindowSize),
.block_width(1),.frame_width(ImageW),
.pixel_depth(mulW)) winIxIx(clk,en,IxIx,IxIx_col);

ScanLWindow_blkRAM_adv #(
.block_height(cornorwindowSize),
.block_width(1),.frame_width(ImageW),
.pixel_depth(mulW)) winIxIy(clk,en,IxIy,IxIy_col);

ScanLWindow_blkRAM_adv #(
.block_height(cornorwindowSize),
.block_width(1),.frame_width(ImageW),
.pixel_depth(mulW)) winIyIy(clk,en,IyIy,IyIy_col);



parameter abcColSumW=mulW+1+($clog2(cornorwindowSize)+1);
/*append each elements in col*/

wire [abcColSumW*cornorwindowSize-1:0]IxIx_col_append;
wire [abcColSumW*cornorwindowSize-1:0]IyIy_col_append;
wire [abcColSumW*cornorwindowSize-1:0]IxIy_col_append;
genvar gi;

generate
	for(gi=0;gi<cornorwindowSize;gi=gi+1)begin:appendLoop
		wire signed[mulW-1:0]IxIx_=IxIx_col[gi*mulW+:mulW];
		wire signed[abcColSumW-1:0]IxIx_append=IxIx_;
		assign IxIx_col_append[gi*abcColSumW+:abcColSumW]=IxIx_append;
		wire signed[mulW-1:0]IyIy_=IyIy_col[gi*mulW+:mulW];
		wire signed[abcColSumW-1:0]IyIy_append=IyIy_;
		assign IyIy_col_append[gi*abcColSumW+:abcColSumW]=IyIy_append;
		wire signed[mulW-1:0]IxIy_=IxIy_col[gi*mulW+:mulW];
		wire signed[abcColSumW-1:0]IxIy_append=IxIy_;
		assign IxIy_col_append[gi*abcColSumW+:abcColSumW]=IxIy_append;
	end
endgenerate 



wire signed[abcColSumW-1:0]IxIx_col_sum;
wire signed[abcColSumW-1:0]IyIy_col_sum;
wire signed[abcColSumW-1:0]IxIy_col_sum;

MFP_AdderTree
    #(.data_depth(abcColSumW),.ArrL(cornorwindowSize),.isUnsigned(0),
	 .pipeInterval(999)
     )AdderTree_aij(
       clk,en,IxIx_col_append,IxIx_col_sum);

MFP_AdderTree
    #(.data_depth(abcColSumW),.ArrL(cornorwindowSize),.isUnsigned(0),
	 .pipeInterval(999)
     )AdderTree_cij(
       clk,en,IyIy_col_append,IyIy_col_sum);
		 
MFP_AdderTree
    #(.data_depth(abcColSumW),.ArrL(cornorwindowSize),.isUnsigned(0),
	 .pipeInterval(999)
     )AdderTree_bij(
       clk,en,IxIy_col_append,IxIy_col_sum);
		 


reg [abcColSumW*cornorwindowSize-1:0]IxIx_col_sum_SR;//shiftReg
reg [abcColSumW*cornorwindowSize-1:0]IyIy_col_sum_SR;
reg [abcColSumW*cornorwindowSize-1:0]IxIy_col_sum_SR;


always@(posedge clk or posedge rst)
	if(rst)begin
		IxIx_col_sum_SR<=0;
		IyIy_col_sum_SR<=0;
		IxIy_col_sum_SR<=0;
	end else if(en)begin
		IxIx_col_sum_SR<={IxIx_col_sum_SR,IxIx_col_sum};
		IyIy_col_sum_SR<={IyIy_col_sum_SR,IyIy_col_sum};
		IxIy_col_sum_SR<={IxIy_col_sum_SR,IxIy_col_sum};
	end


//wire signed[abcColSumW-1:0]	IxIx_cs_head=IxIx_col_sum_SR[0+:abcColSumW];
wire signed[abcColSumW-1:0]	IxIx_cs_tail=
IxIx_col_sum_SR[abcColSumW*(cornorwindowSize-1)+:abcColSumW];

//wire signed[abcColSumW-1:0]	IxIy_cs_head=IxIy_col_sum_SR[0+:abcColSumW];
wire signed[abcColSumW-1:0]	IxIy_cs_tail=
IxIy_col_sum_SR[abcColSumW*(cornorwindowSize-1)+:abcColSumW];

//wire signed[abcColSumW-1:0]	IyIy_cs_head=IyIy_col_sum_SR[0+:abcColSumW];
wire signed[abcColSumW-1:0]	IyIy_cs_tail=
IyIy_col_sum_SR[abcColSumW*(cornorwindowSize-1)+:abcColSumW];


localparam cornorwindowDim=cornorwindowSize*cornorwindowSize;
parameter abcWinSumW=mulW+1+($clog2(cornorwindowDim)+1);		 

reg signed[abcWinSumW-1:0]IxIy_win_sum,IyIy_win_sum,IxIx_win_sum;


always@(posedge clk or posedge rst)
	if(rst)begin
		IxIx_win_sum<=0;
		IyIy_win_sum<=0;
		IxIy_win_sum<=0;
	end else if(en)begin
		IxIx_win_sum<= IxIx_win_sum+IxIx_col_sum-IxIx_cs_tail;
		IyIy_win_sum<= IyIy_win_sum+IyIy_col_sum-IyIy_cs_tail;
		IxIy_win_sum<= IxIy_win_sum+IxIy_col_sum-IxIy_cs_tail;
	end




localparam win_sum_satW=3;
wire signed[abcWinSumW-win_sum_satW-1:0]IxIx_win_sum_sat;
wire signed[abcWinSumW-win_sum_satW-1:0]IyIy_win_sum_sat;
wire signed[abcWinSumW-win_sum_satW-1:0]IxIy_win_sum_sat;

MFP_Saturate#(.InW(abcWinSumW),.OutW(abcWinSumW-win_sum_satW),.isUnsigned(0)) 
winSumIxxSat(IxIx_win_sum,IxIx_win_sum_sat);
MFP_Saturate#(.InW(abcWinSumW),.OutW(abcWinSumW-win_sum_satW),.isUnsigned(0)) 
winSumIxySat(IxIy_win_sum,IxIy_win_sum_sat);
MFP_Saturate#(.InW(abcWinSumW),.OutW(abcWinSumW-win_sum_satW),.isUnsigned(0)) 
winSumIyySat(IyIy_win_sum,IyIy_win_sum_sat);


wire signed[dataW-1:0]IxIx_sum_round;
wire signed[dataW-1:0]IyIy_sum_round;
wire signed[dataW-1:0]IxIy_sum_round;

MFP_Round
#(.InW(abcWinSumW-win_sum_satW),.OutW(dataW),.isFloor(1),.isUnsigned(0)) 
IxIxRound(IxIx_win_sum_sat,IxIx_sum_round);
MFP_Round
#(.InW(abcWinSumW-win_sum_satW),.OutW(dataW),.isFloor(1),.isUnsigned(0)) 
IyIyRound(IyIy_win_sum_sat,IyIy_sum_round);
MFP_Round
#(.InW(abcWinSumW-win_sum_satW),.OutW(dataW),.isFloor(1),.isUnsigned(0)) 
IxIyRound(IxIy_win_sum_sat,IxIy_sum_round);



wire signed[outW+3-1:0]aijcij;


wire signed[dataW-1:0]IxIx_sum_roundSubts=IxIx_sum_round-ts;
MFP_Multi #(.In1W(dataW),.OutW(outW+3),.isUnsigned(0)) m_ac(IxIx_sum_roundSubts,IyIy_sum_round-ts,aijcij);		
wire isOnEdge=(suppressSmoothRegion)?(!IxIx_sum_roundSubts[dataW-1]):1;
	
	
	
wire signed[outW+3-1:0]bijbij;
MFP_Multi #(.In1W(dataW),.OutW(outW+3),.isUnsigned(0)) m_bb(IxIy_sum_round,IxIy_sum_round,bijbij);	
	

wire signed[outW+1-1:0]acSbb=aijcij/4-bijbij/4;
	
assign cornerResponse=((!acSbb[outW])&(isOnEdge))?acSbb:0;
	
endmodule
