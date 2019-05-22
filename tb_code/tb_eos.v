`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/18 21:25:00
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//`define   len           800 
//`define   bufm_id           0 
module tb();
reg        clk;
reg        rst_n;
reg  [23:0]in_eos_md;          
reg        in_eos_md_wr;            
reg        in_eos_pkt_valid;        
reg  [31:0]in_eos_rate_limit;         
reg        in_eos_time_slot_flag;
reg [7:0] pktout_usedw_0;      
reg [7:0] pktout_usedw_1;      
wire  [7:0] out_eos_md;         
wire        out_eos_md_wr;           
wire  [63:0]out_eos_mdin_cnt;  
wire  [63:0]out_eos_mdout_cnt;
wire  [4:0] out_eos_q0_used_cnt;
wire  [4:0] out_eos_q1_used_cnt;
wire  [4:0] out_eos_q2_used_cnt;
wire  [4:0] out_eos_q3_used_cnt;
wire  [31:0]out_eos_rate_limit;      

initial begin//125Mhz
    clk = 1'b0;
    forever #4 clk = ~clk;
end

initial begin//rst_n
    rst_n = 1'b0;
    #50;
    rst_n = 1'b1;
end

initial begin//rst_n
    in_eos_rate_limit = 32'd1;
    #200000;
    in_eos_rate_limit = 32'd10;
        #200000;
    in_eos_rate_limit = 32'd100;
end

//控制进入eos的md的时钟
//reg i_eos_clock;
reg [11:0]i_clk_cnt; 
always@(posedge clk or negedge rst_n)begin
if(!rst_n)begin
	i_clk_cnt <= 12'h0;
//    i_eos_clock   <= 1'b0;
end
else begin
    if(50 == i_clk_cnt)begin
       i_clk_cnt <= 12'b0;
//       i_eos_clock   <= 1'b1;
    end
    else begin
       i_clk_cnt <= i_clk_cnt + 12'b1;
//       i_eos_clock   <= 1'b0;
    end
end
end

//time_slot
reg [15:0] time_slot_cnt;
always@(posedge clk or negedge rst_n)begin
if(!rst_n)begin
	in_eos_time_slot_flag <= 1'b0;
	time_slot_cnt <= 16'd0;
end
else begin
    if(time_slot_cnt>=16'd15999)begin   //time_slot周期为128ns
       time_slot_cnt <= 16'd0;
       in_eos_time_slot_flag <= ~in_eos_time_slot_flag;
    end
    else begin
       time_slot_cnt <= time_slot_cnt+16'd1;
       in_eos_time_slot_flag <= in_eos_time_slot_flag;
    end  
end
end

//每隔50个clock输入一个md
reg [11:0]len;
reg [7:0]bufm_id;
reg [3:0]state;
localparam IDLE_S=4'd0,
            FIRST_S=4'd1,
            SECOND_S=4'd2,
            THIRD_S=4'd3,
		    FOUR_S=4'd4,
		    FIVE_S=4'd5,
		    SIX_S=4'd6,
		    SEVEN_S=4'd7;
always@(posedge clk or negedge rst_n)begin
if(!rst_n)begin
	in_eos_md<=24'b0;
	in_eos_md_wr<=1'b0;
	bufm_id <= 8'd0;
	len <= 12'd64+12'd32;
	state<=IDLE_S;
end
else begin
    case(state)
    IDLE_S:begin
        if(!in_eos_time_slot_flag)begin
            if(50 == i_clk_cnt)begin
                bufm_id<=bufm_id+8'd1;
          //      len<=len+12'd16;                
        	    in_eos_md<={3'd3,12'd0,1'b1,bufm_id};
                in_eos_md_wr<=1'b1;
                state<=FIRST_S;
                end
            else begin
                in_eos_md<=24'd0;    
                in_eos_md_wr<=1'b0; 
                state<=IDLE_S;             
            end
         end
        else if(in_eos_time_slot_flag)begin
                if(50 == i_clk_cnt)begin 
        //            len<=len+12'd16;  
                    bufm_id<=bufm_id+8'd1;        
                    in_eos_md<={3'd3,12'd0,1'b1,bufm_id};      
                    in_eos_md_wr<=1'b1;                
                    state<=FIRST_S;                    
                    end                                
                else begin                             
                    in_eos_md<=24'd0;                  
                    in_eos_md_wr<=1'b0;                
                    state<=IDLE_S;                     
                end
        end                                    
        else begin                            
                   in_eos_md<=24'd0;                  
                   in_eos_md_wr<=1'b0;                
                   state<=FIRST_S;                     
                end                                       
        end
        
	FIRST_S:begin
               if(50 == i_clk_cnt)begin
                  len<=len+12'd80;      //报文长度每次增加5拍
                  bufm_id<=bufm_id+8'd1;         
                  in_eos_md<={3'd2,len,1'b0,bufm_id};      
                   in_eos_md_wr<=1'b1;                
                   state<=SECOND_S;                    
                   end                                
               else begin                             
                   in_eos_md<=24'd0;                  
                   in_eos_md_wr<=1'b0;                
                   state<=FIRST_S;                     
               end                                                                      
           end
	SECOND_S:begin
            if(50 == i_clk_cnt)begin
               bufm_id<=bufm_id+8'd1; 
    //           len<=len+12'd16;          
               in_eos_md<={3'd0,12'd0,1'b1,bufm_id};    
                in_eos_md_wr<=1'b1;                
                state<=THIRD_S;                   
                end                                
            else begin                             
                in_eos_md<=24'd0;                  
                in_eos_md_wr<=1'b0;                
                state<=SECOND_S;                    
            end                                                                     
          end
 	THIRD_S:begin
            if(50 == i_clk_cnt)begin
         //       len<=len+12'd16;  
                bufm_id<=bufm_id+8'd1;     
                in_eos_md<={3'd1,len,1'b1,bufm_id};
                in_eos_md_wr<=1'b1;            
                state<=FOUR_S;                
                end                            
            else begin                         
                in_eos_md<=24'd0;              
                in_eos_md_wr<=1'b0;            
                state<=THIRD_S;               
            end                                
      end
 	FOUR_S:begin                   
 	               if(50 == i_clk_cnt)begin 
 	                   len<=len+12'd80;  
 	                   bufm_id<=bufm_id+8'd1;      
 	                   in_eos_md<={3'd2,len,1'b1,bufm_id};  
 	                   in_eos_md_wr<=1'b1;              
 	                   state<=FIVE_S;                   
 	                   end                              
 	               else begin                           
 	                   in_eos_md<=24'd0;                
 	                   in_eos_md_wr<=1'b0;              
 	                   state<=FOUR_S;                  
 	               end                                  
 	         end                                        
    FIVE_S:begin                  
	             if(50 == i_clk_cnt)begin 
	       //          len<=len+12'd16;     
	                 bufm_id<=bufm_id+8'd1;  
	                 in_eos_md<={3'd0,12'd0,1'b1,bufm_id}; 
	                 in_eos_md_wr<=1'b1;             
	                 state<=SIX_S;                  
	                 end                             
	             else begin                          
	                 in_eos_md<=24'd0;               
	                 in_eos_md_wr<=1'b0;             
	                 state<=FIVE_S;                  
	             end                                 
	       end                                       
    SIX_S:begin                     
             if(50 == i_clk_cnt)begin 
                 len<=len+12'd80;     
                 bufm_id<=bufm_id+8'd1;  
                 in_eos_md<={3'd2,len,1'b1,bufm_id}; 
                 in_eos_md_wr<=1'b1;             
                 state<=SEVEN_S;                  
                 end                             
             else begin                          
                 in_eos_md<=24'd0;               
                 in_eos_md_wr<=1'b0;             
                 state<=SIX_S;                  
             end                                 
       end                                       
    SEVEN_S:begin                      
             if(50 == i_clk_cnt)begin 
      //           len<=len+12'd16;     
                 bufm_id<=bufm_id+8'd1;  
                 in_eos_md<={3'd1,len,1'b0,bufm_id}; 
                 in_eos_md_wr<=1'b1;             
                 state<=IDLE_S;                  
                 end                             
             else begin                          
                 in_eos_md<=24'd0;               
                 in_eos_md_wr<=1'b0;             
                 state<=SEVEN_S;                  
             end                                 
       end                                                         
    default:begin
	     in_eos_md<=24'b0;  
         in_eos_md_wr<=1'b0;
         state<=IDLE_S;
         end
endcase	
end    
end   

//控制in_eos_pkt_valid,md输出后过55个clock置1
localparam o_pkt_len=12'd800;
reg [11:0]o_clk_cnt; 
reg [3:0]pkt_state;
localparam PKT_IDLE_S=4'd0,
            PKT_FIRST_S=4'd1;
always@(posedge clk or negedge rst_n)begin
if(!rst_n)begin
	o_clk_cnt <= 12'd0;
    in_eos_pkt_valid <= 1'b0;
    pkt_state <= PKT_IDLE_S;
end
else begin
    case(pkt_state)
    PKT_IDLE_S:begin
       in_eos_pkt_valid <= 1'b0;
       o_clk_cnt <= 12'd0;
       if(out_eos_md_wr==1'b1)begin
           pkt_state <= PKT_FIRST_S;
       end
       else begin
          pkt_state <= PKT_IDLE_S;
       end 
   end
   PKT_FIRST_S:begin
       if(((o_pkt_len>>4)+12'd5) == o_clk_cnt)begin
           o_clk_cnt <= 12'd0;
           in_eos_pkt_valid <= 1'b1;
           pkt_state <= PKT_IDLE_S;
       end
       else begin
           o_clk_cnt <= o_clk_cnt + 12'b1;
           in_eos_pkt_valid <= 1'b0;
           pkt_state <= PKT_FIRST_S;
       end
end
endcase
end
end



reg [11:0]pktout_clk_cnt; 
always@(posedge clk or negedge rst_n)begin
if(!rst_n)begin
	pktout_clk_cnt <= 12'd0;
end
else begin
    if(pktout_clk_cnt >= 12'd800)begin
        pktout_clk_cnt <= 12'd0;
        pktout_usedw_0 <= 8'd0;
        pktout_usedw_1 <= 8'd0;
    end
    else begin
        pktout_usedw_0 <= 8'd0;
        pktout_usedw_1 <= 8'd50;
        pktout_clk_cnt <= pktout_clk_cnt + 12'd1;
   end
end
end

design_1_wrapper design_1_wrapper_inst                                  
         (.clk(clk),                                      
          .in_eos_md(in_eos_md),                          
          .in_eos_md_wr(in_eos_md_wr),                    
          .in_eos_pkt_valid(in_eos_pkt_valid),            
          .in_eos_rate_limit(in_eos_rate_limit),                   
          .in_eos_time_slot_flag(in_eos_time_slot_flag),  
          .out_eos_md(out_eos_md),                    
          .out_eos_md_wr(out_eos_md_wr),              
          .out_eos_mdin_cnt(out_eos_mdin_cnt),        
          .out_eos_mdout_cnt(out_eos_mdout_cnt),      
          .out_eos_q0_used_cnt(out_eos_q0_used_cnt),  
          .out_eos_q1_used_cnt(out_eos_q1_used_cnt),  
          .out_eos_q2_used_cnt(out_eos_q2_used_cnt),  
          .out_eos_q3_used_cnt(out_eos_q3_used_cnt),          
          .pktout_usedw_0(pktout_usedw_0),                
          .pktout_usedw_1(pktout_usedw_1),                
          .rst_n(rst_n)
          );                                     
endmodule


/*
//控制报文长度和bufm_id;
always@(negedge i_eos_clock or posedge rst_n)begin
if(!rst_n)begin
	len <= 12'd64+12'd32;
	bufm_id <= 8'd0;
end
else begin
    if(len>=12'd1518)begin
       len <= 12'd64+12'd32;
    end
    else begin
       len <= len+12'd16;
    end
    
    if(bufm_id>=16)begin
       bufm_id <= 8'd0;
    end
    else begin
       bufm_id <= bufm_id+8'd1;
    end    
end
end
*/


/* 
reg [3:0]state;
parameter IDLE_S=4'd0,
            FIRST_S=4'd1,
            SECOND_S=4'd2,
            THIRD_S=4'd3,
		    FOUR_S=4'd4,
		    FIVE_S=4'd5,
		    SIX_S=4'd6,
		    SEVEN_S=4'd7;
always@(posedge i_eos_clock or negedge rst_n)begin
if(!rst_n)begin
	in_eos_md<=24'b0;
	in_eos_md_wr<=1'b0;
	state<=IDLE_S;
end
else begin
    case(state)
    IDLE_S:begin
        if(!in_eos_time_slot_flag && !q0fifo_full)begin
        	in_eos_md<={3'd3,len,1'b0,8'd0};
//            in_eos_md_wr<=1'b1;
            end
        else if(in_eos_time_slot_flag && !q1fifo_full)begin
            in_eos_md<={3'd3,len,1'b0,8'd0};
 //           in_eos_md_wr<=1'b1;
            end
        else begin
            in_eos_md<=24'b0;
//            in_eos_md_wr<=1'b0;
            end
            state<=FIRST_S;
        end
        
	FIRST_S:begin
	    if(!q2fifo_full)begin
           in_eos_md<={3'd2,len,1'b0,8'd1}; 
 //          in_eos_md_wr<=1'b1;
           end
         else begin
           in_eos_md<=24'b0;  
//           in_eos_md_wr<=1'b0;
         end
         state<=SECOND_S;            
    end
	SECOND_S:begin
	    if(!q3fifo_full)begin
          in_eos_md<={3'd0,len,1'b0,8'd2};      
 //         in_eos_md_wr<=1'b1;
          end
         else begin
            in_eos_md<=24'b0;  
//            in_eos_md_wr<=1'b0;
          end
          state<=THIRD_S;      
        end
 	THIRD_S:begin
	   if(!q2fifo_full)begin
            in_eos_md<={3'd1,len,1'b0,8'd3};      
//            in_eos_md_wr<=1'b1;
      end
      else begin
            in_eos_md<=24'b0;  
 //           in_eos_md_wr<=1'b0;
       end
            state<=FOUR_S;      
     end
 	FOUR_S:begin
	   if(!q2fifo_full)begin
          in_eos_md<={3'd2,len,1'b1,8'd4};      
//          in_eos_md_wr<=1'b1;
       end
       else begin
             in_eos_md<=24'b0;  
//             in_eos_md_wr<=1'b0;
        end
             state<=FIVE_S;      
        end
    FIVE_S:begin
	   if(!q3fifo_full)begin
           in_eos_md<={3'd0,len,1'b0,8'd5};      
//           in_eos_md_wr<=1'b1;
       end
       else begin
          in_eos_md<=24'b0;  
//          in_eos_md_wr<=1'b0;
       end
          state<=IDLE_S;      
     end
    default:begin
	     in_eos_md<=24'b0;  
//         in_eos_md_wr<=1'b0;
         state<=IDLE_S;
         end
endcase	
end    
end  
*/

/*
//控制pktout_usedw_N
reg [11:0]pktout_clk_cnt;
always@(posedge clk or negedge rst_n)begin
if(!rst_n)begin
	pktout_clk_cnt <= 12'h0;
end
else begin
    if(pktout_usedw_0!=8'd0)begin
        if(pktout_clk_cnt>=15)begin
           pktout_clk_cnt <= 12'b0;
           if(out_eos_md_wr==1'b1 && out_eos_md[8]==1'b0)begin          
              pktout_usedw_0 <= pktout_usedw_0+out_eos_md[20:9]-12'd32 - 8'd1;        
           end                                                          
           else begin                               
              pktout_usedw_0 <= pktout_usedw_0 - 8'd1;               
           end 
         end                                                                                                              
        else begin
           pktout_clk_cnt <= pktout_clk_cnt + 12'b1;
           if(out_eos_md_wr==1'b1 && out_eos_md[8]==1'b0)begin                               
              pktout_usedw_0 <= pktout_usedw_0+out_eos_md[20:9]-12'd32 + 8'd1;         
           end                                                                               
           else begin                                                                        
              pktout_usedw_0 <= pktout_usedw_0;                                       
           end                                                                               
        end
    end
    else begin//(pktout_usedw_0==8'd0)begin
        pktout_clk_cnt <= 12'b0;
        if(out_eos_md_wr==1'b1 && out_eos_md[8]==1'b0)begin          
            pktout_usedw_0 <= out_eos_md[20:9]-12'd32 + 8'd1;        
        end
        else begin
           pktout_usedw_0 <= 8'd0; 
        end 
    end
end
end
*/