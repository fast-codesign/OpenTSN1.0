`timescale 1ns / 1ps

`define   WITE            2              //甯ч棿�??
`define   INPORT          0             //inport
`define   SMID            0              //smid(128:from cpu     鍏朵粬锛歠rom port)

module um_tb();
reg       clk;
reg       rst_n;

reg        pktin_data_valid;
reg        pktin_data_valid_wr;
reg[133:0] pktin_data;
reg        pktin_data_wr;
wire       [47:0]direct_mac_addr;
wire       direction;
wire       [47:0]local_mac_addr;

assign      local_mac_addr = 48'h0023cd76631a;
assign      direct_mac_addr = 48'h000a35000001;
assign      direction = 1'h1;

initial begin//100Mhz
    clk = 1'b0;
    forever #5 clk = ~clk;
end

initial begin//reset
    rst_n = 1'b0;
    #5000;
    rst_n = 1'b1;
end

task generator_yuyue_esw;
	reg         [7:0] WITE;   
	reg			[5:0] INPORT; 
	reg 		[7:0] SMID;   
	reg			[47:0]SMAC; 
	reg			[47:0]DMAC;   
	reg        [2:0]PCP; 
	                    
	begin
		WITE    <= `WITE   ;
		INPORT  <= `INPORT ;
		SMID    <= `SMID   ;
		
        PCP     <= 3'h4;
                          
		SMAC    <= local_mac_addr   ;
		DMAC    <= local_mac_addr   ;
		
		 @(posedge clk); //metadta0
			pktin_data <={2'b01,4'b0000,2'b00,INPORT,12'h0,12'h6e,SMID,8'h1,80'h0};
			pktin_data_wr <= 1'b1; 
			pktin_data_valid  <= 1'h0;
			pktin_data_valid_wr <= 1'b0;
			
		 @(posedge clk); //metadta1
	        pktin_data <=  {2'b11,4'b0000,128'h0};
		    pktin_data_wr <= 1'b1; 
            pktin_data_valid  <= 1'h0;
		    pktin_data_valid_wr <= 1'b0;	
		   
		 @(posedge clk); // data
			pktin_data <= {2'b11,4'b0000,DMAC,SMAC,16'h8100,PCP,13'h1280};   
			pktin_data_wr <= 1'b1;		   
			pktin_data_valid  <= 1'h0;
			pktin_data_valid_wr <= 1'b0;	
		   
		 @(posedge clk); // data
			pktin_data <= {2'b11,4'b0000,128'h08004500003c7919000040017df2c0a8};   
			pktin_data_wr <= 1'b1;		   
			pktin_data_valid  <= 1'h0;
			pktin_data_valid_wr <= 1'b0;	
		   
		 @(posedge clk); // data
			pktin_data <= {2'b11,4'b0000,128'h0164c0a801010800445c040005006162};   
			pktin_data_wr <= 1'b1;		   
			pktin_data_valid  <= 1'h0;
			pktin_data_valid_wr <= 1'b0;		
		   
		 @(posedge clk); // data
	       pktin_data <= {2'b11,4'b0000,128'h636465666768696a6b6c6d6e6f707172};   
		   pktin_data_wr <= 1'b1;		   
           pktin_data_valid  <= 1'h0;
		   pktin_data_valid_wr <= 1'b0;	

		 @(posedge clk); // data
	       pktin_data <= {2'b10,4'b0010,128'h73747579776162636465666768690000};   
		   pktin_data_wr <= 1'b1;		   
           pktin_data_valid  <= 1'h1;
		   pktin_data_valid_wr <= 1'b1;	
		   
		 @(posedge clk);//甯ч棿�??
           repeat(WITE)begin
                   pktin_data <= 134'h0;
                   pktin_data_wr <= 1'b0;                    
                   pktin_data_valid  <= 1'h0;
                   pktin_data_valid_wr <= 1'b0;        
           @(posedge clk);     
		   end
	end
endtask

initial begin
  wait (rst_n == 1'b1);
  repeat(100) @(posedge clk);
  repeat(50)begin
       generator_yuyue_esw();
  end
end

test_um test_um(
.clk(clk),
.direct_mac_addr(direct_mac_addr),
.direction(direction),
.local_mac_addr(local_mac_addr),
.esw_pktin_cnt(),
.esw_pktout_cnt(),
.bufm_ID_cnt(),
.pktin_data(pktin_data),
.pktin_valid(pktin_data_valid),
.pktin_valid_wr(pktin_data_valid_wr),
.pktin_data_wr(pktin_data_wr),
.rst_n(rst_n)
);

endmodule