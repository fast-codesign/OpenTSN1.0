/////////////////////////////////////////////////////////////////
// MIT License
//*************************************************************
//                     Basic Information
//*************************************************************
//Vendor: NUDT
//FAST URL://www.fastswitch.org 
//Target Device: Xilinx/Intel
//Filename: lreport.v
//Version: 1.0
//Author : FAST Group
//*************************************************************
//                     Module Description
//*************************************************************
// 1)LCM: generate beacon report message;
//        process beacon update message.
//*************************************************************
//                     Revision List
//*************************************************************
//      date:  2019/05/13
//      modifier: 
//      description: 
///////////////////////////////////////////////////////////////// 
`timescale 1ns / 1ps
module lreport #(
	parameter LMID = 8'd11
	)(
	input clk,
	input rst_n,

//um signal 
	input in_lr_data_wr,
	input [133:0] in_lr_data,
	input in_lr_data_valid,
	input in_lr_data_valid_wr,

	output reg pktin_ready,
	input [47:0] precision_time,
	input [47:0] in_local_mac_id,   //should be changed to [47:0], represents a mac addr.

//lupdate signal 
	output out_lr_data_wr,
	output [133:0] out_lr_data,
	output out_lr_data_valid,
	output out_lr_data_valid_wr,

	output [47:0] out_lr_mac_id,  //should be changed to [47:0], represents a mac addr.

//readable & changeable registers and counters

	input direction,
	input [31:0] token_bucket_para,
	input [47:0] direct_mac_addr,

	//input from esw
	input [63:0] esw_pktin_cnt,
	input [63:0] esw_pktout_cnt,
	input [7:0] bufm_id_cnt,

	//input from eos
	input [5:0] eos_q0_used_cnt,
	input [5:0] eos_q1_used_cnt,
	input [5:0] eos_q2_used_cnt,
	input [5:0] eos_q3_used_cnt,

	input [63:0] eos_mdin_cnt,
	input [63:0] eos_mdout_cnt,

	//input from goe
	
	input [63:0] goe_pktin_cnt,
	input [63:0] goe_port0out_cnt,
	input [63:0] goe_port1out_cnt,
	input [63:0] goe_discard_cnt

);

//***************************************************
//        Intermediate variable Declaration
//***************************************************
//all wire/reg/parameter variable 
//should be declare below here

//local_mac_addr = 00-06-06-02-00-00-00-ID

parameter cnc_mac_addr = 48'h010203040506;  //CNC节点mac地址
parameter time_inteval = 20'hFFFFF;  //同步周期为8ms左右  2^20 us


reg [47:0] time_stamp_rec; //record the accurate timestamp.
//reg [19:0] time_inteval_cnt;
reg deadline_when_trans;
//reg [47:0] cnc_mac_addr;

reg [4:0] beacon_report_cycle;

//restore the in_data when needed
reg [133:0] lr_data;
reg lr_data_wr;
reg lr_data_valid;
reg lr_data_valid_wr;

//lreport state machine
reg [2:0] lreport_state;


//============================= beacon report =============================//

parameter IDLE_S = 3'b000,
		Trans_S = 3'b001,
		Haunt1_S = 3'b010,
		Haunt2_S = 3'b101,
		Btrans_S = 3'b011,
		Set_S = 3'b100;

always @(posedge clk or negedge rst_n) begin
	

	if(!rst_n) begin
		deadline_when_trans <= 1'b0;
		lreport_state <= IDLE_S;

		//reset
		lr_data <= 134'b0;
		lr_data_wr <= 1'b0;
		lr_data_valid <= 1'b0;
		lr_data_valid_wr <= 1'b0; 

		out_lr_data <= 134'b0;
		out_lr_data_wr <= 1'b0;
		out_lr_data_valid <= 1'b0;
		out_lr_data_valid_wr <= 1'b0; 

		beacon_report_cycle <= 4'b0;
		time_stamp_rec <= 48'b0;

	end

	else begin
		case(lreport_state)
			IDLE_S:begin
				deadline_when_trans <= 1'b0;
				beacon_report_cycle <= 4'b0;

				if(in_lr_data_wr == 1'b1 && precision_time[19:0] != 20'b0) begin
					out_lr_data_wr <= in_lr_data_wr;
					out_lr_data <= in_lr_data;
					out_lr_data_valid <= in_lr_data_valid;
					out_lr_data_valid_wr <= in_lr_data_valid_wr;
					lreport_state <= Trans_S;
				end

				else if(in_lr_data_wr <= 1'b0 && precision_time[19:0] == 20'b0) begin
					time_stamp_rec <= precision_time;
					pktin_ready <= 1'b1;
					lreport_state <= Haunt1_S;
				end

				//when deadline_when_trans was set when data[133:132] == 2'b10
				else if(in_lr_data_wr <= 1'b0 && deadline_when_trans == 1'b1) begin
					time_stamp_rec <= precision_time;
					pktin_ready <= 1'b1;

					lreport_state <= Haunt1_S;

				end

				else begin
					out_lr_data_wr <= 1'b0;
					out_lr_data <= 134'b0;
					out_lr_data_valid <= 1'b0;
					out_lr_data_valid_wr <= 1'b0;
					lreport_state <= IDLE_S;
				end
			end

			Trans_S:begin
								
				if(precision_time[19:0] == 20'b0)begin
					deadline_when_trans <= 1'b1;
					time_stamp_rec <= precision_time;
				end

				else if(in_lr_data[133:132] == 2'b10)begin
					out_lr_data<= in_lr_data;
					out_lr_data_wr <= in_lr_data_wr;
					out_lr_data_valid <= in_lr_data_valid;
					out_lr_data_valid_wr <= in_lr_data_valid_wr;

					//ready to send beacon report
					if(deadline_when_trans == 1'b1)begin
						lreport_state <= Haunt1_S;
						pktin_ready <= 1'b1;
						deadline_when_trans <= 1'b0;
					end

					else begin
						lreport_state <= IDLE_S;
					end
				end

				else begin
					out_lr_data<= in_lr_data;
					out_lr_data_wr <= in_lr_data_wr;
					out_lr_data_valid <= in_lr_data_valid;
					out_lr_data_valid_wr <= in_lr_data_valid_wr;

					lreport_state <= Trans_S;
				end

				
			end

			Haunt1_S:begin
				//if there is a pkt left to send
				//e.g., when the pktin_ready is set, but another pkt comes.
				
				if(in_lr_data_wr <= 1'b1)begin
					
					pktin_ready <= 1'b0;
					//delay for 1 cycle 
					lreport_state <= Haunt2_S;
					out_lr_data_wr <= 1'b0;
					out_lr_data <= 134'b0;
					out_lr_data_valid <= 1'b0;
					out_lr_data_valid_wr <= 1'b0;

					lr_data <= in_lr_data;
					lr_data_wr <= in_lr_data_wr;
					lr_data_valid <= in_lr_data_valid;
					lr_data_valid_wr <= in_lr_data_valid_wr;


				end

				//lreport can send its own packet
				else begin
					pktin_ready <= 1'b1;

					out_lr_data_wr <= 1'b0;
					out_lr_data <= 134'b0;
					out_lr_data_valid <= 1'b0;
					out_lr_data_valid_wr <= 1'b0;

					lreport_state <= Btrans_S;
				end
			end

			Haunt2_S:begin
				out_lr_data <= lr_data;
				out_lr_data_wr <= lr_data_wr;
				out_lr_data_valid <= in_lr_data_valid;
				out_lr_data_valid_wr <= lr_data_valid_wr;

				lreport_state <= Trans_S;

			end

			//send a beacon report message
			Btrans_S:begin
				beacon_report_cycle <= beacon_report_cycle + 4'b1;
				
				case(beacon_report_cycle)begin
					4'd0:begin
						out_lr_data_wr <= 1'b1;
						out_lr_data <= {2'b01,4'b0,1'b0,1'b0,6'b0,2'b0,6'b0,112'b0};
						out_lr_data_valid <= 1'b0;
						out_lr_data_valid_wr <= 1'b0;
					end

					4'd1:begin
						out_lr_data_wr <= 1'b1;
						out_lr_data <= {2'b11,4'b0,1'b0,1'b0,6'b0,2'b0,6'b0,112'b0};
						out_lr_data_valid <= 1'b0;
						out_lr_data_valid_wr <= 1'b0;
					end
					4'd2:begin
						out_lr_data_wr <= 1'b1;
						out_lr_data <= {2'b11, 4'b0, cnc_mac_addr, in_local_mac_id, 16'h88f7, 4'b0, 4'he, 8'b0};
						out_lr_data_valid <= 1'b0;
						out_lr_data_valid_wr <= 1'b0;
					end
					4'd3:begin
						out_lr_data_wr <= 1'b1;
						out_lr_data <= {2'b11,4'b0,16'd176,112'b0}; //contains length field
						out_lr_data_valid <= 1'b0;
						out_lr_data_valid_wr <= 1'b0;
					end
					4'd4:begin
						out_lr_data_wr <= 1'b1;
						out_lr_data <= {2'b11,4'b0,128'b0};
						out_lr_data_valid <= 1'b0;
						out_lr_data_valid_wr <= 1'b0;
					end
					4'd5:begin
						out_lr_data_wr <= 1'b1;
						out_lr_data <= {2'b11,4'b0,32'b0,time_stamp_rec,48'b0};
						out_lr_data_valid <= 1'b0;
						out_lr_data_valid_wr <= 1'b0;
					end
					//beacon field
					4'd6:begin
						out_lr_data_wr <= 1'b1;
						out_lr_data <= {2'b11,4'b0,direct_mac_addr, direction, 15'b0, token_bucket_para,32'b0};
						out_lr_data_valid <= 1'b0;
						out_lr_data_valid_wr <= 1'b0;
					end
					//ESW module
					4'd7:begin
						out_lr_data_wr <= 1'b1;
						out_lr_data <= {2'b11,4'b0,esw_pktin_cnt, esw_pktout_cnt};
						out_lr_data_valid <= 1'b0;
						out_lr_data_valid_wr <= 1'b0;
					end
					4'd8:begin
						out_lr_data_wr <= 1'b1;
						out_lr_data <= {2'b11,4'b0,in_local_mac_id[7:0], bufm_id_cnt, 112'b0};
						out_lr_data_valid <= 1'b0;
						out_lr_data_valid_wr <= 1'b0;
					end
					//EOS module
					4'd9:begin
						out_lr_data_wr <= 1'b1;
						out_lr_data <= {2'b11,4'b0,eos_mdin_cnt, eos_mdout_cnt};
						out_lr_data_valid <= 1'b0;
						out_lr_data_valid_wr <= 1'b0;
					end
					4'd10:begin
						out_lr_data_wr <= 1'b1;
						out_lr_data <= {2'b11,4'b0,eos_q0_used_cnt, eos_q1_used_cnt, eos_q2_used_cnt, eos_q3_used_cnt, time_slot_flag, 103'b0};
						out_lr_data_valid <= 1'b0;
						out_lr_data_valid_wr <= 1'b0;
					end
					//GOE module
					4'd11:begin
						out_lr_data_wr <= 1'b1;
						out_lr_data <= {2'b11,4'b0,goe_pktin_cnt,goe_port0out_cnt};
						out_lr_data_valid <= 1'b0;
						out_lr_data_valid_wr <= 1'b0;
						
					end
					4'd12:begin
						out_lr_data_wr <= 1'b1;
						out_lr_data <= {2'b10,4'b0,goe_port1out_cnt, goe_discard_cnt};
						out_lr_data_valid <= 1'b1;
						out_lr_data_valid_wr <= 1'b1;
						lreport_state <= IDLE_S;
					end
					

				end
			end
	end
end



endmodule
