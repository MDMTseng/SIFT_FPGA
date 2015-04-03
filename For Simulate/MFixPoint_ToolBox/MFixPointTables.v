`ifndef MFIXPOINT_TABLES_
`define MFIXPOINT_TABLES_


module MFP_real
#(
parameter
fracNum=0,
outputW=8
)

(output signed[outputW-1:0]outData);
	parameter integer maxNum=(2**(outputW-1))-1;
	
	parameter integer  Y=(fracNum>=1)?maxNum:
	((fracNum<=-1)?(-maxNum):fracNum*(maxNum+1));
	assign outData=Y;
endmodule



/*
for simple setup
gaussianTable#(.x(X),.sig(SIGMA),.outputW(DATA_WIDTH)) gt2(OUTPUT);

for advence setup
gaussianTable#(.xsq(X*X/SIGMA/SIGMA+Y*Y/SIGMA/SIGMA)
,.sig(SIGMA),.outputW(DATA_WIDTH)) gt2(OUTPUT);
*/

module MFP_gaussianTable2D
#(
parameter
x=0,
y=0,
sig=1,
outputW=8,
scale=1
)

(output [outputW-1:0]outData);

MFP_gaussianTable#(.xsq(x*x+y*y),.dim(2),.sig(sig),.outputW(outputW),.scale(scale)) gt(outData);


endmodule


module MFP_gaussianTable
#(
parameter
x=0,
sig=1,
xsq=x*x,
dim=1,
outputW=8,
scale=1
)

(output [outputW-1:0]outData);

parameter sqrt2pi=2.50662827463100;


parameter xsqDSS=xsq*1.0/sig/sig;
//ty=exp(-xsqDSS/2)/sqrt2pi
//ty=exp(-xsq/(2*sig^2))/sqrt2pi
parameter ty=(xsqDSS<2.4*2.4)?
(1 
-(xsqDSS**1)/2
+(xsqDSS**2)/8
-(xsqDSS**3)/48
+(xsqDSS**4)/384
-(xsqDSS**5)/3840
+(xsqDSS**6)/46080
-(xsqDSS**7)/645120
+(xsqDSS**8)/10321920
-(xsqDSS**9)/185794560
+(xsqDSS**10)/3715891200
-(xsqDSS**11)/100/817496064
+(xsqDSS**12)/102400/19160064
)/sqrt2pi
:(4.0/(xsqDSS**3));//out region fitting
//y=toFixPoint(exp(xsqDSS/2)/(sqrt2pi*sig))
parameter y=scale*2*ty/(sig**(dim))/(sqrt2pi)*512/410;


MFP_real#(.fracNum(y),.outputW(outputW)) R(outData);
endmodule

module MFP_gaussianTableArr
#(
parameter
xstart=-5,
xend=5,
sig=1,
outputW=8,
scale=1,
negRaise=0.01
)
(output [outputW*xL-1:0]GaussianArr);
localparam xL=xend-xstart+1;

generate
	genvar i;
	for(i=0;i<xL;i=i+1)
	begin:l
		if(i+xstart<0)
		MFP_gaussianTable#(.x(i+xstart+negRaise),.sig(sig),.outputW(outputW),.scale(scale)) 
		gt(GaussianArr[i*outputW+:outputW]);
		else
		MFP_gaussianTable#(.x(i+xstart),.sig(sig),.outputW(outputW),.scale(scale))
		gt(GaussianArr[i*outputW+:outputW]);
		
	end
endgenerate

endmodule
module MFP_gaussianSum
#(
parameter
xstart=-5,
xend=5,
sig=1,
outputW=8,
scale=1
)
(output [outputW-1:0]GSum);
localparam xL=xend-xstart+1;

generate
	genvar i;
	for(i=0;i<xL;i=i+1)
	begin:l
		wire [outputW-1:0]GaussVar;
		wire [outputW-1:0]sum;
		if(i+xstart<0)
		MFP_gaussianTable#(.x(i+xstart+0.01),.sig(sig),.outputW(outputW),.scale(scale)) gt(GaussVar);
		else
		MFP_gaussianTable#(.x(i+xstart),.sig(sig),.outputW(outputW),.scale(scale)) gt(GaussVar);
		if(i>0)begin
			assign sum=l[i-1].sum+GaussVar;
		end else begin
			assign sum=GaussVar;
		end
	end
	assign GSum=l[xL-1].sum;
endgenerate

endmodule



module MFP_gaussian2DSum
#(
parameter
xstart=-5,
xend=5,
ystart=-5,
yend=5,
sig=1,
outputW=8,
scale=1
)
(output reg[outputW:0]GSum);
localparam xL=xend-xstart+1;
localparam yL=yend-ystart+1;

wire [outputW*xL*yL-1:0]GaussTable;

generate
	genvar i,j;
	for(i=0;i<yL;i=i+1)
	begin:l
		for(j=0;j<xL;j=j+1)
		begin:lsds
			MFP_gaussianTable2D#(.x(0.0+j+xstart),.y(0.0+i+ystart),.sig(sig),.outputW(outputW),.scale(scale)) 
			gt2(GaussTable[(i*xL+j)*outputW+:outputW]);
			
		end
	end
endgenerate
integer ai;
initial begin
	GSum=0;
	
	for(ai=0;ai<xL*yL;ai=ai+1)
	begin:lgen
		GSum=GSum+GaussTable[ai*outputW+:outputW];
	end

end


endmodule




module MFP_ReW_ConstTable
#
(parameter   
k=1023,
N=1024,
outputW=16
)(output signed[outputW-1:0] y);
	MFP_Cos_ConstTable#(.x(-2.0*k/N),.outputW(outputW)) CT(y);
endmodule


module MFP_ImW_ConstTable
#
(parameter   
k=1023,
N=1024,
outputW=16
)(output signed[outputW-1:0] y);
	MFP_Cos_ConstTable#(.x(-2.0*k/N-0.5),.outputW(outputW)) CT(y);
endmodule


module MFP_Cos_ConstTable
#
(parameter   x=0.5,
outputW=16
)(output signed[outputW-1:0] y);

	parameter PI_=3.1415926535898;
	parameter   absx=((x<0)?-x:x);
	parameter integer absx_d_2=absx/2;
	parameter integer absx_int=absx;
	parameter integer absx_mod_int_2=absx_int%2;
	parameter   tmp=absx-absx_int+absx_mod_int_2-1;
	parameter   tx=(((tmp<0)?-tmp:tmp)-0.5)*PI_;
	
	parameter cos= (+(tx)
	-(tx*tx*tx)/6
	+(tx*tx*tx*tx*tx)/120
	-(tx*tx*tx*tx*tx*tx*tx)/5040
	+(tx*tx*tx*tx*tx*tx*tx*tx*tx)/362880)
	; 
	
	MFP_real#(.fracNum(cos),.outputW(outputW)) R(y);
	/*parameter integer maxNum=2**(outputW-1)-1;
	parameter integer  Y=(cos>=1)?maxNum:
	((cos<=-1)?-maxNum:cos*maxNum);
	assign y=Y;*/
	
endmodule

`endif