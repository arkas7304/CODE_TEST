import axi_if_pkg::*;

interface AXI4_if;

    // Write slave channels from the controlling AXI masters
    logic                               AWVALID;
    logic                               AWREADY;
    logic [NIC_ID_WIDTH-1:0]            AWID;
    logic [NIC_AWADDR_WD-1:0]           AWADDR;
    logic [8-1:0]                       AWLEN;
    logic [3-1:0]                       AWSIZE;
    logic [2-1:0]                       AWBURST;

    // Verilator coverage_off
    logic                               AWLOCK;
    logic [4-1:0]                       AWCACHE;
    logic [3-1:0]                       AWPROT;
    logic [4-1:0]                       AWQOS;
    // Verilator coverage_on
    //

    logic                               WVALID;
    logic                               WREADY;
    logic [NIC_W_WD-1:0]                WDATA;
    logic [NIC_W_WD/8-1:0]              WSTRB;
    logic                               WLAST;
    //

    logic                               BVALID;
    logic                               BREADY;
    logic [NIC_ID_WIDTH-1:0]            BID;
    logic [2-1:0]                       BRESP;

    // Read slave channels from the controlling AXI masters
    // {{{
    logic                               ARVALID;
    logic                               ARREADY;
    logic [NIC_ID_WIDTH-1:0]            ARID;
    logic [NIC_AWADDR_WD-1:0]           ARADDR;
    logic [8-1:0]                       ARLEN;
    logic [3-1:0]                       ARSIZE;
    logic [2-1:0]                       ARBURST;

    // Verilator coverage_off
    logic                               ARLOCK;
    logic [4-1:0]                       ARCACHE;
    logic [3-1:0]                       ARPROT;
    logic [4-1:0]                       ARQOS;
    // Verilator coverage_on
    //

    logic                               RVALID;
    logic                               RREADY;
    logic [NIC_ID_WIDTH-1:0]            RID;
    logic [NIC_W_WD-1:0]                RDATA;
    logic [2-1:0]                       RRESP;
    logic                               RLAST;

  modport S_AXI_N2M_IF (

    // Write slave channels from the controlling AXI masters
    input  AWVALID,
    output AWREADY,
    input  AWID,
    input  AWADDR,
    input  AWLEN,
    input  AWSIZE,
    input  AWBURST,

    // Verilator coverage_off
    input  AWLOCK,
    input  AWCACHE,
    input  AWPROT,
    input  AWQOS,

    // Verilator coverage_on
    //
    input  WVALID,
    output WREADY,
    input  WDATA,
    input  WSTRB,
    input  WLAST,

    //
    output BVALID,
    input  BREADY,
    output BID,
    output BRESP,

    // }}}
    // Read slave channels from the controlling AXI masters
    // {{{
    input  ARVALID,
    output ARREADY,
    input  ARID,
    input  ARADDR,
    input  ARLEN,
    input  ARSIZE,
    input  ARBURST,

    // Verilator coverage_off
    input  ARLOCK,
    input  ARCACHE,
    input  ARPROT,
    input  ARQOS,

    // Verilator coverage_on
    //
    output RVALID,
    input  RREADY,
    output RID,
    output RDATA,
    output RRESP,
    output RLAST
  );

  modport M_AXI_N2S_IF (

    // Write slave channels from the controlling AXI masters
    output AWVALID,
    input  AWREADY,
    output AWID,
    output AWADDR,
    output AWLEN,
    output AWSIZE,
    output AWBURST,

    // Verilator coverage_off
    output AWLOCK,
    output AWCACHE,
    output AWPROT,
    output AWQOS,

    // Verilator coverage_on
    //
    output WVALID,
    input  WREADY,
    output WDATA,
    output WSTRB,
    output WLAST,

    //
    input  BVALID,
    output BREADY,
    input  BID,
    input  BRESP,

    // }}}
    // Read slave channels from the controlling AXI masters
    // {{{
    output ARVALID,
    input  ARREADY,
    output ARID,
    output ARADDR,
    output ARLEN,
    output ARSIZE,
    output ARBURST,

    // Verilator coverage_off
    output ARLOCK,
    output ARCACHE,
    output ARPROT,
    output ARQOS,

    // Verilator coverage on
    //
    input  RVALID,
    output RREADY,
    input  RID,
    input  RDATA,
    input  RRESP,
    input  RLAST
  );

endinterface
