`timescale 1 ns/ 1ps
module um_tb
	(
	);
//define reg and wire
	reg clk;
	reg rst_n;

	reg [133:0] pktin_data;
	reg pktin_data_wr;
	reg pktin_data_valid;
	reg pktin_data_valid_wr;
	wire pktin_ready;

	wire [133:0] pktout_data;
	wire pktout_data_wr;
	wire pktout_data_valid;
	wire pktout_data_valid_wr;
	wire pktout_ready;


//initialize module
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


//Part 3: Clk

parameter INTENT = 20;
parameter CYCLE = 10;

//Part 1: wire connection
//Part 2: Reset
initial begin
	clk = 0;
	rst_n = 1;
	#(5);
	rst_n = 0;
	#(5);
	rst_n = 1;
end

//start user code
initial begin

	//tb for control path
	pktin_data_wr = 1'b0;
	pktin_data = 134'b0;
    pktin_data_valid = 1'b0;
    pktin_data_valid_wr = 1'b0;
	/**the 1st control packet*/
	#(10*CYCLE) 
	pktin_data_wr = 1'b1;
    pktin_data = {2'b01,24'hff, 12'd96, 96'hff};
    pktin_data_valid = 1'b0;
    pktin_data_valid_wr = 1'b0;


	#CYCLE 
	pktin_data_wr = 1'b1;
	pktin_data = {2'b11,132'hff};
	pktin_data_valid = 1'b0;
	pktin_data_valid_wr = 1'b0;

	#CYCLE 
	pktin_data_wr = 1'b1;
	pktin_data = {2'b11, 4'b0, 48'h1, 48'h2, 20'b0, 4'hf, 8'b0};
	pktin_data_valid = 1'b0;
	pktin_data_valid_wr = 1'b0;

	#CYCLE 
	pktin_data_wr = 1'b1;
	pktin_data = {2'b11,132'h2};
	pktin_data_valid = 1'b0;
	pktin_data_valid_wr = 1'b0;

	#CYCLE 
	pktin_data_wr = 1'b1;
	pktin_data = {2'b11,132'h3};
	pktin_data_valid = 1'b0;
	pktin_data_valid_wr = 1'b0;

	#CYCLE 
	pktin_data_wr = 1'b1;
	pktin_data = {2'b10,132'h4};
	pktin_data_valid = 1'b1;
	pktin_data_valid_wr = 1'b1;

	#CYCLE 
	pktin_data_wr = 1'b0;
	pktin_data = 134'b0;
	pktin_data_valid = 1'b0;
	pktin_data_valid_wr = 1'b0;

    #CYCLE 
	pktin_data_wr = 1'b0;
	pktin_data = 134'b0;
	pktin_data_valid = 1'b0;
	pktin_data_valid_wr = 1'b0;

	#CYCLE
	pktin_data_wr = 1'b1;
    pktin_data = {2'b01,24'hff, 12'd96, 96'hff};
    pktin_data_valid = 1'b0;
    pktin_data_valid_wr = 1'b0;


	#CYCLE 
	pktin_data_wr = 1'b1;
	pktin_data = {2'b11,132'hff};
	pktin_data_valid = 1'b0;
	pktin_data_valid_wr = 1'b0;

	#CYCLE 
	pktin_data_wr = 1'b1;
	pktin_data = {2'b11, 4'b0, 48'h01020304, 48'h2, 20'b0, 4'h0, 8'b0};
	pktin_data_valid = 1'b0;
	pktin_data_valid_wr = 1'b0;

	#CYCLE 
	pktin_data_wr = 1'b1;
	pktin_data = {2'b11,132'h2};
	pktin_data_valid = 1'b0;
	pktin_data_valid_wr = 1'b0;

	#CYCLE 
	pktin_data_wr = 1'b1;
	pktin_data = {2'b11,132'h3};
	pktin_data_valid = 1'b0;
	pktin_data_valid_wr = 1'b0;

	#CYCLE 
	pktin_data_wr = 1'b1;
	pktin_data = {2'b10,132'h4};
	pktin_data_valid = 1'b1;
	pktin_data_valid_wr = 1'b1;

	#CYCLE 
	pktin_data_wr = 1'b0;
	pktin_data = 134'b0;
	pktin_data_valid = 1'b0;
	pktin_data_valid_wr = 1'b0;

	#(100*CYCLE);
	$finish; 
	
end

always begin
	#(CYCLE/2) clk = ~ clk;
end

endmodule