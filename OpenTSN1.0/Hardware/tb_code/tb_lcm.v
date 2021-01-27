`timescale 1 ns/ 1ps
module lcm_tb
	(
	);
//define reg and wire


	reg clk;
	reg rst_n;

//receive data & phv from Previous module
	
    reg [1023:0] in_pgm_phv;
	reg in_pgm_phv_wr;
	wire out_pgm_phv_alf;

	reg [133:0] in_pgm_data;
	reg in_pgm_data_wr;
	reg in_pgm_valid_wr;
	reg in_pgm_valid;
	wire out_pgm_alf;

//transport phv and data to GOE
    wire [1023:0] out_pgm_phv;
	wire out_pgm_phv_wr;
	reg in_pgm_phv_alf;
	wire [133:0] out_pgm_data;
	wire out_pgm_data_wr;
	wire out_pgm_valid;
	wire out_pgm_valid_wr;
	reg in_pgm_alf;


//signals to PRM_R;
	wire out_pgm_sent_start_flag;
	wire out_pgm_sent_finish_flag;

//reg cfg packet from DMA
    reg [133:0] cin_pgm_data;
	reg cin_pgm_data_wr;
	wire cout_pgm_ready;

//wire configure pkt to next module
    wire [133:0] cout_pgm_data;
	wire cout_pgm_data_wr;
	reg cin_pgm_ready;




//initialize module
pgm pgm_ctl_tb(

	.clk(clk),
	.rst_n(rst_n),
	.in_pgm_phv(in_pgm_phv),
	.in_pgm_phv_wr(in_pgm_phv_wr), 
	.out_pgm_phv_alf(out_pgm_phv_wr),
	.in_pgm_data(in_pgm_data),
	.in_pgm_data_wr(in_pgm_data_wr),
	.in_pgm_valid_wr(in_pgm_valid_wr),
	.in_pgm_valid(in_pgm_valid),
	.out_pgm_alf(out_pgm_alf),

//transport phv and data to pgm_rd
    .out_pgm_phv(out_pgm_phv),
	.out_pgm_phv_wr(out_pgm_phv_wr),
	.in_pgm_phv_alf(in_pgm_phv_alf),

	.out_pgm_data(out_pgm_data), 
	.out_pgm_data_wr(out_pgm_data_wr),
	.out_pgm_valid(out_pgm_valid),
	.out_pgm_valid_wr(out_pgm_valid_wr),
	.in_pgm_alf(in_pgm_alf),


//signals to PRM_RD
	.out_pgm_sent_start_flag(out_pgm_sent_start_flag),
	.out_pgm_sent_finish_flag(out_pgm_sent_finish_flag),

//reg cfg packet from DMA
    .cin_pgm_data(cin_pgm_data),
	.cin_pgm_data_wr(cin_pgm_data_wr),
	.cout_pgm_ready(cout_pgm_ready),

//wire configure pkt to next module
    .cout_pgm_data(cout_pgm_data),
	.cout_pgm_data_wr(cout_pgm_data_wr),
	.cin_pgm_ready(cin_pgm_ready)
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

	//tb for control path
	//
	/**the 1st control packet*/
	#CYCLE in_pgm_phv = 1024'b0;
	in_pgm_phv_wr = 1'b0;
	in_pgm_phv_wr = 1'b0;
	in_pgm_data = 133'b0;
	in_pgm_data_wr = 1'b0;
	in_pgm_valid = 1'b0;
	in_pgm_valid_wr = 1'b0;
	in_pgm_alf = 1'b0;

	cin_pgm_ready = 1'b1;

	cin_pgm_data_wr = 1'b1;
	cin_pgm_data = {6'b010000,1'b1,3'b010,12'b0,8'd70,8'd61,32'h00010001,32'hffffffff,32'h00004000};


#CYCLE in_pgm_phv = 1024'b0;
	in_pgm_phv_wr = 1'b0;
	in_pgm_phv_wr = 1'b0;
	in_pgm_data = 133'b0;
	in_pgm_data_wr = 1'b0;
	in_pgm_valid = 1'b0;
	in_pgm_valid_wr = 1'b0;
	in_pgm_alf = 1'b0;

	cin_pgm_ready = 1'b1;

	cin_pgm_data_wr = 1'b1;
	cin_pgm_data = {6'b100000,1'b1,3'b010,12'b0,8'd70,8'd61,32'h00010001,32'hffffffff,32'h00000000};


	
// 2nd control packet
	#CYCLE in_pgm_phv = 1024'b0;
	in_pgm_phv_wr = 1'b0;
	in_pgm_phv_wr = 1'b0;

	in_pgm_data = 133'b0;
	in_pgm_data_wr = 1'b0;
	in_pgm_valid = 1'b0;
	in_pgm_valid_wr = 1'b0;
	in_pgm_alf = 1'b0;

	cin_pgm_ready = 1'b1;

	cin_pgm_data_wr = 1'b1;
	cin_pgm_data = {6'b010000,1'b1,3'b010,12'b0,8'd70,8'd61,32'h00010002,32'hffffffff,32'h000000000};


	#CYCLE in_pgm_phv = 1024'b0;
	in_pgm_phv_wr = 1'b0;
	in_pgm_phv_wr = 1'b0;

	in_pgm_data = 133'b0;
	in_pgm_data_wr = 1'b0;
	in_pgm_valid = 1'b0;
	in_pgm_valid_wr = 1'b0;
	in_pgm_alf = 1'b0;

	cin_pgm_ready = 1'b1;

	cin_pgm_data_wr = 1'b1;
	cin_pgm_data = {6'b100000,1'b1,3'b010,12'b0,8'd70,8'd61,32'h00010002,32'hffffffff,32'h00000000};


//3rd control packet

	#CYCLE in_pgm_phv = 1024'b0;
	in_pgm_phv_wr = 1'b0;
	in_pgm_phv_wr = 1'b0;

	in_pgm_data = 133'b0;
	in_pgm_data_wr = 1'b0;
	in_pgm_valid = 1'b0;
	in_pgm_valid_wr = 1'b0;
	in_pgm_alf = 1'b0;

	cin_pgm_ready = 1'b1;

	cin_pgm_data_wr = 1'b1;
	cin_pgm_data = {6'b010000,1'b1,3'b010,12'b0,8'd70,8'd62,32'h00010001,32'hffffffff,32'h0000000a};


	#CYCLE in_pgm_phv = 1024'b0;
	in_pgm_phv_wr = 1'b0;
	in_pgm_phv_wr = 1'b0;

	in_pgm_data = 133'b0;
	in_pgm_data_wr = 1'b0;
	in_pgm_valid = 1'b0;
	in_pgm_valid_wr = 1'b0;
	in_pgm_alf = 1'b0;

	cin_pgm_ready = 1'b1;

	cin_pgm_data_wr = 1'b1;
	cin_pgm_data = {6'b100000,1'b1,3'b010,12'b0,8'd70,8'd62,32'h00010001,32'hffffffff,32'h00000000};
//4th control packet

	#CYCLE in_pgm_phv = 1024'b0;
	in_pgm_phv_wr = 1'b0;
	in_pgm_phv_wr = 1'b0;

	in_pgm_data = 133'b0;
	in_pgm_data_wr = 1'b0;
	in_pgm_valid = 1'b0;
	in_pgm_valid_wr = 1'b0;
	in_pgm_alf = 1'b0;

	cin_pgm_ready = 1'b1;

	cin_pgm_data_wr = 1'b1;
	cin_pgm_data = {6'b010000,1'b1,3'b010,12'b0,8'd70,8'd62,32'h00010002,32'hffffffff,32'h00000000};


	#CYCLE in_pgm_phv = 1024'b0;
	in_pgm_phv_wr = 1'b0;
	in_pgm_phv_wr = 1'b0;

	in_pgm_data = 133'b0;
	in_pgm_data_wr = 1'b0;
	in_pgm_valid = 1'b0;
	in_pgm_valid_wr = 1'b0;
	in_pgm_alf = 1'b0;

	cin_pgm_ready = 1'b1;

	cin_pgm_data_wr = 1'b1;
	cin_pgm_data = {6'b100000,1'b1,3'b010,12'b0,8'd70,8'd62,32'h00010002,32'hffffffff,32'h00000000};
	

//finish the trans
	#CYCLE 
   	cin_pgm_data_wr <= 1'b0;
   	cin_pgm_data = 134'b0;



/**start data plane trans*/

/**1st packet*/
	#CYCLE
	in_pgm_phv = 1024'b1;
	in_pgm_phv_wr = 1'b1;
	in_pgm_phv_alf = 1'b0;

	in_pgm_data = {6'b010000, 16'b0, 3'b111, 13'b0, 32'b0, 64'b0};

	in_pgm_data_wr = 1'b1;
	in_pgm_valid = 1'b0;
	in_pgm_valid_wr = 1'b0;
	in_pgm_alf = 1'b0;

	#CYCLE 
	in_pgm_phv_wr = 1'b0;
	in_pgm_phv = 1024'b0;
	in_pgm_data = {6'b110000, 16'b1, 16'b0, 32'b0, 64'd2};

	#CYCLE 
	in_pgm_data = {6'b110000, 16'b0, 16'b0, 32'b0, 64'd2};

	#CYCLE
	in_pgm_data = {6'b100000, 16'b0, 16'b0, 32'b0, 64'd2};

	#CYCLE
	in_pgm_data = 134'b0;
	in_pgm_data_wr = 1'b0;
	in_pgm_valid = 1'b1;
	in_pgm_valid_wr = 1'b1;


	#(2*CYCLE)

/**2nd packet*/
	in_pgm_phv = 1024'b1;
	in_pgm_phv_wr = 1'b1;
	in_pgm_phv_alf = 1'b0;

	in_pgm_data = {6'b010000, 16'b0, 3'b111, 13'b0, 32'b0, 64'b0};

	in_pgm_data_wr = 1'b1;
	in_pgm_valid = 1'b0;
	in_pgm_valid_wr = 1'b0;
	in_pgm_alf = 1'b0;

	#CYCLE 
	in_pgm_phv_wr = 1'b0;
	in_pgm_phv = 1024'b0;
	in_pgm_data = {6'b110000, 16'b1, 16'b0, 32'b0, 64'd2};

	#CYCLE 
	in_pgm_data = {6'b110000, 16'b0, 16'b0, 32'b0, 64'd2};

	#CYCLE
	in_pgm_data = {6'b100000, 16'b0, 16'b0, 32'b0, 64'd2};

	#CYCLE
	in_pgm_data = 134'b0;
	in_pgm_data_wr = 1'b0;
	in_pgm_valid = 1'b1;
	in_pgm_valid_wr = 1'b1;

/**finish trans*/

	#CYCLE
	in_pgm_data = 134'b0;
	in_pgm_data_wr = 1'b0;
	in_pgm_valid = 1'b0;
	in_pgm_valid_wr = 1'b0;


	#(10*CYCLE);
	$finish; 
	
end

always begin
	#(CYCLE/2) clk = ~ clk;
end

endmodule