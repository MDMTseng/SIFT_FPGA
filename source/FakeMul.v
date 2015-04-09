module ABSData
#(parameter
dataW=8,
outW=dataW-1
)
(
input signed[dataW-1:0]in,
output signed[outW-1:0]outData
);
	assign outData=(in[dataW-1])?-in:in;
endmodule


module XMul
#(parameter
dataW=8,
outW=dataW,
power=1
)
(
input signed[dataW-1:0]in1,
input signed[dataW-1:0]in2,
output signed[outW-1:0]outData
);
parameter tableDataW=outW-1;//its unsigned
localparam tableDataMax=(2**tableDataW)-1;
parameter tableLW=dataW-1;
localparam tableL=(2**tableLW);

localparam FixTableL=64;
parameter FixTableBitW=$clog2(FixTableL);
localparam FixTableMax=FixTableL-1;

wire [FixTableBitW*FixTableL-1:0]sqTableS={6'd63,6'd63,6'd63,6'd63,6'd63,6'd63,6'd63,6'd63,6'd63,6'd62,6'd62,6'd62,6'd62,6'd62,6'd62,6'd61,6'd61,6'd61,6'd61,6'd60,6'd60,6'd59,6'd59,6'd58,6'd58,6'd57,6'd57,6'd56,6'd55,6'd54,6'd53,6'd52,6'd51,6'd50
,6'd49,6'd48,6'd47,6'd45,6'd44,6'd42,6'd41,6'd39,6'd37,6'd36,6'd34,6'd32,6'd30,6'd29,6'd27,6'd25,6'd23,6'd21,6'd19,6'd17,6'd15,6'd14,6'd12,6'd10,6'd8,6'd6,6'd5,6'd3,6'd2,6'd0};
wire [tableDataW-1:0]sqTable[0:tableL-1];
genvar gi;
generate 
	for(gi=0;gi<tableL;gi=gi+1)begin:tableLoop
			assign sqTable[gi]=sqTableS[FixTableBitW*(gi*(FixTableMax-1)/(tableL-1))+:FixTableBitW]*tableDataMax/FixTableMax;
			//(gi**power)*tableDataMax/((tableL-1)**power);
	end
endgenerate

wire outSign=in1[dataW-1]^in2[dataW-1];
wire [dataW-2:0]absIn1=(in1[dataW-1])?-in1:in1;
wire [dataW-2:0]absIn2=(in2[dataW-1])?-in2:in2;
wire [dataW-2:0]minAbs=(absIn1<absIn2)?absIn1:absIn2;


wire [outW-1-1:0]outDataAbs=minAbs;
assign outData=(outSign)?-outDataAbs:outDataAbs;

endmodule
