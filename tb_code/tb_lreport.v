//*************************************************************
//      date:  2019/05/19
//      modifier: 
//      description: 
///////////////////////////////////////////////////////////////// 

`timescale 1 ns/ 1ps
module lreport_tb
	(
	);
//define reg and wire
	reg clk;
	reg rst_n;

//um signals

	reg [133:0] in_lr_data;
	reg in_lr_data_wr;
	reg in_lr_data_valid;
	reg in_lr_data_valid_wr;

	wire pktin_ready;
	reg [47:0] precision_time;
	reg [47:0] in_local_mac_id;

//lupdate signal 
	wire out_lr_data_wr;
	wire [133:0] out_lr_data;
	wire out_lr_data_valid;
	wire out_lr_data_valid_wr;

	wire [47:0] out_local_mac_id;

//readable & changeable registers and counters
	reg direction;
	reg [31:0] token_bucket_para;
	reg [47:0] direct_mac_addr;

	//input from esw
	reg [63:0] esw_pktin_cnt;
	reg [63:0] esw_pktout_cnt;
	reg [7:0] bufm_id_cnt;

	//input from eos
	reg [5:0] eos_q0_used_cnt;
	reg [5:0] eos_q1_used_cnt;
	reg [5:0] eos_q2_used_cnt;
	reg [5:0] eos_q3_used_cnt;

	reg [63:0] eos_mdin_cnt;
	reg [63:0] eos_mdout_cnt;

	//input from goe
	reg [63:0] goe_pktin_cnt;
	reg [63:0] goe_port0out_cnt;
	reg [63:0] goe_port1out_cnt;
	reg [63:0] goe_discard_cnt;




//initialize module
lreport lreport_ctl_tb(

	.clk(clk),
	.rst_n(rst_n),
	.in_lr_data_wr(in_lr_data_wr),
	.in_lr_data(in_lr_data),
	.in_lr_data_valid(in_lr_data_valid),
	.in_lr_data_valid_wr(in_lr_data_valid_wr),
	.pktin_ready(pktin_ready),
	.precision_time(precision_time),

	.out_lr_data(out_lr_data),
	.out_lr_data_wr(out_lr_data_wr),
	.out_lr_data_valid(out_lr_data_valid),
	.out_lr_data_valid_wr(out_lr_data_valid_wr),

	.direction(direction),
	.token_bucket_para(token_bucket_para),
	.direct_mac_addr(direct_mac_addr),

	.esw_pktin_cnt(esw_pktin_cnt),
	.esw_pktout_cnt(esw_pktout_cnt),
	.bufm_id_cnt(bufm_id_cnt),


	.eos_q0_used_cnt(eos_q0_used_cnt),
	.eos_q1_used_cnt(eos_q1_used_cnt),
	.eos_q2_used_cnt(eos_q2_used_cnt),
	.eos_q3_used_cnt(eos_q3_used_cnt),

	.eos_mdin_cnt(eos_mdin_cnt),
	.eos_mdout_cnt(eos_mdout_cnt),

	.goe_pktin_cnt(goe_pktin_cnt),
	.goe_port0out_cnt(goe_port0out_cnt),
	.goe_port1out_cnt(goe_port1out_cnt),
	.goe_discard_cnt(goe_discard_cnt),

	.in_local_mac_id(in_local_mac_id),
	.out_local_mac_id(out_local_mac_id)

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

initial begin
//*******************************cnts & regs****************************//
	precision_time = 48'b0;
	in_local_mac_id = 48'b1;
	direction= 1'b1;
	token_bucket_para = 32'd21;
	esw_pktin_cnt = 64'b1;
	esw_pktout_cnt = 64'b1;
	bufm_id_cnt = 8'b0;
	direct_mac_addr = 48'b1011;

	eos_q0_used_cnt = 6'd12;
	eos_q1_used_cnt = 6'd12;
	eos_q2_used_cnt = 6'd12;
	eos_q3_used_cnt = 6'd12;

	eos_mdin_cnt = 64'd32;
	eos_mdout_cnt = 64'd32;

	goe_pktin_cnt = 64'd82;
	goe_port0out_cnt = 64'd82;
	goe_port1out_cnt = 64'd82;
	goe_discard_cnt = 64'd82;

//*******************************cnts & regs****************************//
end

//start user code
initial begin


	//tb for control path
	in_lr_data_wr = 1'b0;
	/**the 1st control packet*/
	#(2*CYCLE) 
	in_lr_data_wr = 1'b1;
	in_lr_data = {2'b01,132'hff};
	in_lr_data_valid = 1'b0;
	in_lr_data_valid_wr = 1'b0;

	#CYCLE
	in_lr_data_wr = 1'b0;
	in_lr_data = 134'b0;
	in_lr_data_valid = 1'b0;
	in_lr_data_valid_wr = 1'b0;

	#CYCLE 
	in_lr_data_wr = 1'b1;
	in_lr_data = {2'b11,132'hff};
	in_lr_data_valid = 1'b0;
	in_lr_data_valid_wr = 1'b0;

	#CYCLE 
	in_lr_data_wr = 1'b1;
	in_lr_data = {2'b11, 4'b0, 48'h1, 68'b0, 4'hf, 8'b0};
	in_lr_data_valid = 1'b0;
	in_lr_data_valid_wr = 1'b0;

	#CYCLE 
	in_lr_data_wr = 1'b1;
	in_lr_data = {2'b11,132'h2};
	in_lr_data_valid = 1'b0;
	in_lr_data_valid_wr = 1'b0;

	#CYCLE 
	in_lr_data_wr = 1'b1;
	in_lr_data = {2'b11,132'h3};
	in_lr_data_valid = 1'b0;
	in_lr_data_valid_wr = 1'b0;

	#CYCLE 
	in_lr_data_wr = 1'b1;
	in_lr_data = {2'b10,132'h4};
	in_lr_data_valid = 1'b1;
	in_lr_data_valid_wr = 1'b1;

	#CYCLE 
	in_lr_data_wr = 1'b0;
	in_lr_data = 134'b0;
	in_lr_data_valid = 1'b0;
	in_lr_data_valid_wr = 1'b0;


	#(30*CYCLE);
	$finish; 
	
end

always begin
	#(CYCLE/2) clk = ~ clk;
end

always begin
	#CYCLE
	precision_time = precision_time + 48'b1;
end

endmodule