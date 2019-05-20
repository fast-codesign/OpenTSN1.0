/////////////////////////////////////////////////////////////////
// Copyright (c) 2018-2025 FAST Group, Inc.  All rights reserved.
//*************************************************************
//                     Basic Information
//*************************************************************
//Vendor: FAST Group.
//Xperis URL://www.xperis.com.cn
//FAST URL://www.fastswitch.org 
//Target Device: Xilinx
//Filename: pac.v
//Version: 1.0
//Author : FAST Group
//*************************************************************
//                     Module Description
//*************************************************************
// 1)transmit according to different purposes of the pkt
// 2)modify FAST_MD
// 3)structure TSN_MD
// 4)traffic regulation
//*************************************************************
//                     Revision List
//*************************************************************
//	rn1: 
//      date:  2019/05/11
//      modifier: 
//      description: 
//////////////////////////////////////////////////////////////

module pac(
input     wire    clk,
input     wire    rst_n,

//////////pkt and in_pac_action from pfw /////
input     wire    [133:0]in_pac_data,
input     wire    in_pac_data_wr,
input     wire    in_pac_valid,
input     wire    in_pac_valid_wr,
input     wire    [8:0]in_pac_action,
input     wire    in_pac_action_wr,

/////////pkt and tsn_md to ibm///////  
output    reg     [133:0]out_pac_data,
output    reg     out_pac_data_wr,
output    reg     out_pac_valid,
output    reg     out_pac_valid_wr,
(*mark_debug="TRUE"*) output    reg     [23:0]out_pac_tsn_md,
(*mark_debug="TRUE"*) output    reg     out_pac_tsn_md_wr,
input     wire    [4:0]bufm_ID_count,

////////pkt to goe ///////////////
output    reg     [133:0]out_pac2port_data2,
output    reg     out_pac2port_data_wr2,
output    reg     out_pac2port_valid2,
output    reg     out_pac2port_valid_wr2,

output    reg    [133:0]out_pac2port_data3,
output    reg    out_pac2port_data_wr3,
output    reg    out_pac2port_valid3,
output    reg    out_pac2port_valid_wr3,

//////reg from or to lcm /////////////
output    reg     [63:0]esw_pktout_cnt,
output    wire    [7:0]bufm_ID_cnt
);
/////////register///////////////////
reg     [133:0]delay1;
reg     [133:0]delay0;
/////////state machine/////////////
(*mark_debug="TRUE"*) reg     [2:0]pac_state;

localparam  IDLE_S   = 3'd0,
            DIR_S    = 3'd1,
            TRA_S    = 3'd2,
			TRANS_S  = 3'd3,
			DIC_S    = 3'd4;

assign bufm_ID_cnt = {3'h0,bufm_ID_count};

always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0)begin
		   out_pac_data      <= 134'h0;
	       out_pac_data_wr   <= 1'h0;
	       out_pac_valid     <= 1'h0;
	       out_pac_valid_wr  <= 1'h0;	  
		   out_pac_tsn_md    <= 24'h0;
		   out_pac_tsn_md_wr <= 1'h0;
	  
		   out_pac2port_data2    <= 134'h0;
	       out_pac2port_data_wr2 <= 1'h0;
	       out_pac2port_valid2   <= 1'h0;
	       out_pac2port_valid_wr2<= 1'h0;	

		   pac_state	 	 <= IDLE_S;
	  end
	  else begin
		   case(pac_state)
				IDLE_S:begin
					out_pac_data      <= 134'h0;
					out_pac_data_wr   <= 1'h0;
					out_pac_valid     <= 1'h0;
					out_pac_valid_wr  <= 1'h0;	  
					out_pac_tsn_md    <= 24'h0;
					out_pac_tsn_md_wr <= 1'h0;
					if(in_pac_data_wr == 1'b1)begin						
						if(in_pac_action[5:0] == 6'h2)begin
							out_pac2port_data2    <= {in_pac_data[133:118],in_pac_action[5:0],in_pac_data[111:0]};
							out_pac2port_data_wr2 <= 1'h1;
							out_pac2port_valid2   <= 1'h0;
							out_pac2port_valid_wr2<= 1'h0;	
							
							pac_state	 	  <= DIR_S;
						end
						else begin
							out_pac2port_data2    <= 134'h0;
							out_pac2port_data_wr2 <= 1'h0;
							out_pac2port_valid2   <= 1'h0;
							out_pac2port_valid_wr2<= 1'h0;	
							
							delay0            <= {in_pac_data[133:118],in_pac_action[5:0],in_pac_data[111:0]};					
							pac_state	 	  <= TRA_S;
						end
					end
					else begin
						out_pac2port_data2    <= 134'h0;
                        out_pac2port_data_wr2 <= 1'h0;
                        out_pac2port_valid2   <= 1'h0;
                        out_pac2port_valid_wr2<= 1'h0;  
                         
                        pac_state	 	  <= IDLE_S; 					
					end
				end
				DIR_S:begin
					out_pac2port_data2    <= in_pac_data;
					out_pac2port_data_wr2 <= 1'h1;
					if(in_pac_data[133:132] == 2'b10)begin
						out_pac2port_valid2   <= 1'h1;
						out_pac2port_valid_wr2<= 1'h1;	

						pac_state	 	 <= IDLE_S;
					end
					else begin
						out_pac2port_valid2   <= 1'h0;
						out_pac2port_valid_wr2<= 1'h0;		

						pac_state	 	 <= DIR_S;
					end
				end
				TRA_S:begin						
					if(in_pac_data_wr == 1'b1)begin
						delay0            <= in_pac_data;
						delay1            <= delay0;	
						out_pac_tsn_md 	  <= {in_pac_action[8:6],delay0[107:96],in_pac_action[0],8'h0};
						if( bufm_ID_count == 5'h02 )begin
							if(in_pac_action[8:6] == 3'h0)begin
								pac_state      <= DIC_S;
							end
							else begin
								pac_state      <= TRANS_S;
							end
						end
						else if(bufm_ID_count == 5'h1)begin
							if((in_pac_action[8:6] == 3'h0)||(in_pac_action[8:6] == 3'h1))begin
								pac_state      <= DIC_S;
							end
							else begin
								pac_state      <= TRANS_S;
							end				 
						end
						else begin
							pac_state      <= TRANS_S;
						end
					end
					else begin
						delay0            <= delay0;
                        delay1            <= delay1;    					
					    pac_state         <= TRA_S;
					end    
				end
				TRANS_S:begin
					delay0            <= in_pac_data;
					delay1            <= delay0;

					out_pac_data      <= delay1;
					out_pac_data_wr   <= 1'h1;					
					if(delay1[133:132] == 2'b10)begin
						out_pac_valid     <= 1'h1;
						out_pac_valid_wr  <= 1'h1;	
						out_pac_tsn_md_wr <= 1'h0;

						pac_state      <= IDLE_S;
					end
					else begin
						out_pac_valid     <= 1'h0;
						out_pac_valid_wr  <= 1'h0;
						out_pac_tsn_md_wr <= 1'h1;
						
						pac_state      <= TRANS_S;
					end
				end
				DIC_S:begin
					out_pac_data      <= 134'h0;
					out_pac_data_wr   <= 1'h0;
					out_pac_valid     <= 1'h0;
					out_pac_valid_wr  <= 1'h0;	  
					out_pac_tsn_md    <= 24'h0;
					out_pac_tsn_md_wr <= 1'h0;
					delay0            <= 134'h0;
					delay1            <= 134'h0;					
					if(in_pac_data[133:132] == 2'b10)begin
						pac_state <= IDLE_S;
					end
					else begin
						pac_state <= DIC_S;
					end
				end
				default:begin
					out_pac_data      <= 134'h0;
					out_pac_data_wr   <= 1'h0;
					out_pac_valid     <= 1'h0;
					out_pac_valid_wr  <= 1'h0;	  
					out_pac_tsn_md    <= 24'h0;
					out_pac_tsn_md_wr <= 1'h0;
				
					out_pac2port_data2    <= 134'h0;
					out_pac2port_data_wr2 <= 1'h0;
					out_pac2port_valid2   <= 1'h0;
					out_pac2port_valid_wr2<= 1'h0;	
			
					pac_state	 	 <= IDLE_S;
				end
		   endcase
	  end
end

always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0)begin
	       out_pac2port_data3      <= 134'h0;
		   out_pac2port_data_wr3   <= 1'h0;
		   out_pac2port_valid3     <= 1'h0;
		   out_pac2port_valid_wr3  <= 1'h0;	   
	  end
	  else begin
		   case({out_pac_data_wr,out_pac2port_data_wr2})
		   2'b01:begin
	              out_pac2port_data3      <= out_pac2port_data2;
		          out_pac2port_data_wr3   <= out_pac2port_data_wr2;
		          out_pac2port_valid3     <= out_pac2port_valid2;
		          out_pac2port_valid_wr3  <= out_pac2port_valid_wr2;			          
		   end
		   
		   2'b10:begin
		          out_pac2port_data3      <= out_pac_data;
				  out_pac2port_data_wr3   <= out_pac_data_wr;
				  out_pac2port_valid3     <= out_pac_valid;
		          out_pac2port_valid_wr3  <= out_pac_valid_wr;	
		   end
		   
		   default:begin
	              out_pac2port_data3      <= 134'h0;
		          out_pac2port_data_wr3   <= 1'h0;
		          out_pac2port_valid3     <= 1'h0;
		          out_pac2port_valid_wr3  <= 1'h0;	   		   
		   end
		   endcase
	  end
end
////////////////pkt out count //////////////////////
always @(posedge clk or negedge rst_n) begin
      if(rst_n == 1'b0)begin
	       esw_pktout_cnt <= 64'h0;
	  end
	  else begin
	       if(out_pac2port_valid_wr3 == 1'b1)begin
		        esw_pktout_cnt <= esw_pktout_cnt + 64'h1;
		   end
		   else begin
		        esw_pktout_cnt <= esw_pktout_cnt;
		   end
	  end
end
endmodule
/**************************
pac  pac{
.clk(),
.rst_n(),

//////////pkt and in_pac_action from pfw /////
.in_pac_data(),
.in_pac_data_wr(),
.in_pac_valid(),
.in_pac_valid_wr(),
.in_pac_action(),
.in_pac_action_wr(),

/////////pkt and tsn_md to ibm///////  
.out_pac_data(),
.out_pac_data_wr(),
.out_pac_valid(),
.out_pac_valid_wr(),
.out_pac_tsn_md(),
.out_pac_tsn_md_wr(),
.bufm_ID_count(),

////////pkt to goe ///////////////
.out_pac2port_data2(),
.out_pac2port_data_wr2(),
.out_pac2port_valid2(),
.out_pac2port_valid_wr2(),

.out_pac2port_data3(),
.out_pac2port_data_wr3(),
.out_pac2port_valid3(),
.out_pac2port_valid_wr3(),

//////reg from or to lcm /////////////
.esw_pktout_cnt(),
.bufm_ID_cnt()
};
*************************/