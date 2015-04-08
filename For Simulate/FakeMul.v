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

localparam FixTableL=128;
localparam FixTableBitW=$clog2(FixTableL);
localparam FixTableMax=FixTableL-1;

wire [FixTableBitW*FixTableL-1:0]sqTableS={7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd127,7'd126,7'd126,7'd126,7'd126,7'd126,7'd126,7'd126,7'd125,7'd125,7'd125,7'd125,7'd124,7'd124,7'd124,7'd123,7'd123,7'd122,7'd121,7'd121,7'd120,7'd119,7'd118,7'd117,7'd116,7'd115,7'd113,7'd112,7'd111,7'd109,7'd107,7'd106,7'd104,7'd102,7'd100,7'd97,7'd95,7'd93,7'd90,7'd88,7'd85,7'd83,7'd80,7'd77,7'd75,7'd72,7'd69,7'd66,7'd63,7'd60,7'd57,7'd54,7'd52,7'd49,7'd46,7'd43,7'd41,7'd38,7'd36,7'd33,7'd31,7'd29,7'd27,7'd24,7'd23,7'd21,7'd19,7'd17,7'd16,7'd14,7'd13,7'd12,7'd10,7'd9,7'd8,7'd7,7'd6,7'd6,7'd5,7'd4,7'd4,7'd3,7'd3,7'd2,7'd2,7'd2,7'd1,7'd1,7'd1,7'd0,7'd0,7'd0,7'd0};
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


wire [outW-1-1:0]outDataAbs=sqTable[minAbs];
assign outData=(outSign)?-outDataAbs:outDataAbs;

endmodule
