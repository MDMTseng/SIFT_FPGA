
module windowSampler
#(
	parameter
	x=0,
	y=0,
	winW=5,
	winH=winW,//x=y=0 is at window 2,2
	interpolateBits=4,
	dataW=8,
	outputW=dataW,
	nonPipe=1
)
(input clk,en,
input [winW*winH*dataW-1:0]window,
output [outputW-1:0]sample
);
real xx,yy;
initial begin
	xx=x;
	yy=y;
end


localparam xos=x+(winW-1)/2.0;
localparam yos=y+(winH-1)/2.0;

localparam integer loX=xos-0.5;
localparam integer loY=yos-0.5;
localparam integer HiX=loX+1;
localparam integer HiY=loY+1;
//  O----o--O  alpha=0.7
//  @-------O  alpha=0.0
localparam xalpha=xos-loX;
localparam yalpha=yos-loY;

localparam integer xalpH=xalpha*(2**interpolateBits);
localparam integer yalpH=yalpha*(2**interpolateBits);

localparam integer xalpL=(2**interpolateBits)-xalpH;
localparam integer yalpL=(2**interpolateBits)-yalpH;
generate
if(loX>=0&&loY>=0&&HiX<winW&&HiY<winH)begin
	wire [dataW-1:0]neib[0:3];

	MFP_RegOWire#(.dataW(dataW),.isWire(nonPipe)) RoW0(clk,en,window[(loY*winW+loX)*dataW+:dataW],neib[0]);
	MFP_RegOWire#(.dataW(dataW),.isWire(nonPipe)) RoW1(clk,en,window[(loY*winW+HiX)*dataW+:dataW],neib[1]);
	MFP_RegOWire#(.dataW(dataW),.isWire(nonPipe)) RoW2(clk,en,window[(HiY*winW+loX)*dataW+:dataW],neib[2]);
	MFP_RegOWire#(.dataW(dataW),.isWire(nonPipe)) RoW3(clk,en,window[(HiY*winW+HiX)*dataW+:dataW],neib[3]);

	wire [dataW-1:0]interX0,interX1;
	assign interX0=(neib[0]*xalpL+neib[1]*xalpH)>>interpolateBits;
	assign interX1=(neib[2]*xalpL+neib[3]*xalpH)>>interpolateBits;
	
	assign sample=(interX0*yalpL+interX1*yalpH)
	>>(interpolateBits-outputW+dataW);
	
	//MFP_RegOWire#(.dataW(outputW),.isWire(nonPipe)) RoW(clk,en,sample_tmp,sample);
	
end
else
begin
 assign sample=0;

end

endgenerate
endmodule


module windowRotate_89_9
#(
	parameter
	sin=0,
	cos=1,
	scaleF=0.95,
	winW=5,
	winH=winW,//x=y=0 is at window 2,2
	interpolateBits=4,
	dataW=8,
	outputW=dataW,
	nonPipe=1
)
(input clk,en,sel,
input [winW*winH*dataW-1:0]window,
output [winW*winH*outputW-1:0]window_rotate_tribus
);
	localparam
	sin_s=sin*scaleF,
	cos_s=cos*scaleF;

	localparam
	xf=-(winW-1)/2.0,
	yf=-(winH-1)/2.0;
	
	
wire [winW*winH*outputW-1:0]window_rotate_pre;
wire BusOutSel;
   MFP_RegOWire #(.dataW(1),.isWire(nonPipe))RoW(clk,en,sel,BusOutSel);

assign window_rotate_tribus = (BusOutSel)? window_rotate_pre :{winW*winH*outputW{1'bZ}};

//MFP_RegOWire#(.dataW(winW*winH*outputW),.isWire(nonPipe)) RoW(clk,en,window_rotate_pre,window_rotate);



	genvar gx;
	genvar gy;
generate
if(sin!=0)
	for(gy=0;gy<winH;gy=gy+1)begin:yLoop
		for(gx=0;gx<winW;gx=gx+1)begin:sxLoop
			windowSampler
			#(.x((gx+xf)*cos_s-(gy+yf)*sin_s),.y((gx+xf)*sin_s+(gy+yf)*cos_s),.winW(winH),.winW(winH),
			.interpolateBits(interpolateBits),.dataW(dataW),.outputW(outputW),.nonPipe(nonPipe))  
				wS(clk,sel&en,window,window_rotate_pre[outputW*(gy*winW+gx)+:outputW]);
		end
	end
else
	begin
		wire [winW*winH*outputW-1:0]window_rotate_pre_pre;
		for(gy=0;gy<winH;gy=gy+1)begin:yLoop
			for(gx=0;gx<winW;gx=gx+1)begin:sxLoop
				if(outputW<=dataW)
					assign window_rotate_pre_pre[outputW*(gy*winW+gx)+:outputW]=
					{window[dataW*(gy*winW+gx+1)-1-:outputW]};
				else
					assign window_rotate_pre_pre[outputW*(gy*winW+gx)+:outputW]=
					{window[dataW*(gy*winW+gx+1)-1-:dataW],{outputW-dataW{1'b0}}};
					
				
			end
		end
	
		MFP_RegOWire#(.dataW(winW*winH*outputW),.isWire(nonPipe)) RoW(clk,sel&en,window_rotate_pre_pre,window_rotate_pre);
	end
	
	
endgenerate




endmodule


/*
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
wire [winW*winH*outputW-1:0]window_rotate;//9 angle per domain
wire [6-1:0]rotate=rotate0_36;
reg [9-1:0]RoEn;

wire [winW*winH*dataW-1:0]window;
MFP_RegOWire#(.dataW(winW*winH*dataW),.isWire(0)) RoW(clk,en,windowIn,window);
always @(posedge clk)if(en)begin
	case(rotate)
	 0 : RoEn=9'b0_0000_0001; 
	 1 : RoEn=9'b0_0000_0010; 
	 2 : RoEn=9'b0_0000_0100; 
	 3 : RoEn=9'b0_0000_1000; 
	 4 : RoEn=9'b0_0001_0000; 
	 5 : RoEn=9'b0_0010_0000; 
	 6 : RoEn=9'b0_0100_0000; 
	 7 : RoEn=9'b0_1000_0000; 
	 8 : RoEn=9'b1_0000_0000; 
	 default : RoEn=9'bX_XXXX_XXXX;  
	endcase 
end

windowRotate_89_9#(.sin(0),.cos(1),.winW(winW),.dataW(dataW),.nonPipe(nonPipe))
wS0(clk,en,RoEn[0],window,window_rotate);
windowRotate_89_9#(.sin(0.17365),.cos(0.98481),.winW(winW),.dataW(dataW),.nonPipe(nonPipe))
wS1(clk,en,RoEn[1],window,window_rotate);
windowRotate_89_9#(.sin(0.34202),.cos(0.93969),.winW(winW),.dataW(dataW),.nonPipe(nonPipe))
wS2(clk,en,RoEn[2],window,window_rotate);
windowRotate_89_9#(.sin(0.5),.cos(0.86603),.winW(winW),.dataW(dataW),.nonPipe(nonPipe))
wS3(clk,en,RoEn[3],window,window_rotate);
windowRotate_89_9#(.sin(0.6428),.cos(0.76604),.winW(winW),.dataW(dataW),.nonPipe(nonPipe))
wS4(clk,en,RoEn[4],window,window_rotate);
windowRotate_89_9#(.sin(0.76604),.cos(0.6428),.winW(winW),.dataW(dataW),.nonPipe(nonPipe))
wS5(clk,en,RoEn[5],window,window_rotate);
windowRotate_89_9#(.sin(0.86603),.cos(0.5),.winW(winW),.dataW(dataW),.nonPipe(nonPipe))
wS6(clk,en,RoEn[6],window,window_rotate);
windowRotate_89_9#(.sin(0.93969),.cos(0.34202),.winW(winW),.dataW(dataW),.nonPipe(nonPipe))
wS7(clk,en,RoEn[7],window,window_rotate);
windowRotate_89_9#(.sin(0.98481),.cos(0.17365),.winW(winW),.dataW(dataW),.nonPipe(nonPipe))
wS8(clk,en,RoEn[8],window,window_rotate);




endmodule

*/