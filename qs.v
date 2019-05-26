/*========================================================================================================*\
          Filename : qs.v,queue selecting
            Author : peng jintao
       Description : according to pkt_type(md[23:21]) and current time slot which is odd or even, deciding to 
		             transmit md to which fifo of next module(metadata buffer module) for caching.
	     Called by : 
  Revision History : 5/16/2019 Revision 1.0  peng jintao
                     mm/dd/yy
           Company : 662
============================================================================================================
          Comments :
\*========================================================================================================*/

`timescale 1ns/1ps

module qs#(
    parameter    PLATFORM = "xilinx"
)(
//clk & rst
input	wire			clk,
input	wire			rst_n,

//receive from LCM
input	wire			in_qs_time_slot_flag,

//receive from IBM
input	wire	[23:0]	in_qs_md,
input	wire			in_qs_md_wr,

//transmit to MB
output	reg 	[8:0]	out_qs_md0,       //even-time-slot TSN metadata
output	reg 			out_qs_md0_wr,
output	reg 	[8:0]	out_qs_md1,       //odd-time-slot TSN metadata
output	reg 			out_qs_md1_wr,
output	reg 	[15:0]	out_qs_md2,       //bandwidth reservation metadata and PTP metadata
output	reg 			out_qs_md2_wr,
output	reg 	[8:0]	out_qs_md3,       //best effort metadata
output	reg 			out_qs_md3_wr

);

//*******************************************
//         transmit MD to MB
//*******************************************

always @(posedge clk or negedge rst_n) begin 
    if(rst_n == 1'b0) begin 
	    out_qs_md0 <= 9'b0;  
		out_qs_md0_wr <= 1'b0;
		
		out_qs_md1 <= 9'b0;  
		out_qs_md1_wr <= 1'b0;
		
		out_qs_md2 <= 16'b0;  
		out_qs_md2_wr <= 1'b0;
		
		out_qs_md3 <= 9'b0; 
		out_qs_md3_wr <= 1'b0;	
    end 
    else begin 
	    if(in_qs_md_wr == 1'b1)begin
	        if(in_qs_md[23:21] == 3'd3 && in_qs_time_slot_flag == 1'b0) begin
		        out_qs_md0 <= in_qs_md[8:0];  
		    	out_qs_md0_wr <= 1'b1;
		    end
		    else if(in_qs_md[23:21] == 3'd3 && in_qs_time_slot_flag == 1'b1)begin
		        out_qs_md1 <= in_qs_md[8:0];
			    out_qs_md1_wr <= 1'b1;
		    end
		    else if(in_qs_md[23:21] == 3'd2)begin
                out_qs_md2[15:9] <= 7'd0;               //not do traffic shaping in GC module, and not consume tokens
                out_qs_md2[8:0] <= in_qs_md[8:0];
                out_qs_md2_wr <= 1'b1;
            end
			else if(in_qs_md[23:21] == 3'd1)begin
			    out_qs_md2[15:9] <= (in_qs_md[20:9]>>4) - 12'd2;        //pkt_length(Byte)/(16Byte per clock) - 2 clock's metadata
			    out_qs_md2[8:0] <= in_qs_md[8:0];
				out_qs_md2_wr <= 1'b1;
			end
			else if(in_qs_md[23:21] == 3'd0)begin
			    out_qs_md3 <= in_qs_md[8:0];
				out_qs_md3_wr <= 1'b1;
			end
			else begin
			    out_qs_md0 <= 9'b0;  
				out_qs_md0_wr <= 1'b0;
				
				out_qs_md1 <= 9'b0;  
				out_qs_md1_wr <= 1'b0;
				
				out_qs_md2 <= 16'b0;  
				out_qs_md2_wr <= 1'b0;
				
				out_qs_md3 <= 9'b0; 
				out_qs_md3_wr <= 1'b0;		
			end
	    end
		else begin
		    out_qs_md0 <= 9'b0;  
		    out_qs_md0_wr <= 1'b0;
		    
		    out_qs_md1 <= 9'b0;  
		    out_qs_md1_wr <= 1'b0;
		    
		    out_qs_md2 <= 16'b0;  
		    out_qs_md2_wr <= 1'b0;
		    
		    out_qs_md3 <= 9'b0; 
		    out_qs_md3_wr <= 1'b0;	
		end
	end	
end
endmodule

