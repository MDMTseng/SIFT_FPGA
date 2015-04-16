`timescale 1ns / 1ps

`define MVAL_W(MAXVALUE) ($clog2(MAXVALUE)+(((2**$clog2(MAXVALUE))==MAXVALUE)?0:1))
module hijacker
#(parameter
CameraDataDepth=16,//Data from camera
//Set the width parameter for window extraction module
ImageW=640,
ImageH=480,

dispLevel=32, //32
DataDepth=16,
SGMDataDepth=6
)
(
	 input fclk,
	 input clk1,
	 input clk2,
	 
	 input CamADV,
	 input FbWrARst,
	 input CamBDV,
	 input FbWrBRst,
	 
	  
    input [CameraDataDepth-1:0] DI1,
    input [CameraDataDepth-1:0] DI2,
    input [CameraDataDepth-1:0] DIx,
    output [CameraDataDepth-1:0] DO1,
    output [CameraDataDepth-1:0] DO2,
	 output [7:0]LED_O,
	 input [7:0]SW_I,
	 output [7:0]IO_O,
	 
	 
	 input sck,input css,input mosi,inout miso,
	 output spi_DatRdy,output spi_ScreenRst
    );
	 wire miso_;
	 
	 reg misoGate;
	wire mosi;
	 assign miso = (misoGate) ? miso_ : 1'bz;
	 
	 wire clk_p=clk2;
	 always@(posedge clk_p)misoGate<=css;
	 
	 
	reg [8-1:0]SaData[7:0];
	 
	
	wire [8-1:0]dat_i;
	wire [8-1:0]ndat_i;
	wire spi_rdy;
	wire spi_prerdy;
	
	wire sck_posedge;
	reg [8-1:0]feedData;
	

	
	
	SPI_slave SPI_S1(clk_p,sck,css, mosi,miso_,
	feedData,dat_i,ndat_i,sck_posedge,accep_dat_o,spi_rdy,spi_prerdy
	);
	
	reg[8*6-1:0]dataG;
	wire SPIByteRdy=sck_posedge&spi_prerdy;
	
	reg enD;
	always@(posedge clk_p)begin//sec for data shift counter 1, 2, 4 
		enD<=SPIByteRdy&Pix_C[5];
	end
	
	
	wire en_p=(SaData[2]==0)?CamBDV:enD;//enD;
	assign spi_DatRdy=en_p;
	wire rst_p=(SaData[2]==0)?FbWrBRst:spi_ScreenRst;
	
	
	always@(posedge clk_p)begin//sec for data shift counter 1, 2, 4 
		if(SPIByteRdy)dataG<={dataG,ndat_i};
	end
	
	reg [2:0]SPI_C;
	always@(posedge clk_p,negedge css)begin//sec for data shift counter 1, 2, 4 
		if(~css)SPI_C<=1;
		else if(SPIByteRdy)SPI_C<={SPI_C,SPI_C[2]};
	end
	
   reg [5:0]Pix_C;
	always@(posedge clk_p,negedge KGate)begin//sec for data shift counter 1, 2, 4 
		if(~KGate)Pix_C<=1;
		else if(SPIByteRdy)Pix_C<={Pix_C,Pix_C[5]};
	end
	
	reg [8*6-1:0]dat_PixK;
	always@(posedge clk_p)begin//sec for data shift counter 1, 2, 4 
		if(SPIByteRdy&Pix_C[5])dat_PixK<={dataG,ndat_i};
	end
	
	/*
	wire clk_p=clk1;
	wire en_p=CamADV;
	wire rst_p=FbWrARst;*/
	
	always@(posedge clk_p,negedge css)begin
		if(~css) KGate=0;
		else if(SPIByteRdy)begin//new spi data byte comes in
			if(KGate)begin
				feedData=spiRet;
			end
			else begin
				feedData=8'hff;
				
				if(SPI_C[1])begin//receive 2 datas 1st data=dat_Pix[0+:8],2nd data=preData , usually for return data 
					if(dataG[0+:8]==16'h81)
						feedData=SaData[ndat_i];
				end
				else if(SPI_C[2])begin//receive 3 datas 1st data=dat_Pix[8+:8],2nd data=dat_Pix[0+:8] 3rd data at , usually for accept data 
					case(dataG[8+:8])
					8'h80:
						SaData[dataG[0+:8]]=ndat_i;
					8'h55:
						KGate=1;
					8'h40:
						spi_ScreenRst=0;
					8'h41:
						spi_ScreenRst=1;
					default:
						KGate=0;
					endcase
				
				end
			end
		end
	end
	
	
	assign LED_O={Pix_C,KGate,spi_ScreenRst};
	
	
	reg KGate,spi_ScreenRst;
	
	
	
	wire [10:0]pixX;
	wire [10:0]pixY;
	reg [8:0]spiRet;//=MinDataIdx;
	


	wire [DataDepth-1:0]ColorMean1=(DI1[11+:5]+DI1[0+:5]+DI1[5+:6])*2;//(DI1[11+:5]+DI1[0+:5]*2+DI1[5+:6]*2);
	wire [DataDepth-1:0]ColorMean2=(DI2[11+:5]+DI2[0+:5]+DI2[5+:6])*2;//(DI2[11+:5]+DI2[0+:5]*2+DI2[5+:6]*2);
	
	wire [DataDepth-1:0]DI2r=(SaData[2]==0)?ColorMean2:{dat_PixK[24+23-:5],dat_PixK[24+15-:6],dat_PixK[24+7-:8]};//giv full bit of blue
	
	wire [DataDepth-1:0]DI1r=(SaData[2]==0)?ColorMean1:{dat_PixK[23-:5],dat_PixK[15-:6],dat_PixK[7-:8]};//may kick off red
	parameter GausTableN=5;
	localparam dataW=8;//unsigned data
	localparam sidataW=dataW;
	wire [dataW-1:0]GOut[0:7];
	
	always@(*)
	begin
		case(SaData[0])
		 0:spiRet<=GOut[0];
		 1:spiRet<=GOut[1];
		 2:spiRet<=GOut[2];
		 3:spiRet<=GOut[3];
		
		 4:spiRet<=GOut[4];
		 5:spiRet<=GOut[5];
		 6:spiRet<=GOut[6];
		 7:spiRet<=GOut[7];
		 
		// 3:spiRet<=DIxL;
		 //4:spiRet<=(DIxL==0)?0:255;
		 8:spiRet<=(pixX>pixY)?pixX:pixY;
		// 9:spiRet<=dat_PixK[40+:8];
		 default:spiRet<=0;
		 endcase
	
	end
	
	wire[8-1:0]OR,OG,OB;
	ColorTranse(spiRet,OR,OG,OB);
	assign DO2=(SW_I[7])?{OR[7-:5],OG[7-:6],OB[7-:5]}:DI2;//(pixX[0])?DIxL:DIxR;
	assign DO1=(SW_I[7])?((pixY[3])?DI1:DI2):DI1;
	//assign DO1={ColorMean2[6-:5],ColorMean1[6-:6],ColorMean2[6-:5]};//(pixX[0])?DIxL:DIxR;
	
	//assign IO_O[7:4]={KGate,spi_DatRdy,css&sck,spi_prerdy};
	PixCoordinator # (.frameW(ImageW),.frameH(ImageH)) 
	Pc1(clk_p,en_p,rst_p,pixX,pixY);
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	parameter GaussianOut=dataW;
	wire [GausTableN*GaussianOut-1:0]Gaussian1;//unsigned
	wire [GaussianOut+1-1:0]harrisRes1;
	octaveModule#(.frameW(ImageW),.outW(GaussianOut)) 
	OM1(clk_p,en_p,DI1r[0+:8],pixX,pixY,Gaussian1,harrisRes1);
	
	assign GOut[0]=GOut[1]/2+harrisRes1/2;
	assign GOut[1]=Gaussian1[0*GaussianOut+:dataW];
	assign GOut[2]=DHL[0].DoGOffset/2+harrisRes1/2;
	assign GOut[3]=DHL[0].DoGOffset;
	
	
	
	
	assign GOut[4]=DHL[0].DoGXHarrisOffset;
	

	generate
		genvar gi;
		 for(gi=0;gi<GausTableN-1;gi=gi+1)
		 begin:DHL
			wire signed[GaussianOut+1-1:0] GaussianA=Gaussian1[gi*dataW+:dataW];
			wire signed[GaussianOut+1-1:0] GaussianB=Gaussian1[(gi+1)*dataW+:dataW];
			wire signed[GaussianOut+1-1:0] DoG=GaussianA-GaussianB;
			wire signed[GaussianOut-1:0] DoGOffset=128+DoG;
			
			
			wire signed[GaussianOut-1:0] DoGXHarris;
			
			MFP_Multi #(.In1W(GaussianOut),.In2W(GaussianOut+1),.OutW(GaussianOut+2),.isUnsigned(0)) 
			m_ac(DoG,harrisRes1,DoGXHarris);
			wire signed[GaussianOut-1:0] DoGXHarrisOffset=128+DoGXHarris/2;
			
		 end
	endgenerate	
	
	
	
	
	
	
	parameter extWinsize=3;
	
	parameter HalfSize=(extWinsize*extWinsize-1)/2;
	wire [extWinsize*extWinsize*GaussianOut-1:0]W1;


	ScanLWindow_blkRAM_adv #(.block_height(extWinsize),.block_width(extWinsize)
	,.frame_width(ImageW),.pixel_depth(GaussianOut))
	win1(clk_p,en_p,DHL[0].DoGXHarris,W1);

	wire [2*HalfSize*GaussianOut-1:0]Win_skipCenter=
	{W1[(HalfSize+1)*GaussianOut+:HalfSize*GaussianOut],W1[0+:HalfSize*GaussianOut]};

	parameter localExThres=0;
	genvar pix; 
	generate 
		wire signed[GaussianOut-1:0]centerpix=W1[HalfSize*GaussianOut+:GaussianOut];
		wire signed[GaussianOut-1:0]centerpixT=centerpix-localExThres;
		wire signed[GaussianOut-1:0]centerpixB=centerpix+localExThres;
		
		wire [2*HalfSize-1:0]compArrMax;
		wire [2*HalfSize-1:0]compArrMin;
		for (pix=0;pix<2*HalfSize;pix=pix+1) begin:maxpixel
			
		  wire signed[GaussianOut-1:0]a= Win_skipCenter[pix*GaussianOut+:GaussianOut];
		  assign compArrMin[pix]=(centerpixB < a);
		  assign compArrMax[pix]=(centerpixT > a);
			
		end

	endgenerate
	wire localEx=(compArrMin=={2*HalfSize{1'b1}})||(compArrMax=={2*HalfSize{1'b1}}); 
		 
		 
		 
	reg [dataW-1:0]EXSym;
	assign GOut[5]=EXSym;
	always@(posedge clk_p)if(en_p)begin
		#1
		if((compArrMin=={2*HalfSize{1'b1}}))
			EXSym=0;
		else if((compArrMax=={2*HalfSize{1'b1}}))
			EXSym=255;
		else
			EXSym=128;
	end


	
endmodule

	