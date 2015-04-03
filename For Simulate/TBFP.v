`include "MFixPoint_ToolBox/MFixPointBasic.v"
`include "MFixPoint_ToolBox/MFixPointMAC.v"
`include "MFixPoint_ToolBox/MFixPointTables.v"
//`include "FFT_tools.v"
module TB ();
reg clr;
reg clk;
parameter inputW=18;
parameter outputW=18;
localparam maxPosNum=2**(inputW-1)-1;//3bit max pos number is 3(011)=>2^(3-1)-1=4-1
parameter resetMax=30;
reg signed[inputW-1:0]dA,dB;



reg [inputW*40-1:0]dAArr2;
wire [inputW*40-1:0]dBArr;
wire signed[outputW-1:0]acc_sum_rounded_par2;
MFP_MAC_par #(.InAW(inputW),.ArrL(40),.AccW_ROUND(outputW))MACp2(dAArr2,dBArr,ghfghghfg, acc_sum_rounded_par2);



reg [resetMax:0]sR_rst;

real outrData,inrA,inrB,prorData,outrData_par,outrData_par2;

always #5 clk=~clk;
integer di=0;

real signFlop;


generate 
	genvar i;
	for(i=0;i<40;i=i+1)begin:tableGen
	
		MFP_gaussianTable#(.x((i-40/2)),.sig(2),.outputW(inputW)) gT(dBArr[i*inputW+:inputW]);
	end
endgenerate

initial
begin
	
	sR_rst=1;
   clk=0;
	signFlop=1;
	inrA=0.999999;
	inrB=0.04;
	

    #3200 $finish;
end

always@(posedge clk)begin
	dAArr2={dAArr2,dA};
	
	//dAArr={dAArr,{Fix2Logi(127/256.0),Fix2Logi(255/256.0),Fix2Logi(21/256.0)}};
end
always@(posedge clk)begin
	if(sR_rst[resetMax])begin
		signFlop=(signFlop==1)?-1:1;
		inrA=signFlop*0.999999;
		inrB=0.04;
	end 
	else begin
		 inrA=inrA*0.9;
		 inrB=inrB/0.9;
		 if(inrA>=1)inrA=0.9999999;
		 if(inrB>=1)inrB=0.9999999;
	end
	sR_rst={sR_rst,sR_rst[resetMax]};
	
	
end
always@(*)
begin
	dA=Fix2Logi(inrA);
	dB=Fix2Logi(inrB);
	outrData_par2=acc_sum_rounded_par2*1.0/(2**(outputW-1));
end


function signed [inputW-1:0] Fix2Logi;
   input real f52;
   begin
	   Fix2Logi=f52*(2**(inputW-1));
		if((f52<0)^Fix2Logi[inputW-1])//signed change
			Fix2Logi=(f52<0)?-maxPosNum:maxPosNum;
   end
endfunction

initial
begin
    $dumpfile("wave.vcd");
    $dumpvars;
end

endmodule

