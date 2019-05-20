/////////////////////////////////////////////////////////////////
// Copyright (c) 2018-2025 FAST Group, Inc.  All rights reserved.
//*************************************************************
//                     Basic Information
//*************************************************************
//Vendor:FAST Group.
//Xperis URL://www.xperis.com.cn
//FAST URL://www.fastswitch.org 
//Target Device: Xilinx
//Filename: ebm.v
//Version: 3.1
//Author : FAST Group
//*************************************************************
//                     Module Description
//*************************************************************
// 1)receive pkt from data_cache
// 2)transmit id to data_cache
//*************************************************************
//                     Revision List
//*************************************************************
//	rn1: 
//      date:  2019/04/01
//      modifier: 
//      description: 
///////////////////////////////////////////////////////////////// 
`timescale 1ns / 1ps

module ebm(
input  wire   clk,
input  wire   rst_n,
	
//input pkt from data_cache
input  wire   [133:0]in_ebm_data,
input  wire   in_ebm_data_wr,
input  wire   in_ebm_valid,
input  wire   in_ebm_valid_wr,
output  reg   [7:0]out_ebm_ID,
output  reg   out_ebm_ID_wr,
	
//transport to next module
output  reg   [133:0]out_ebm_data,
output  reg   out_ebm_data_wr,
output  reg   out_ebm_valid,
output  reg   out_ebm_valid_wr,

//input tsn_md from eos
input  wire   [11:0]in_ebm_md,
input  wire   in_ebm_md_wr
);

reg      [1:0]ebm_state;
localparam    IDLE_S   =2'd0,
			  WITE_S   =2'd1,
		      TRAN_S   =2'd2;
			  
always @(posedge clk or negedge rst_n) begin 
    if(rst_n == 1'b0) begin 
	      out_ebm_data      <=134'b0;
		  out_ebm_data_wr   <=1'b0;
		  out_ebm_valid     <=1'b0;
		  out_ebm_valid_wr  <=1'b0;

		  out_ebm_ID        <= 8'b0;
		  out_ebm_ID_wr     <= 1'b0;
		  
		  ebm_state         <= IDLE_S;		  
	end
	else begin
		 case(ebm_state)
			IDLE_S:begin
				   out_ebm_data      <=134'b0;
		           out_ebm_data_wr   <=1'b0;
		           out_ebm_valid     <=1'b0;
		           out_ebm_valid_wr  <=1'b0;
				   
				   if(in_ebm_md_wr == 1'h1)begin
					    out_ebm_ID     <= in_ebm_md[7:0];
						out_ebm_ID_wr  <= 1'b1;
						
						ebm_state      <= WITE_S;
				   end
				   else begin
					    out_ebm_ID     <= 8'h0;
						out_ebm_ID_wr  <= 1'b0;
						
						ebm_state      <= IDLE_S;		  
				   end
			end
			WITE_S:begin			   
				   if(in_ebm_data_wr == 1'b1)begin
					    out_ebm_data    <= in_ebm_data;
						out_ebm_data_wr <= 1'h1;
						
						ebm_state       <= TRAN_S;	
				   end
				   else begin
					    out_ebm_data    <= 134'h0;
						out_ebm_data_wr <= 1'h0;
						
						ebm_state       <= WITE_S;				   
				   end
			end
			TRAN_S:begin
				   out_ebm_data    <= in_ebm_data;
				   out_ebm_data_wr <= 1'h1;			
				   if(in_ebm_data[133:132] == 2'b10)begin
		                out_ebm_valid     <=1'b1;
		                out_ebm_valid_wr  <=1'b1;
		                out_ebm_ID_wr     <= 1'b0;
						
						ebm_state         <= IDLE_S;
				   end
				   else begin
		                out_ebm_valid     <=1'b0;
		                out_ebm_valid_wr  <=1'b0;
						
						ebm_state         <= TRAN_S;				   
				   end
			end
			default:begin
	               out_ebm_data      <=134'b0;
		           out_ebm_data_wr   <=1'b0;
		           out_ebm_valid     <=1'b0;
		           out_ebm_valid_wr  <=1'b0;
                   
		           out_ebm_ID        <= 8'b0;
		           out_ebm_ID_wr     <= 1'b0;
		           
		           ebm_state         <= IDLE_S;	
			end	
	     endcase
    end		  
end	
endmodule	
/*****************************
ebm ebm_inst(
.clk(),
.rst_n(),

.in_ebm_data(),
.in_ebm_data_wr(),
.in_ebm_valid(),
.in_ebm_valid_wr(),
.out_ebm_ID(),
.out_ebm_ID_wr(),

.out_ebm_data(),
.out_ebm_data_wr(),
.out_ebm_valid(),
.out_ebm_valid_wr(),

.in_ebm_md(),
.in_ebm_md_wr()  
);
*****************************/
			  