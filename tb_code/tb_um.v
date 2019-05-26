`timescale 1ns / 1ps

`define   WITE            2              //the intention between two pkts.
`define   INPORT          0             //from port
`define   SMID            0             

module um_tb();
	reg       clk;
	reg       rst_n;

	reg        pktin_data_valid;
	reg        pktin_data_valid_wr;
	reg[133:0] pktin_data;
	wire 	   pktin_ready;	
	reg        pktin_data_wr;

	wire [133:0] pktout_data;
	wire pktout_data_wr;
	wire pktout_data_valid;
	wire pktout_data_valid_wr;	
	reg  pktout_ready;



um um_s4_tb(

.clk(clk),
.um_timestamp(),
.rst_n(rst_n),
    
//cpu or port
.pktin_data_wr(pktin_data_wr),
.pktin_data(pktin_data),
.pktin_data_valid(pktin_data_valid),
.pktin_data_valid_wr(pktin_data_valid_wr),
.pktin_ready(pktin_ready),
    
.pktout_data_wr(pktout_data_wr),
.pktout_data(pktout_data),
.pktout_data_valid(pktout_data_valid),
.pktout_data_valid_wr(pktout_data_valid_wr),
.pktout_ready(pktout_ready), 

//control path
.dma2um_data(),
.dma2um_data_wr(),
.um2dma_ready(),
    
.um2dma_data(),
.um2dma_data_wr(),
.dma2um_ready(),
    
//to match
.um2me_key_wr(),
.um2me_key_valid(),
.um2match_key(),
.um2me_ready(),
//from match
.me2um_id_wr(),
.match2um_id(),
.um2match_gme_alful(),
//localbus
.ctrl_valid(),  
.ctrl2um_cs_n(),
.um2ctrl_ack_n(),
.ctrl_cmd(),
.ctrl_datain(),
.ctrl_addr(),
.ctrl_dataout(),
.um_timer()
);



parameter   local_mac_addr = 48'h0023cd76631a;
parameter   direct_mac_addr = 48'h000a35000001;
parameter   direction = 1'h1;

parameter CYCLE = 10;

always begin
	#(CYCLE/2) clk = ~ clk;
	pktout_ready = 1'b1;
end

initial begin
	clk = 0;
	rst_n = 1;
	#(5);
	rst_n = 0;
	#(5);
	rst_n = 1;
end

task um_tester;
	reg         [7:0] WITE;   
	reg			[5:0] INPORT; 
	reg 		[7:0] SMID;   
	reg			[47:0]SMAC; 
	reg			[47:0]DMAC;   
	reg         [2:0] PCP; 
	                    
	begin
		WITE    <= `WITE   ;
		INPORT  <= `INPORT ;
		SMID    <= `SMID   ;
		
        PCP     <= 3'h4;
                          
		SMAC    <= local_mac_addr   ;
		DMAC    <= direct_mac_addr  ;
		
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
		   
		 @(posedge clk);
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

       um_tester();
  end
end


endmodule