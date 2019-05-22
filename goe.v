/////////////////////////////////////////////////////////////////
// Copyright (c) 2018-2025 Xperis, Inc.  All rights reserved.
//*************************************************************
//                     Basic Information
//*************************************************************
//Vendor: Hunan Xperis Network Technology Co.,Ltd.
//Xperis URL://www.xperis.com.cn
//FAST URL://www.fastswitch.org 
//Target Device: Xilinx
//Filename: goe.v
//Version: 2.0
//Author : FAST Group
//*************************************************************
//                     Module Description
//*************************************************************
// 1)Transmit pkt to port or cpu
//*************************************************************
//                     Revision List
//*************************************************************
//	rn1: 
//      date:  2018/08/24
//      modifier: 
//      description: 
///////////////////////////////////////////////////////////////// 
module goe #(
    parameter   PLATFORM = "Xilinx",
	            LMID = 8'd5
    )(
    input clk,
    input rst_n,
	
//uda pkt waiting for transmit
    input in_goe_data_wr,
    input [133:0] in_goe_data,
    input in_goe_valid_wr,
    input in_goe_valid,
	
//pkt waiting for transmit
    output reg pktout_data_wr,
    output reg [133:0] pktout_data,
    output reg pktout_data_valid_wr,
    output reg pktout_data_valid
	
);

//***************************************************
//        Intermediate variable Declaration
//***************************************************
//all wire/reg/parameter variable 
//should be declare below here 

//state
reg [1:0]goe_state;

localparam  IDLE_S = 2'b01,
			Trans_S = 2'b10;

always @(posedge clk or negedge rst_n) begin
	if(rst_n == 1'b0) begin
		pktout_data <= 134'b0;
		pktout_data_wr <= 1'b0;
		pktout_data_valid <= 1'b0;
		pktout_data_valid_wr <= 1'b0;

		goe_state <= IDLE_S;
	end

	else begin
		case(goe_state)
			IDLE_S:begin
				if(in_goe_data_wr == 1'b1) begin
					pktout_data <= in_goe_data;
					pktout_data_wr <= in_goe_data_wr;
					pktout_data_valid <= in_goe_data_valid;
					pktout_data_valid_wr <= in_goe_data_valid_wr;

					goe_state <= Trans_S;
				end

				else begin
					pktout_data <= 134'b0;
					pktout_data_wr <= 1'b0;
					pktout_data_valid <= 1'b0;
					pktout_data_valid_wr <= 1'b0;

					goe_state <= IDLE_S;
				end
			end

			Trans_S: begin
				if(in_goe_data[133:132] == 2'b10) begin
					pktout_data <= in_goe_data;
					pktout_data_wr <= in_goe_data_wr;
					pktout_data_valid <= in_goe_data_valid;
					pktout_data_valid_wr <= in_goe_data_valid_wr;

					goe_state <= IDLE_S;
				end
				
				else begin
					pktout_data <= in_goe_data;
					pktout_data_wr <= in_goe_data_wr;
					pktout_data_valid <= in_goe_data_valid;
					pktout_data_valid_wr <= in_goe_data_valid_wr;

					goe_state <= Trans_S;
				end
			end
		endcase
	end
end
 	   
endmodule                
