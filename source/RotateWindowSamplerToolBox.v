
module BilinearInterpolator
#(
	parameter
	dataW=8,
	outputW=dataW,
	interpolateBits=4,
	nonPipe=1
)(input clk,en,
input [dataW*4-1:0]Pix4,
input [interpolateBits-1:0]xalpha,
input [interpolateBits-1:0]yalpha,
output [outputW-1:0]interp
);

/*
Pix4={p3,p2,p1,p0}
xalp
|   |	
p0-----o---p1  -
       |        yalp
       A      -
       |
       |      
       |      
p2-----o---p3

when
xalp=yalp=0
=> A=p0

when
xalp=0 yalp=0.999(it's fixed-point style)
=> A is close to p2 
*/
	reg signed[dataW+1-1:0]neib[0:3];
	reg signed[interpolateBits-1:0]xalp,yalp;
	always@(posedge clk)if(en)begin
		xalp=xalpha;
		yalp=yalpha;
		neib[0]=Pix4[0*dataW+:dataW];
		neib[1]=Pix4[1*dataW+:dataW];
		neib[2]=Pix4[2*dataW+:dataW];
		neib[3]=Pix4[3*dataW+:dataW];
	end
	
	wire [dataW+interpolateBits-1:0]interX0_,interX1_;
	assign interX0_=(neib[1]-neib[0])*xalp+(neib[0]<<interpolateBits);
	assign interX1_=(neib[3]-neib[2])*xalp+(neib[2]<<interpolateBits);
	
	
	wire signed[dataW+1-1:0]interX0,interX1;
	assign interX0=interX0_>>interpolateBits;
	assign interX1=interX1_>>interpolateBits;
	
	wire [dataW+interpolateBits-1:0]interRes=
	(interX1-interX0)*yalp+(interX0<<interpolateBits);
	
	
	assign interp=interRes
	>>(interpolateBits-outputW+dataW);
endmodule



module SampleObjArrEval
#(
	parameter
	dataW=8,
	ArrL=4*4,
	interpolateBits=4,
	ObjW=dataW*4+interpolateBits*2,
	outputW=8,
	nonPipe=1
)(input clk,en,
input [ArrL*ObjW-1:0]sampleObjectArr,
output [ArrL*outputW-1:0]interp
);

	genvar gi;
generate
	for(gi=0;gi<ArrL;gi=gi+1)begin:Loop
	
		wire [ObjW-1:0]obj=sampleObjectArr[((gi)*ObjW)+:ObjW];
		BilinearInterpolator#(.dataW(dataW),.outputW(outputW),
		.interpolateBits(interpolateBits),.nonPipe(nonPipe))
		BI(clk,en,obj[ObjW-1-:dataW*4],obj[0+:interpolateBits],obj[0+interpolateBits+:interpolateBits],interp[gi*outputW+:outputW]);
	end
	
endgenerate
	
endmodule



module windowSamplerObj
#(
	parameter
	x=0,
	y=0,
	winW=5,
	winH=winW,//x=y=0 is at window 2,2
	interpolateBits=4,
	dataW=8,
	objW=dataW*4+interpolateBits*2
)
(input clk,en,
input [winW*winH*dataW-1:0]window,
output [dataW*4+interpolateBits*2-1:0]sampleObject
);

localparam xos=x+(winW-1)/2.0;
localparam yos=y+(winH-1)/2.0;

localparam integer loX=xos-0.5;//it's rounding by default
localparam integer loY=yos-0.5;
localparam integer HiX=loX+1;
localparam integer HiY=loY+1;


real xx,yy,aa,zz;
initial begin
	xx=xos;
	yy=loX;
	aa=xalpha;
	zz=xalpH;
end

//  O----o--O  alpha=0.7
//  @-------O  alpha=0.0
localparam xalpha=xos-loX;
localparam yalpha=yos-loY;

localparam integer xalpH=xalpha*((2**interpolateBits)-1);
localparam integer yalpH=yalpha*((2**interpolateBits)-1);

localparam integer xalpL=(2**interpolateBits)-xalpH;
localparam integer yalpL=(2**interpolateBits)-yalpH;
generate



if(loX>=0&&loY>=0&&HiX<winW&&HiY<winH)begin
	wire [interpolateBits-1:0]xalp=xalpH,yalp=yalpH;

	assign sampleObject=
	{
		window[(HiY*winW+HiX)*dataW+:dataW],//3
		window[(HiY*winW+loX)*dataW+:dataW],//2
		window[(loY*winW+HiX)*dataW+:dataW],//1
		window[(loY*winW+loX)*dataW+:dataW],//0
		yalp,xalp
	};
end
else
begin
 assign sampleObject=0;

end

endgenerate
endmodule



module windowRotate_89_9_Obj
#(
	parameter
	sin=0,
	cos=1,
	scaleF=0.999,
	winW=5,
	winH=winW,
	interpolateBits=4,
	dataW=8
)
(input clk,en,
input [winW*winH*dataW-1:0]window,
output [winW*winH*objW-1:0]window_samObjs_pre
);
	localparam
	objW=dataW*4+interpolateBits*2,
	sin_s=sin*scaleF,
	cos_s=cos*scaleF,
	xf=-(winW-1)/2.0,
	yf=-(winH-1)/2.0;
	
	

	genvar gx;
	genvar gy;
generate
	for(gy=0;gy<winH;gy=gy+1)begin:yLoop
		for(gx=0;gx<winW;gx=gx+1)begin:sxLoop
			windowSamplerObj
			#(.x((gx+xf)*cos_s-(gy+yf)*sin_s),.y((gx+xf)*sin_s+(gy+yf)*cos_s),.winW(winH),.winH(winH),
			.interpolateBits(interpolateBits),.dataW(dataW))  
				wS(clk,en,window,window_samObjs_pre[objW*(gy*winW+gx)+:objW]);
		end
	end
	
endgenerate

endmodule



module windowRotate360
#(
	parameter
	winW=5,
	winH=winW,//x=y=0 is at window 2,2
	interpolateBits=4,
	dataW=8,
	outputW=dataW,
	nonPipe=1
)
(input clk,en,input [6-1:0]rotate0_36,
input [winW*winH*dataW-1:0]windowIn,
output [winW*winH*outputW-1:0]window_SS
);
reg rdy;
initial #100 rdy=1;
localparam 
	objW=dataW*4+interpolateBits*2;


wire [winW*winH*objW-1:0]window_rotate_OBJ[0:8];//9 angle per domain
reg [6-1:0]rotate;
reg [winW*winH*objW-1:0]window_rotate_OBJArr;
reg [winW*winH*dataW-1:0]window;
always @(posedge clk)if(en)begin
	window<=windowIn;
	rotate<=rotate0_36;
end
windowRotate_89_9_Obj#(.sin(0),.cos(1),.winW(winW),.winH(winH),.dataW(dataW),.interpolateBits(interpolateBits))
wS0(clk,en,window,window_rotate_OBJ[0]);
/*windowRotate_89_9_Obj#(.sin(0.17365),.cos(0.98481),.winW(winW),.winH(winH),.dataW(dataW),.interpolateBits(interpolateBits))
wS1(clk,en,window,window_rotate_OBJ[1]);
windowRotate_89_9_Obj#(.sin(0.34202),.cos(0.93969),.winW(winW),.winH(winH),.dataW(dataW),.interpolateBits(interpolateBits))
wS2(clk,en,window,window_rotate_OBJ[2]);
windowRotate_89_9_Obj#(.sin(0.5),.cos(0.86603),.winW(winW),.winH(winH),.dataW(dataW),.interpolateBits(interpolateBits))
wS3(clk,en,window,window_rotate_OBJ[3]);
windowRotate_89_9_Obj#(.sin(0.6428),.cos(0.76604),.winW(winW),.winH(winH),.dataW(dataW),.interpolateBits(interpolateBits))
wS4(clk,en,window,window_rotate_OBJ[4]);
windowRotate_89_9_Obj#(.sin(0.76604),.cos(0.6428),.winW(winW),.winH(winH),.dataW(dataW),.interpolateBits(interpolateBits))
wS5(clk,en,window,window_rotate_OBJ[5]);
windowRotate_89_9_Obj#(.sin(0.86603),.cos(0.5),.winW(winW),.winH(winH),.dataW(dataW),.interpolateBits(interpolateBits))
wS6(clk,en,window,window_rotate_OBJ[6]);
windowRotate_89_9_Obj#(.sin(0.93969),.cos(0.34202),.winW(winW),.winH(winH),.dataW(dataW),.interpolateBits(interpolateBits))
wS7(clk,en,window,window_rotate_OBJ[7]);
windowRotate_89_9_Obj#(.sin(0.98481),.cos(0.17365),.winW(winW),.winH(winH),.dataW(dataW),.interpolateBits(interpolateBits))
wS8(clk,en,window,window_rotate_OBJ[8]);*/
/*
SampleObjArrEval#(.dataW(dataW),.ArrL(winW*winH),.interpolateBits(interpolateBits),
.outputW(outputW),.nonPipe(nonPipe)
) SOAEval(clk,en,window_rotate_OBJ[rotate],window_SS);*/

wire [objW-1:0]Current_rotate_OBJ=window_rotate_OBJArr;
always @(posedge clk)if(en)begin
	rdy<=~rdy;
	if(rdy)begin
		window_rotate_OBJArr<=window_rotate_OBJ[0];
		rdy<=0;
	end
	else
		window_rotate_OBJArr<=window_rotate_OBJArr[winW*winH*objW-1:objW];
end
SampleObjArrEval#(.dataW(dataW),.ArrL(1),.interpolateBits(interpolateBits),
.outputW(outputW),.nonPipe(nonPipe)
) SOAEval(clk,en,Current_rotate_OBJ,window_SS);


endmodule