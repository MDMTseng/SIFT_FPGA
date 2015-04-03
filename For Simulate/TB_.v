

`include "MFixPoint_ToolBox/MFixPointTables.v"

module TB1();
parameter TL=5;
parameter DW=9;
/*wire [DW*TL-1:0]GaussTable;
reg [DW*TL-1:0]GaussTable_;
/*
generate
	genvar i;
	for(i=0;i<TL;i=i+1)
	begin:lgen
		MFP_gaussianTable#(.x((i-TL/2)),.sig(10),.outputW(DW)) gt2(GaussTable[i*DW+:DW]);
		
	end
endgenerate*/

/*gaussianSum #(.xstart(-16),.xend(16),
.sig(3),.dataW(8)) gS(GaussSS);*/

/*MFP_gaussian2DSum #(.xstart(-windowRadi),.xend(windowRadi),.ystart(-windowRadi),.yend(windowRadi),
.sig(1.59),.outputW(8),.scale(255.0/235)) gS(GaussSS);*/

parameter windowSize=19;
parameter windowRadi=windowSize/2;
parameter SumW=9;
parameter TestSig=1;
parameter sigmaInit=1.6;//1.26
parameter sigmaInc=1.414;//1.26
wire [SumW*TL:0]GaussSS;
reg [SumW*TL:0]GaussSSReg;
wire [SumW-1:0]GaussSVar=GaussSSReg;
generate
	genvar i;
	/*for(i=0;i<TL;i=i+1)
	begin:lgen
		MFP_gaussianSum #(.xstart(-windowRadi),.xend(windowRadi),
		.sig(1.26**(i)),.outputW(SumW),.scale(255.0/255)) gS(GaussSS[i*SumW+:SumW]);
	end*/
	MFP_gaussianSum #(.xstart(-windowRadi),.xend(windowRadi),
		.sig(sigmaInit*sigmaInc**(0)),.outputW(SumW),.scale(255.0/255.8)) gS0(GaussSS[0*SumW+:SumW]);
	MFP_gaussianSum #(.xstart(-windowRadi),.xend(windowRadi),
		.sig(sigmaInit*sigmaInc**(1)),.outputW(SumW),.scale(255.0/256)) gS1(GaussSS[1*SumW+:SumW]);
	MFP_gaussianSum #(.xstart(-windowRadi),.xend(windowRadi),
		.sig(sigmaInit*sigmaInc**(2)),.outputW(SumW),.scale(255.0/254.5)) gS2(GaussSS[2*SumW+:SumW]);
	MFP_gaussianSum #(.xstart(-windowRadi),.xend(windowRadi),
		.sig(sigmaInit*sigmaInc**(3)),.outputW(SumW),.scale(255.0/248.9)) gS3(GaussSS[3*SumW+:SumW]);
	MFP_gaussianSum #(.xstart(-windowRadi),.xend(windowRadi),
		.sig(sigmaInit*sigmaInc**(4)),.outputW(SumW),.scale(255.0/220.3)) gS4(GaussSS[4*SumW+:SumW]);
	
endgenerate
always@(posedge clk)GaussSSReg<={{SumW{1'b0}},GaussSSReg[SumW*TL-1:SumW]};

integer S;
//wire [DW-1:0]GaussOut=GaussTable_;
		reg clk,en;
     always #3 clk=~clk;
		

initial
begin
   $dumpfile("wave.vcd");$dumpvars;
	//GaussTable_=GaussTable;
	#5
	GaussSSReg=GaussSS;
    en=1;
    clk=0;
    #1024 $finish;
end


endmodule
