module um(
input  wire  clk,
input  wire  rst_n,

input  wire [47:0]direct_mac_addr,
input  wire direction,
input  wire [47:0]local_mac_addr,
output  wire [63:0]esw_pktin_cnt,
output  wire [63:0]esw_pktout_cnt,
output  wire [7:0]bufm_ID_cnt,

input  wire  [133:0]pktin_data,
input  wire  pktin_data_wr,
input  wire  pktin_valid,
input  wire  pktin_valid_wr,

output wire  [133:0]pktout_data,
output wire  pktout_data_wr,
output wire  pktout_valid,
output wire  pktout_valid_wr
);

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

assign in_eos_valid_wr = pktout_valid_wr;

esw esw(
.clk(clk),
.rst_n(rst_n),

.in_esw_data(pktin_data),
.in_esw_data_wr(pktin_data_wr),
.in_esw_valid(pktin_valid),
.in_esw_valid_wr(pktin_valid_wr),

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
.local_mac_addr(local_mac_addr),
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

eos eos(
.clk(clk),
.rst_n(rst_n),

.in_eos_tsn_md(out_ibm_md),
.in_eos_tsn_md_wr(out_ibm_md_wr),

.out_eos_tsn_md(out_eos_tsn_md),
.out_eos_tsn_md_wr(out_eos_tsn_md_wr),
.in_eos_valid_wr(in_eos_valid_wr)
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
.out_ebm_valid(pktout_valid),
.out_ebm_valid_wr(pktout_valid_wr),

.in_ebm_md(out_eos_tsn_md),
.in_ebm_md_wr(out_eos_tsn_md_wr)  
);
endmodule