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

	reg [47:0] precision_time;


//initialize module
um um_s4_tb(

.clk(clk),
.rst_n(rst_n),

.pktout_usedw_0(),
.pktout_usedw_1(),

.pktin_data(pktin_data),
.pktin_data_wr(pktin_data_wr),
.pktin_valid(pktin_data_valid),
.pktin_valid_wr(pktin_data_valid_wr),
.pktin_ready(pktin_ready),

.precision_time(precision_time),
.local_mac_id(),

.pktout_data_0(pktout_data),
.pktout_data_wr_0(pktout_data_wr),
.pktout_valid_0(pktout_data_valid),
.pktout_valid_wr_0(pktout_data_valid_wr),

.pktout_data_1(),
.pktout_data_wr_1(),
.pktout_valid_1(),
.pktout_valid_wr_1(),

.port2_pktout_data(),
.port2_pktout_data_wr(),
.port2_pktout_valid(),
.port2_pktout_valid_wr(),

.port3_pktout_data(),
.port3_pktout_data_wr(),
.port3_pktout_valid(),
.port3_pktout_valid_wr()
);


//Part 3: Clk

parameter INTENT = 20;
parameter CYCLE = 10;

//Part 1: wire connection
//Part 2: Reset
initial begin
	clk = 0;
	precision_time = 48'b0;
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

	#(CYCLE) precision_time = precision_time + 48'b1;
end

endmodule