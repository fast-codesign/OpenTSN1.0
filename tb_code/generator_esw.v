`timescale 1ns / 1ps

`define   WITE            5              //帧间�?
`define   INPORT          0              //inport
`define   SMID            128              //smid(128:from cpu     其他：from port)

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

task generator_esw;
	reg         [7:0] WITE;   
	reg			[5:0] INPORT; 
	reg 		[7:0] SMID;   
	reg			[47:0]SMAC; 
	reg			[47:0]DMAC;   
	                    
	begin
		WITE    <= `WITE   ;
		INPORT  <= `INPORT ;
		SMID    <= `SMID   ;
                          
		SMAC    <= local_mac_addr   ;
		DMAC    <= local_mac_addr   ;
		
		 @(posedge clk); //metadta0
			pktin_data <={2'b01,4'b0000,2'b00,INPORT,12'h0,12'h82,SMID,8'h1,80'h0};
			pktin_data_wr <= 1'b1; 
			pktin_data_valid  <= 1'h0;
			pktin_data_valid_wr <= 1'b0;
			
		 @(posedge clk); //metadta1
	        pktin_data <=  {2'b11,4'b0000,128'h0};
		    pktin_data_wr <= 1'b1; 
            pktin_data_valid  <= 1'h0;
		    pktin_data_valid_wr <= 1'b0;	
		   
		 @(posedge clk); // data
			pktin_data <= {2'b11,4'b0000,DMAC,SMAC,32'h08004500};   
			pktin_data_wr <= 1'b1;		   
			pktin_data_valid  <= 1'h0;
			pktin_data_valid_wr <= 1'b0;	
		   
		 @(posedge clk); // data
			pktin_data <= {2'b11,4'b0000,128'h00544938400040014177cac50537cac5};   
			pktin_data_wr <= 1'b1;		   
			pktin_data_valid  <= 1'h0;
			pktin_data_valid_wr <= 1'b0;	
		   
		 @(posedge clk); // data
			pktin_data <= {2'b11,4'b0000,128'h0538080024e56403005337b9370b0000};   
			pktin_data_wr <= 1'b1;		   
			pktin_data_valid  <= 1'h0;
			pktin_data_valid_wr <= 1'b0;		
		   
		 @(posedge clk); // data
	       pktin_data <= {2'b11,4'b0000,128'h0};   
		   pktin_data_wr <= 1'b1;		   
           pktin_data_valid  <= 1'h0;
		   pktin_data_valid_wr <= 1'b0;	

		 @(posedge clk); // data
	       pktin_data <= {2'b11,4'b0000,128'h0};   
		   pktin_data_wr <= 1'b1;		   
           pktin_data_valid  <= 1'h0;
		   pktin_data_valid_wr <= 1'b0;	

		 @(posedge clk); // data
	       pktin_data <= {2'b11,4'b0000,128'h0};   
		   pktin_data_wr <= 1'b1;		   
           pktin_data_valid  <= 1'h0;
		   pktin_data_valid_wr <= 1'b0;	

		 @(posedge clk); // last_data
	       pktin_data <= {2'b10,4'b1110,128'h0};   
		   pktin_data_wr <= 1'b1;		   
           pktin_data_valid  <= 1'h1;
		   pktin_data_valid_wr <= 1'b1;  
		   
		 @(posedge clk);//帧间�?
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
  repeat(10)begin
       generator_esw();
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