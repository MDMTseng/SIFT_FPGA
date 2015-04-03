
`include "MFixPointTables.v"

module TB1();

	parameter dataW=18;
	parameter ARRL=200;
	reg clk,en;

wire [ARRL*dataW-1:0]Gaussian;
reg [ARRL*dataW-1:0]GaussianReg;
wire signed[dataW-1:0]GaussianVar=GaussianReg[0+:dataW];
wire [ARRL*dataW-1:0]Cos;
reg [ARRL*dataW-1:0]CosReg;
wire signed[dataW-1:0]CosVar=CosReg[0+:dataW];

generate 
	genvar i;
	for(i=0;i<ARRL;i=i+1)begin:tableGen
		MFP_gaussianTable#(.x((i-ARRL/2)*0.05),.sig(1),.outputW(dataW)) gT(Gaussian[i*dataW+:dataW]);
		MFP_Cos_ConstTable#(.x(i*0.1),.outputW(dataW)) W(Cos[i*dataW+:dataW]);
	end
endgenerate
always #3 clk=~clk;


wire [8:0]GaussSS;
MFP_gaussianSum #(.xstart(-13),.xend(13),
.sig(1),.outputW(9),.scale(255.0/204)) gS(GaussSS);

always@(posedge clk)
begin
	GaussianReg=GaussianReg[ARRL*dataW-1:dataW];
	CosReg=CosReg[ARRL*dataW-1:dataW];
end


initial
begin
  $dumpfile("wave.vcd");
  $dumpvars;
  #2
  GaussianReg=Gaussian;
  CosReg=Cos;
  en=1;
  clk=0;
	#1024 $finish;
end
endmodule 