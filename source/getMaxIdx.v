module getMaxIdx
       #(parameter
           data_depth=8,
           ArrL = 4,
           IdxOffSet=0
       )(
           input [data_depth*ArrL-1:0]DIn,
           output reg [data_depth-1:0]MaxData,
           output reg [IdxDept-1:0]MaxDataIdx
       );
	   localparam 
				IdxDept=10;
	wire  [data_depth-1:0]Max1;
   wire [IdxDept-1:0]MaxIdx1;
	wire  [data_depth-1:0]Max2;
   wire [IdxDept-1:0]MaxIdx2;
   wire [IdxDept-1:0]offSetw=IdxOffSet;
   wire [IdxDept-1:0]ArrLw=ArrL;
	generate 
		localparam Sp1=ArrL/2;
		localparam Sp2=ArrL-Sp1;
		if(Sp1==1)
		begin
			assign Max1=DIn[0+:data_depth];
			assign MaxIdx1=IdxOffSet;
			
		end
		else
		begin
			getMaxIdx #(.data_depth(data_depth),.ArrL(Sp1),.IdxOffSet(IdxOffSet))
			GMI1(DIn[0+:Sp1*data_depth],Max1,MaxIdx1);
		
		end
		if(Sp2==1)
		begin
			assign Max2=DIn[Sp1*data_depth+:data_depth];
			assign MaxIdx2=IdxOffSet+Sp1;
			
		end
		else
		begin
			getMaxIdx #(.data_depth(data_depth),.ArrL(Sp2),.IdxOffSet(IdxOffSet+Sp1))
			GMI2(DIn[Sp1*data_depth+:Sp2*data_depth],Max2,MaxIdx2);
		
		end
	endgenerate
	
	always@(*)
	begin
		if(Max2>Max1)
		begin
			MaxData=Max2;
			MaxDataIdx=MaxIdx2;
		end
		else
		begin
			MaxData=Max1;
			MaxDataIdx=MaxIdx1;
		end
	
	end


endmodule
