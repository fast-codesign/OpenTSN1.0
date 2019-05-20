/////////////////////////////////////////////////////////////////
// Copyright (c) 2018-2025 FAST Group, Inc.  All rights reserved.
//*************************************************************
//                     Basic Information
//*************************************************************
//Vendor: FAST Group.
//Xperis URL://www.xperis.com.cn
//FAST URL://www.fastswitch.org 
//Target Device: Xilinx
//Filename: pke.v
//Version: 1.0
//Author : FAST Group
//*************************************************************
//                     Module Description
//*************************************************************
// 1)pkt parse:TSN/PTP/reserbed bandwidth/best effort
// 2)transmit pkt and key and pkttype to pfw.
//*************************************************************
//                     Revision List
//*************************************************************
//	rn1: 
//      date:  2019/05/15
//      modifier: 
//      description: 
//////////////////////////////////////////////////////////////
module  pke(
input     wire    clk,
input     wire    rst_n,

//////////pkt from LCM ////////////////
input     wire    [133:0]in_pke_data,
input     wire    in_pke_data_wr,
input     wire    in_pke_valid,
input     wire    in_pke_valid_wr,
  
/////////pkt and action to PAC ///////  
(*mark_debug="TRUE"*) output    reg     [133:0]out_pke_data,
(*mark_debug="TRUE"*) output    reg     out_pke_data_wr,
output    reg     out_pke_valid,
output    reg     out_pke_valid_wr,
(*mark_debug="TRUE"*) output    reg     [2:0]out_pke_pkttype,
(*mark_debug="TRUE"*) output    reg     [101:0]out_pke_key,

/////////reg  to LCM /////////////////
output    reg     [63:0]esw_pktin_cnt
);

/////////register///////////////////
reg       [133:0]delay0;
reg       [133:0]delay1;

/////////state machine/////////////
(*mark_debug="TRUE"*) reg       [1:0]pke_state;

localparam  IDLE_S   = 2'd0,
            MD1      = 2'd1,
            PARS_S   = 2'd2,
			TRANS_S  = 2'd3;

always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0)begin
		   out_pke_data      <= 134'h0;
		   out_pke_data_wr   <= 1'h0;
		   out_pke_valid     <= 1'h0;
		   out_pke_valid_wr  <= 1'h0;
		   out_pke_pkttype           <= 3'h0;
		   out_pke_key               <= 102'h0;
		   
		   pke_state         <= IDLE_S;
	  end
	  else begin
	  case(pke_state)
		   IDLE_S:begin		
				out_pke_data      <= 134'h0;
				out_pke_data_wr   <= 1'h0;
				out_pke_valid     <= 1'h0;
		        out_pke_valid_wr  <= 1'h0;
				if((in_pke_data_wr == 1'b1)&&(in_pke_data[133:132] == 2'b01))begin
					delay0            <= in_pke_data;
					out_pke_key[5:0]          <= in_pke_data[125:120];
					
					pke_state         <= MD1;
				end
				else begin
					delay0		      <= 134'h0;
					out_pke_key               <= 102'h0;
					
					pke_state         <= IDLE_S;				
				end
		   end
		   MD1:begin	   
				if(in_pke_data_wr == 1'b1)begin
					delay1            <= delay0;
					delay0            <= in_pke_data;				
					
					pke_state         <= PARS_S;					
				end
				else begin
					delay1            <= delay1;
					delay0            <= delay0;
					
					pke_state         <= MD1;				
				end
		   end
		   PARS_S:begin
				out_pke_valid     <= 1'h0;
		        out_pke_valid_wr  <= 1'h0;						
				if(in_pke_data_wr == 1'b1)begin
					out_pke_data      <= delay1;
					out_pke_data_wr   <= 1'h1;		
					
					delay1            <= delay0;
					delay0            <= in_pke_data;
					out_pke_key[101:6]        <= in_pke_data[127:32];					
					if(in_pke_data[31:16]==16'h88F7)begin
						out_pke_pkttype   <= 3'h2;
					end
					else if(in_pke_data[31:16]==16'h8100)begin
						case(in_pke_data[15:13])
							3'h0:begin
								out_pke_pkttype   <= 3'h0;
							end
							3'h1:begin
								out_pke_pkttype   <= 3'h0;
							end
							3'h2:begin
								out_pke_pkttype   <= 3'h0;
							end
							3'h3:begin
								out_pke_pkttype   <= 3'h1;
							end
							3'h4:begin
								out_pke_pkttype   <= 3'h1;
							end
							3'h5:begin
								out_pke_pkttype   <= 3'h1;
							end
							3'h6:begin
								out_pke_pkttype   <= 3'h3;
							end
							3'h7:begin
								out_pke_pkttype   <= 3'h3;
							end
						endcase
					end
					else begin
						out_pke_pkttype   <= 3'h0;
					end
					pke_state         <= TRANS_S;					
				end
				else begin
					out_pke_data      <= 134'h0;
					out_pke_data_wr   <= 1'h0;
					delay1            <= delay1;
					delay0            <= delay0;
					
					pke_state         <= PARS_S;				
				end
		   end
		   TRANS_S:begin
				out_pke_data      <= delay1;
				out_pke_data_wr   <= 1'h1;		
				
				delay1            <= delay0;
				delay0            <= in_pke_data;			
				if(delay1[133:132]==2'b10)begin
					out_pke_valid     <= 1'h1;
					out_pke_valid_wr  <= 1'h1;	
					
					pke_state         <= IDLE_S;
				end
				else begin
					out_pke_valid     <= 1'h0;
					out_pke_valid_wr  <= 1'h0;	
					
					pke_state         <= TRANS_S;
				end
		   end
		   default:begin
			    out_pke_data      <= 134'h0;
		        out_pke_data_wr   <= 1'h0;
		        out_pke_valid     <= 1'h0;
		        out_pke_valid_wr  <= 1'h0;
		        out_pke_pkttype           <= 3'h0;
		        out_pke_key               <= 102'h0;
		        
		        pke_state         <= IDLE_S;
		   end		   	  
	  endcase
	  end
end

////////////////pkt in count //////////////////////
always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0)begin
	       esw_pktin_cnt <= 64'h0;
	  end
	  else begin
	       if(in_pke_valid_wr == 1'b1)begin
		        esw_pktin_cnt <= esw_pktin_cnt + 64'h1;
		   end
		   else begin
		        esw_pktin_cnt <= esw_pktin_cnt;
		   end
	  end
end

endmodule

/****************************************
pke pke(
.clk(),
.rst_n(),

//////////pkt from LCM ////////////////
.in_pke_data(),
.in_pke_data_wr(),
.in_pke_valid(),
.in_pke_valid_wr(),
  
/////////pkt and action to PAC ///////  
.out_pke_data(),
.out_pke_data_wr(),
.out_pke_valid(),
.out_pke_valid_wr(),
.out_pke_pkttype(),
.out_pke_key(),

/////////reg  to LCM /////////////////
.esw_pktin_cnt()
);
****************************************/