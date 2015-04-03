
`include "MFixPointFFT.v"

`define DW 8
module TB1();

	parameter dataW=8;
	parameter FFTW=10;
reg	signed [dataW-1:0] cosRes;

real D;
parameter FFTL=16;

reg [FFTL*dataW-1:0] Ref,Imf;
wire [FFTL*FFTW-1:0] ReF,ImF;
wire [FFTL*dataW-1:0] ReiF,ImiF;

reg signed[FFTW-1:0] ReiN,ImiN;
real ReiNr,ImiNr;
reg signed[dataW-1:0] ReN,ImN;
integer i;
integer RRRR;

parameter FFTDataFraction=2**(FFTW-dataW);
initial
begin
	#1;Imf=0;
	Ref={{9{`DW'b0}},{7{`DW'b100}}};
	
	//Ref={{4{-`DW'd4}},{4{`DW'd4}},{4{-`DW'd4}},{4{`DW'd4}}};
	/*Ref={
	-`DW'd2
	,-`DW'd1
	,-`DW'd5
	,-`DW'd4
	,-`DW'd2
	,-`DW'd1
	,-`DW'd5
	,-`DW'd4//8
	,`DW'd7
	,`DW'd6
	,`DW'd4
	,`DW'd3
	,`DW'd7
	,`DW'd6
	,`DW'd4
	,`DW'd3};//idx=0*/
	/*Ref={
	-`DW'd7
	,-`DW'd7
	,`DW'd7
	,`DW'd7
	,-`DW'd3
	,-`DW'd3
	,`DW'd5
	,`DW'd5
	,-`DW'd7
	,-`DW'd7
	,`DW'd7
	,`DW'd7
	,-`DW'd3
	,-`DW'd3
	,`DW'd5
	,`DW'd5};//idx=0*/
	for(i=0;i<FFTL;i=i+1)
	begin

		ReN=Ref[i*dataW+:dataW];
		ImN=Imf[i*dataW+:dataW];
		$display("%d>>%d+%di",i,ReN,ImN);
	end
	
	#200;
	$display("FFt-----------------");
	for(i=0;i<FFTL;i=i+1)begin
		ReiN=ReF[i*FFTW+:FFTW];
		ImiN=ImF[i*FFTW+:FFTW];
		ReiNr=1.0*ReiN/FFTDataFraction;
		ImiNr=1.0*ImiN/FFTDataFraction;
		$display("%d>>%.3f+%.3fi",i,ReiNr,ImiNr);
	end
	#20;
	$display("iFFt-----------------");
	for(i=0;i<FFTL;i=i+1)begin
		ReN=ReiF[i*dataW+:dataW];
		ImN=ImiF[i*dataW+:dataW];
		$display("%d>>%d+%di",i,ReN,ImN);
	end
end
parameter pipeInterval=4;
reg clk,en;
MFP_FFT #(.FFTL(FFTL),.FFTW(FFTW),.InW(dataW),.pipeInterval(pipeInterval),.Saturate(1),.isFloor(0))FFTS(clk,en,
Ref,Imf,
ReF,ImF);

MFP_iFFT #(.FFTL(FFTL),.FFTW(FFTW),.OutW(dataW),.pipeInterval(pipeInterval),.Saturate(1),.isFloor(0)) iFFTS(clk,en,
ReF,ImF,
ReiF,ImiF);
real ReW;
real ImW;

always #3 clk=~clk;
initial
begin
  $dumpfile("wave.vcd");
  $dumpvars;
  en=1;
  clk=0;
	/*ReW=fT.ReW_Gen(1,8);
	ImW=fT.ImW_Gen(1,8);*/
	#1024 $finish;
end
/*always@(*)begin
	moded=fT.ImW_Gen(1,8);
	cosRes=fT.real2Fix(moded);
end*/
endmodule 