`timescale 1 ns/ 1ps
module lupdate_tb
	(
	);
//define reg and wire


	reg clk;
	reg rst_n;

//lreport signal 
	reg [133:0] in_lu_data;
	reg in_lu_data_wr;
	reg in_lu_data_valid;
	reg in_lu_data_valid_wr;
	
	reg [47:0] in_local_mac_id;

//esw signal 
	wire [133:0] out_lu_data;
	wire out_lu_data_wr;
	wire out_lu_data_valid;
	wire out_lu_data_valid_wr;
	wire out_local_mac_id;

//changeable registers and counters
	wire direction;
	wire [31:0] token_bucket_para;
	wire [47:0] direct_mac_add;

//initialize module
lupdate lupdate_tb(

	.clk(clk),
	.rst_n(rst_n),

	.in_lu_data(in_lu_data),
	.in_lu_data_wr(in_lu_data_wr),
	.in_lu_data_valid(in_lu_data_valid),
	.in_lu_data_valid_wr(in_lu_data_valid_wr),
	.in_local_mac_id(in_local_mac_id),

	.out_lu_data(out_lu_data),
	.out_lu_data_wr(out_lu_data_wr),
	.out_lu_data_valid(out_lu_data_valid),
	.out_lu_data_valid_wr(out_lu_data_valid_wr),
	.out_local_mac_id(out_local_mac_id),

	.direction(direction),
	.token_bucket_para(token_bucket_para),
	.direct_mac_addr(direct_mac_addr)
);


//Part 3: Clk

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

	//tb for packet trans
	/**the 1st control packet*/
	in_local_mac_id = 48'b1;

	#CYCLE 
	in_lu_data_wr = 1'b1;
	in_lu_data = {2'b01,132'hff};
	in_lu_data_valid = 1'b0;
	in_lu_data_valid_wr = 1'b0;
	#CYCLE 
	in_lu_data_wr = 1'b1;
	in_lu_data = {2'b11,132'hff};
	in_lu_data_valid = 1'b0;
	in_lu_data_valid_wr = 1'b0;
	#CYCLE 
	in_lu_data_wr = 1'b1;
	in_lu_data = {2'b11, 4'b0, 48'h1, 68'b0, 4'hf, 8'b0};
	in_lu_data_valid = 1'b0;
	in_lu_data_valid_wr = 1'b0;
	#CYCLE 
	in_lu_data_wr = 1'b1;
	in_lu_data = {2'b11,132'h2};
	in_lu_data_valid = 1'b0;
	in_lu_data_valid_wr = 1'b0;
	#CYCLE 
	in_lu_data_wr = 1'b1;
	in_lu_data = {2'b11,132'h3};
	in_lu_data_valid = 1'b0;
	in_lu_data_valid_wr = 1'b0;
	#CYCLE 
	in_lu_data_wr = 1'b1;
	in_lu_data = {2'b10,132'h4};
	in_lu_data_valid = 1'b1;
	in_lu_data_valid_wr = 1'b1;

	#CYCLE 
	in_lu_data_wr = 1'b0;
	in_lu_data = 134'b0;
	in_lu_data_valid = 1'b0;
	in_lu_data_valid_wr = 1'b0;



	#(15*CYCLE);
	$finish; 
	
end

always begin
	#(CYCLE/2) clk = ~ clk;
end

endmodule