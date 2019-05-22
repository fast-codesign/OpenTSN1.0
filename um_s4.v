module um #(
    parameter    PLATFORM = "Xilinx"
)(
    input clk,
    input [63:0] um_timestamp,
    input rst_n,
    
//cpu or port
    input  pktin_data_wr,
    input  [133:0] pktin_data,
    input  pktin_data_valid,
    input  pktin_data_valid_wr,
    output pktin_ready,//pktin_ready = um2port_alf
    
    output pktout_data_wr,
    output [133:0] pktout_data,
    output pktout_data_valid,
    output pktout_data_valid_wr,
    input pktout_ready,//pktout_ready = port2um_alf    

//control path
    input [133:0] dma2um_data,
    input dma2um_data_wr,
    output um2dma_ready,
    
    output [133:0] um2dma_data,
    output um2dma_data_wr,
    input dma2um_ready,
    
//to match
    output um2me_key_wr,
    output um2me_key_valid,
    output [511:0] um2match_key,
    input um2me_ready,//um2me_ready = ~match2um_key_alful
//from match
    input me2um_id_wr,
    input [15:0] match2um_id,
    output um2match_gme_alful,
//localbus
    input ctrl_valid,  
    input ctrl2um_cs_n,
    output reg um2ctrl_ack_n,
    input ctrl_cmd,//ctrl2um_rd_wr,//0 write 1:read
    input [31:0] ctrl_datain,//ctrl2um_data_in,
    input [31:0] ctrl_addr,//ctrl2um_addr,
    output reg [31:0] ctrl_dataout, //um2ctrl_data_out
    output reg [31:0] um_timer
 
);


wire [133:0] lcm2esw_data;
wire lcm2esw_data_wr;
wire lcm2esw_data_valid;
wire lcm2esw_data_valid_wr;

wire [47:0] direct_mac_addr;
wire direction;
wire [47:0] local_mac_addr;
wire [31:0] token_bucket_para;
wire time_slot_flag;

wire [63:0] esw_pktin_cnt;
wire [63:0] esw_pktout_cnt;
wire [7:0] bufm_ID_cnt;

wire  [133:0]esw2ibm_data;
wire  esw2ibm_data_wr;
wire  esw2ibm_valid;
wire  esw2ibm_valid_wr;
wire  [23:0]tsn_md;
wire  tsn_md_wr;

wire [4:0]ibm2esw_bufm_ID;

wire [133:0]out_ibm_data;
wire out_ibm_data_wr;
wire out_ibm_valid;
wire out_ibm_valid_wr;
wire [7:0]in_ibm_ID;
wire [4:0]in_ibm_ID_count;
wire [23:0]out_ibm_md;
wire out_ibm_md_wr;
   
wire out_data_cache_data_wr;
wire [133:0]out_data_cache_data;
wire out_data_cache_valid_wr;
wire out_data_cache_valid;
wire [7:0]in_data_cache_ID;
wire in_data_cache_ID_wr;

wire [23:0]out_eos_tsn_md;
wire out_eos_tsn_md_wr;

wire in_eos_valid_wr;

assign in_eos_valid_wr = pktout_data_valid_wr;

 lcm lcm_inst(
.clk(clk),
.rst_n(rst_n),
//um signals
.in_lcm_data(pktin_data),
.pktin_data_wr(pktin_data_wr),
.in_lcm_data_valid(pktin_data_valid),
.in_lcm_data_valid_wr(pktin_data_valid_wr),
.pktin_ready(pktin_ready),
.precision_time(),

.in_local_mac_id(48'h01020304),

//esw signals 
.out_lcm_data_wr(lcm2esw_data_wr),
.out_lcm_data(lcm2esw_data),
.out_lcm_data_valid(lcm2esw_data_valid),
.out_lcm_data_valid_wr(lcm2esw_data_valid_wr),

//readable & changeable registers and counters
.out_direction(direction),
.out_token_bucket_para(token_bucket_para),
.out_direct_mac_addr(direct_mac_addr),

//input from esw
.esw_pktin_cnt(),
.esw_pktout_cnt(),
.bufm_id_cnt(),

//input from eos
.eos_q0_used_cnt(),
.eos_q1_used_cnt(),
.eos_q2_used_cnt(),
.eos_q3_used_cnt(),

.time_slot_flag(time_slot_flag),
.eos_mdin_cnt(),
.eos_mdout_cnt(),

//input from goe
.goe_pktin_cnt(),
.goe_port0out_cnt(),
.goe_port1out_cnt(),
.goe_discard_cnt()
);

esw esw(
.clk(clk),
.rst_n(rst_n),

.in_esw_data(lcm2esw_data),
.in_esw_data_wr(lcm2esw_data_wr),
.in_esw_valid(lcm2esw_data_valid),
.in_esw_valid_wr(lcm2esw_data_valid_wr),

.out_esw_data(esw2ibm_data),
.out_esw_data_wr(esw2ibm_data_wr),
.out_esw_valid(esw2ibm_valid),
.out_esw_valid_wr(esw2ibm_valid_wr),
.out_esw_tsn_md(tsn_md),
.out_esw_tsn_md_wr(tsn_md_wr),
.bufm_ID_count(ibm2esw_bufm_ID),

.out_esw2port_data2(),
.out_esw2port_data_wr2(),
.out_esw2port_valid2(),
.out_esw2port_valid_wr2(),

.out_esw2port_data3(),
.out_esw2port_data_wr3(),
.out_esw2port_valid3(),
.out_esw2port_valid_wr3(),

.direction(direction),
.local_mac_addr(48'h01020304),
.direct_mac_addr(direct_mac_addr),
.esw_pktin_cnt(esw_pktin_cnt),
.esw_pktout_cnt(esw_pktout_cnt),
.bufm_ID_cnt(bufm_ID_cnt)
);

ibm ibm_inst(
.clk(clk),
.rst_n(rst_n),

.in_ibm_data(esw2ibm_data),
.in_ibm_data_wr(esw2ibm_data_wr),
.in_ibm_valid(esw2ibm_valid),
.in_ibm_valid_wr(esw2ibm_valid_wr),
.out_ibm_bufm_ID(ibm2esw_bufm_ID),

.in_ibm_tsn_md(tsn_md),
.in_ibm_tsn_md_wr(tsn_md_wr),

.out_ibm_data(out_ibm_data),
.out_ibm_data_wr(out_ibm_data_wr),
.out_ibm_valid(out_ibm_valid),
.out_ibm_valid_wr(out_ibm_valid_wr),

.in_ibm_ID(in_ibm_ID),
.in_ibm_ID_count(in_ibm_ID_count),

.out_ibm_md(out_ibm_md),
.out_ibm_md_wr(out_ibm_md_wr)
);

data_cache data_cache_inst(
.clk(clk),
.rst_n(rst_n),

.in_data_cache_data_wr(out_ibm_data_wr),
.in_data_cache_data(out_ibm_data),
.in_data_cache_valid_wr(out_ibm_valid_wr),
.in_data_cache_valid(out_ibm_valid),
.out_data_cache_ID(in_ibm_ID),
.out_data_cache_ID_count(in_ibm_ID_count),
   
.out_data_cache_data_wr(out_data_cache_data_wr),
.out_data_cache_data(out_data_cache_data),
.out_data_cache_valid_wr(out_data_cache_valid_wr),
.out_data_cache_valid(out_data_cache_valid),
.in_data_cache_ID(in_data_cache_ID),
.in_data_cache_ID_wr(in_data_cache_ID_wr)
);


eos eos_inst(
//clk & rst
.clk(clk),
.rst_n(rst_n),
    
//receive from LCM module
.in_eos_time_slot_flag(time_slot_flag),
.in_eos_rate_limit(32'd16),                   
//transmit to LCM module
.out_eos_q0_used_cnt(),
.out_eos_q1_used_cnt(),
.out_eos_q2_used_cnt(), 
.out_eos_q3_used_cnt(),
.out_eos_mdin_cnt(), 
.out_eos_mdout_cnt(), 

//receive from IBM module
.in_eos_md(out_ibm_md),
.in_eos_md_wr(out_ibm_md_wr),  

//receive from UDO module
.pktout_usedw_0(8'b1),
.pktout_usedw_1(8'b1),           

//receive from EBM module
.in_eos_pkt_valid(in_eos_valid_wr),
//transmit to EBM module
.out_eos_md(out_eos_tsn_md), 
.out_eos_md_wr(out_eos_tsn_md_wr)
);

ebm ebm_inst(
.clk(clk),
.rst_n(rst_n),

.in_ebm_data(out_data_cache_data),
.in_ebm_data_wr(out_data_cache_data_wr),
.in_ebm_valid(out_data_cache_valid),
.in_ebm_valid_wr(out_data_cache_valid_wr),
.out_ebm_ID(in_data_cache_ID),
.out_ebm_ID_wr(in_data_cache_ID_wr),

.out_ebm_data(pktout_data),
.out_ebm_data_wr(pktout_data_wr),
.out_ebm_valid(pktout_data_valid),
.out_ebm_valid_wr(pktout_data_valid_wr),

.in_ebm_md(out_eos_tsn_md),
.in_ebm_md_wr(out_eos_tsn_md_wr)  
);

endmodule