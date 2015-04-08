
`include"../FakeMul.v"
module test;
	reg signed[8-1:0]counter;
	 XMul#(.dataW(8)) xm(counter,8'd127,XZZ);
	 
	 reg clk;
	 always #5 clk=~clk;
	 always@(posedge clk)counter=counter+1;
   initial begin
        $dumpfile("wave.vcd");$dumpvars;
       clk=0;
		counter=0;
       #3500 $finish;
    end
endmodule

