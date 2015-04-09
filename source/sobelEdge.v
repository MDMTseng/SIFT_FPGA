

module sobelEdge
#(
parameter 
dataW=8,
pipeInterval=0,
outW=dataW+2+1
)
(
input clk,input en,
input [dataW*windowSize-1:0]PixCol3x1,
output signed[outW-1:0]XEdge,
output signed[outW-1:0]YEdge
);
	
localparam windowSize=3;
//Y Edge detect
/*

[
1
2
1
]
*
[-1 0 1]
=
-1 0 1
-2 0 2
-1 0 1
*/ 
wire  [dataW+2-1:0]YFilter=(PixCol[0*dataW+:dataW]+PixCol[1*dataW+:dataW]*2+PixCol[2*dataW+:dataW]);
wire  [(dataW+2)*windowSize-1:0]DY_ShiftReg;
always@(posedge clk)if(en)DY_ShiftReg<={DY_ShiftReg,YFilter};
wire  [dataW+2-1:0]DY0=DY_ShiftReg[0+:dataW+2];
wire  [dataW+2-1:0]DY2=DY_ShiftReg[2*(dataW+2)+:dataW+2];
assign YEdge=DY0-DY2;

//X Edge detect
/*

[
-1
0
1
]
*
[1 2 1]
=
-1 -2 -1
 0  0  0
 1  2  1
*/ 

wire signed[dataW+1-1:0]XFilter=(PixCol[0*dataW+:dataW]-PixCol[2*dataW+:dataW]);
wire  [(dataW+1)*windowSize-1:0]DX_ShiftReg;
always@(posedge clk)if(en)DX_ShiftReg<={DX_ShiftReg,XFilter};
wire  signed[dataW+1-1:0]DX0=DX_ShiftReg[0+:dataW+1];
wire  signed[dataW+1-1:0]DX1=DX_ShiftReg[1*(dataW+1)+:dataW+1];
wire  signed[dataW+1-1:0]DX2=DX_ShiftReg[2*(dataW+1)+:dataW+1];
assign XEdge=DX0+DX1*2+DX2;




	
endmodule
