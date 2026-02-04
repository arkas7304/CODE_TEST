package axi_if_pkg;

parameter NIC_ID_WIDTH  = 4;
parameter NIC_AWADDR_WD = 32;
parameter NIC_W_WD      = 32;

// cuurent limitation s (lin_1)
//Inherit from top level while supplying

parameter AXI_AWLEN_WD   = 8;
parameter AXI_AWSIZE_WD  = 3;
parameter AXI_AWBURST_WD = 2;

parameter AXI_AWLOCK_WD  = 1;

parameter AXI_AWCACHE_WD = 4;
parameter AXI_AWPROT_WD  = 3;
parameter AXI_AWQOS_WD   = 4;
parameter NS = 6;
parameter NM = 5;
parameter LGNS   = (NS>1) ? $clog2(NS+1) : 1;
parameter NSFULL = (NS>1) ? (1<<LGNS) : 2;

// LGOUTSTANDING: Specifies the log based two of the maximum
// {{{
// number of bursts transactions that may be outstanding at any
// given time. This is different from the maximum number of
// outstanding beats.
parameter LGOUTSTANDING = 3;

typedef struct packed {
  logic                      AWVALID;
  logic                      AWREADY;
  logic [NIC_ID_WIDTH-1:0]   AWID;
  logic [NIC_AWADDR_WD-1:0]  AWADDR;
  logic [8-1:0]              AWLEN;
  logic [3-1:0]              AWSIZE;
  logic [2-1:0]              AWBURST;
  // Verilator coverage_off
  logic                      AWLOCK;
  logic [4-1:0]              AWCACHE;
  logic [3-1:0]              AWPROT;
  logic [4-1:0]              AWQOS;

  // Verilator coverage_on
  //
  logic                      WVALID;
  logic                      WREADY;
  logic [NIC_W_WD-1:0]       WDATA;
  logic [NIC_W_WD/8-1:0]     WSTRB;
  logic                      WLAST;
  //
  logic                      BVALID;
  logic                      BREADY;
  logic [NIC_ID_WIDTH-1:0]   BID;
  logic [2-1:0]              BRESP;

  // }}}
  // Read slave channels from the controlling AXI masters
  // {{{
  logic                      ARVALID;
  logic                      ARREADY;
  logic [NIC_ID_WIDTH-1:0]   ARID;
  logic [NIC_AWADDR_WD-1:0]  ARADDR;
  logic [8-1:0]              ARLEN;
  logic [3-1:0]              ARSIZE;
  logic [2-1:0]              ARBURST;
  // Verilator coverage_off
  logic                      ARLOCK;
  logic [4-1:0]              ARCACHE;
  logic [3-1:0]              ARPROT;
  logic [4-1:0]              ARQOS;

  // Verilator coverage_on
  //
  logic                      RVALID;
  logic                      RREADY;
  logic [NIC_ID_WIDTH-1:0]   RID;
  logic [NIC_W_WD-1:0]       RDATA;
  logic [2-1:0]              RRESP;
  logic                      RLAST;

  logic                      AWSTALL;
} AXI_IF_internal;

endpackage
