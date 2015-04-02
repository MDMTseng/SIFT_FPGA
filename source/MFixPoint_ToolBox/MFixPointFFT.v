`ifndef MFIXPOINT_FFT_
`define MFIXPOINT_FFT_
	`ifndef MFIXPOINT_BASIC_ //dependency
	`include "MFixPointBasic.v"
	`endif
	
	`ifndef MFIXPOINT_TABLES_ //dependency
	`include "MFixPointTables.v"
	`endif
module MFP_FFT_BF_recur
#(parameter
 FFTL=8,
 InW=16,
 pipeInterval=0,
 level=0,
 Saturate=0,
 isFloor=0
	)(
		input clk,input en,
	   input [InW*FFTL-1:0]DIn_R,//....,R2,R1,R0
	   input [InW*FFTL-1:0]DIn_I,//....,I2,I1,I0
	   output [InW*FFTL-1:0]DOut_R,
	   output [InW*FFTL-1:0]DOut_I
	);

	
	MFP_FFT_BF#(.FFTL(FFTL),.InW(InW),.level(level),.pipeInterval(pipeInterval),.Saturate(Saturate),.isFloor(isFloor)) fftBf1(clk,en,DIn_R,DIn_I,DOut_R,DOut_I);
endmodule


module MFP_iFFT
#(parameter
 FFTL=8,
 FFTW=16,
 OutW=FFTW,
 pipeInterval=0,
 Saturate=0,
 isFloor=0)(
	input clk,input en,
   input [FFTW*FFTL-1:0]DIn_R,//....,R2,R1,R0
   input [FFTW*FFTL-1:0]DIn_I,//....,I2,I1,I0
   output [OutW*FFTL-1:0]DOut_R,
   output [OutW*FFTL-1:0]DOut_I
 );
wire [FFTW*FFTL-1:0]DIn_I_neg;
wire [FFTW*FFTL-1:0]DOut_I_neg;
wire [FFTW*FFTL-1:0]DOut_R_tmp;


wire [FFTW*FFTL-1:0]DOut_I_p;//with padding
wire [FFTW*FFTL-1:0]DOut_R_p;
parameter outShift=$clog2(FFTL);
generate
	genvar i,j;
	
	for(i=0;i<FFTL;i=i+1)begin:negLoop
		wire signed[FFTW-1:0]tmp=DIn_I[i*FFTW+:FFTW];
		assign DIn_I_neg[i*FFTW+:FFTW]=-tmp;
		
		wire signed[FFTW-1:0]tmpI=DOut_I_neg[i*FFTW+:FFTW];
		wire signed[FFTW-1:0]tmpR=DOut_R_tmp[i*FFTW+:FFTW];
		 
		
		MFP_Round#(.InW(FFTW),.OutW(OutW),.isFloor(isFloor),.Saturate(Saturate)) roun0( (tmpR>>>outShift),DOut_R[i*OutW+:OutW]);
		MFP_Round#(.InW(FFTW),.OutW(OutW),.isFloor(isFloor),.Saturate(Saturate)) roun1(-(tmpI>>>outShift),DOut_I[i*OutW+:OutW]);
		
	end
endgenerate
	   
	
MFP_FFT#(.FFTL(FFTL),.InW(FFTW),.pipeInterval(pipeInterval),.Saturate(Saturate),.isFloor(isFloor)) fftBf1(clk,en,DIn_R,DIn_I_neg,DOut_R_tmp,DOut_I_neg);
	   
	   
endmodule

module MFP_FFT
#(parameter
 FFTL=8,
 InW=16,
 FFTW=InW,
 pipeInterval=0,
 Saturate=0,
 isFloor=0)(
	input clk,input en,
   input [InW*FFTL-1:0]DIn_R,//....,R2,R1,R0
   input [InW*FFTL-1:0]DIn_I,//....,I2,I1,I0
   output [FFTW*FFTL-1:0]DOut_R,
   output [FFTW*FFTL-1:0]DOut_I
 );

	   
	wire [FFTW*FFTL-1:0]DIn_R_rev,DIn_I_rev;
	
wire [$clog2(FFTL)-1:0]idx[FFTL-1:0];
wire [$clog2(FFTL)-1:0]idx_rev[FFTL-1:0];
wire [FFTW-InW-1:0]zeroPadding=0;

parameter clog2FFTL=$clog2(FFTL);
generate
	genvar i,j;
	for(i=0;i<FFTL;i=i+1)begin:revL
		assign idx[i]=i;
		for(j=0;j<clog2FFTL;j=j+1)begin:idx_revLoop
			assign idx_rev[i][j]=idx[i][$clog2(FFTL)-1-j];
		end
		if(FFTW>InW)begin
			assign DIn_R_rev[i*FFTW+:FFTW]={DIn_R[idx_rev[i]*InW+:InW],zeroPadding};
			assign DIn_I_rev[i*FFTW+:FFTW]={DIn_I[idx_rev[i]*InW+:InW],zeroPadding};
		end else begin
			
			assign DIn_R_rev[i*FFTW+:FFTW]={DIn_R[idx_rev[i]*InW+:InW]};
			assign DIn_I_rev[i*FFTW+:FFTW]={DIn_I[idx_rev[i]*InW+:InW]};
		end
	end
endgenerate
	
	MFP_FFT_BF#(.FFTL(FFTL),.InW(FFTW),.level(0),.pipeInterval(pipeInterval),.Saturate(Saturate),.isFloor(isFloor)) fftBf1(clk,en,DIn_R_rev,DIn_I_rev,DOut_R,DOut_I);

	   
endmodule
module MFP_FFT_BF
#(parameter
 FFTL=8,
 InW=16,
 pipeInterval=0,
 level=0,
 Saturate=0,
 isFloor=0
	)(
		input clk,input en,
	   input [InW*FFTL-1:0]DIn_R,//....,R2,R1,R0
	   input [InW*FFTL-1:0]DIn_I,//....,I2,I1,I0
	   output [InW*FFTL-1:0]DOut_R,
	   output [InW*FFTL-1:0]DOut_I
	);
 
		localparam SPL=FFTL/2; //Split
	wire[InW-1:0] Re_W[SPL-1:0];//hard wiring coeff
	wire[InW-1:0] Im_W[SPL-1:0];
	integer i;
	
	genvar gi;
	generate
	 for(gi=1;gi<SPL;gi=gi+1)begin:WsettingLoop
			MFP_ReW_ConstTable#(.k(gi),.N(FFTL),.outputW(InW))CCXRe(Re_W[gi]);
			MFP_ImW_ConstTable#(.k(gi),.N(FFTL),.outputW(InW))CCXIm(Im_W[gi]);
		end
	endgenerate
	
	
	wire [InW*SPL-1:0]DIn0_R=DIn_R[0+:InW*SPL],DIn0_I=DIn_I[0+:InW*SPL];
	wire [InW*SPL-1:0]DIn1_R=DIn_R[InW*SPL+:InW*SPL],DIn1_I=DIn_I[InW*SPL+:InW*SPL];
	
	
	wire [InW*SPL-1:0]PreStageO0_R,PreStageO0_I;
	wire [InW*SPL-1:0]PreStageO1_R,PreStageO1_I;//second section need to do multiply with W
	wire [InW*SPL-1:0]PreStageO1_R_p,PreStageO1_I_p;//second section need to do multiply with W
	
	wire[InW*FFTL-1:0]DOut_I_pipe,DOut_R_pipe;
	generate
		if(SPL==1)begin
			assign PreStageO0_R=DIn0_R;
			assign PreStageO1_R=DIn1_R;
			assign PreStageO0_I=DIn0_I;
			assign PreStageO1_I=DIn1_I;
		end else begin
			MFP_FFT_BF_recur#(.FFTL(SPL),.InW(InW),.level(level+1),.pipeInterval(pipeInterval),.Saturate(Saturate),.isFloor(isFloor)) fftBf0
			(clk,en,DIn0_R,DIn0_I,PreStageO0_R,PreStageO0_I);
			MFP_FFT_BF_recur#(.FFTL(SPL),.InW(InW),.level(level+1),.pipeInterval(pipeInterval),.Saturate(Saturate),.isFloor(isFloor)) fftBf1
			(clk,en,DIn1_R,DIn1_I,PreStageO1_R,PreStageO1_I);
		end
		
	assign PreStageO1_R_p[0+:InW]=PreStageO1_R[0+:InW];
		assign PreStageO1_I_p[0+:InW]=PreStageO1_I[0+:InW];
		for(gi=1;gi<SPL;gi=gi+1)begin:mulW// *W
			wire signed[InW-1:0]ReW=Re_W[gi];
			wire signed[InW-1:0]ImW=Im_W[gi];
			
			wire signed[InW:0]SpC=ImW+ReW;
			wire signed[InW:0]SsC=ImW-ReW;
			MFP_Mul_Complex #(.InXYW(InW),.OutW(InW),.Saturate(Saturate),.isFloor(isFloor)) MC(
			PreStageO1_R[gi*InW+:InW],PreStageO1_I[gi*InW+:InW],
			ReW,ImW,SpC[1+:InW],SsC[1+:InW],
			PreStageO1_R_p[gi*InW+:InW],
			PreStageO1_I_p[gi*InW+:InW]);
		end
		
		
		for(gi=0;gi<SPL;gi=gi+1)begin:plusSub
		
		
			MFP_Add_Complex#(.InXYW(InW),.Saturate(Saturate)) Ac0(
			PreStageO0_R [gi*InW+:InW],PreStageO0_I [gi*InW+:InW],
			PreStageO1_R_p[gi*InW+:InW],PreStageO1_I_p[gi*InW+:InW],
			DOut_R_pipe     [gi*InW+:InW],DOut_I_pipe     [gi*InW+:InW]);//plus
			
			MFP_Add_Complex#(.InXYW(InW),.Saturate(Saturate)) Ac1(
			PreStageO0_R [gi*InW+:InW],PreStageO0_I [gi*InW+:InW],
			-PreStageO1_R_p[gi*InW+:InW],-PreStageO1_I_p[gi*InW+:InW],
			DOut_R_pipe     [(SPL+gi)*InW+:InW],DOut_I_pipe [(SPL+gi)*InW+:InW]);//sub
			
		end
		
	endgenerate
	
	localparam IsNotAStage=(pipeInterval==0)?1:level%pipeInterval!=0;
	generate//choose pipeline or not
		if(IsNotAStage)begin
			assign DOut_R=DOut_R_pipe;
			assign DOut_I=DOut_I_pipe;
		end else begin
			reg[InW*FFTL-1:0]DOut_I_reg,DOut_R_reg;
			always@(posedge clk)if(en)begin
				DOut_I_reg<=DOut_I_pipe;
				DOut_R_reg<=DOut_R_pipe;
			end
			assign DOut_R=DOut_R_reg;
			assign DOut_I=DOut_I_reg;
		end
	
	endgenerate
	
	
endmodule



module MFP_Mul_Complex
#(parameter
 InXYW=16,
 InCSW=InXYW,
 OutW=InXYW+InCSW-1,
 Saturate=0,
 isFloor=0
        )(
           input signed[InXYW-1:0]X_R,
           input signed[InXYW-1:0]Y_I,
           input signed[InCSW-1:0]C_R,
           input signed[InCSW-1:0]S_I,
           input signed[InCSW-1:0]SpC_d2,
		   //(S plus C)/2  => since S+C may greater than 1 so I extend 1 bit
           input signed[InCSW-1:0]SsC_d2,//(S sub C)/2
           output [OutW-1:0]DOut_R,
           output [OutW-1:0]DOut_I
       );
/*
(X+Yi)(C+Si)
XC-YS+(YC+XS)i=R+Ii
R=(X+Y)C-Y(S+C)=(X+Y)C-(SpC)Y
I=(X+Y)C+X(S-C)=(X+Y)C+(SsC)X
Mul_Complex MC
(1,1,3,4,
7,1,DOut_R,DOut_I);
*/

wire signed[InXYW-1:0]XpY;
wire signed[OutW-1:0]XpYmC;
MFP_Adder #(.In1W(InXYW),.In2W(InXYW),.OutW(InXYW),.Saturate(Saturate)) aS(X_R,Y_I,XpY);//X+Y
MFP_Multi #(.In1W(InXYW),.In2W(InCSW),.OutW(OutW),.Saturate(Saturate),.isFloor(isFloor)) m0(XpY,C_R,XpYmC);//(X+Y)C



wire signed[OutW-1:0]SpCmY,SsCmX;
MFP_Multi #(.In1W(InCSW),.In2W(InXYW),.OutW(OutW),.Saturate(Saturate),.isFloor(isFloor)) m1(SpC_d2,Y_I,SpCmY);//(SpC/2)Y*2
MFP_Multi #(.In1W(InCSW),.In2W(InXYW),.OutW(OutW),.Saturate(Saturate),.isFloor(isFloor)) m2(SsC_d2,X_R,SsCmX);//(SsC/2)X*2



MFP_Adder #(.In1W(OutW),.In2W(OutW),.OutW(OutW),.Saturate(Saturate)) aS0(XpYmC,-SpCmY*2,DOut_R);//XpYmC-SpCmY
MFP_Adder #(.In1W(OutW),.In2W(OutW),.OutW(OutW),.Saturate(Saturate)) aS1(XpYmC, SsCmX*2,DOut_I);//XpYmC+SsCmX


endmodule
module MFP_Add_Complex#(parameter
 InXYW=16,
 InCSW=InXYW,
 OutW=(InXYW>InCSW)?InXYW:InCSW,
 Saturate=0
        )(
           input [InXYW-1:0]X_R,
           input [InXYW-1:0]Y_I,
           input [InCSW-1:0]C_R,
           input [InCSW-1:0]S_I,
           output [OutW-1:0]DOut_R,
           output [OutW-1:0]DOut_I
       );
MFP_Adder #(.In1W(InXYW),.In2W(InCSW),.OutW(OutW),.Saturate(Saturate)) aS0(X_R,C_R,DOut_R);
MFP_Adder #(.In1W(InXYW),.In2W(InCSW),.OutW(OutW),.Saturate(Saturate)) aS1(Y_I,S_I,DOut_I);

endmodule


`endif