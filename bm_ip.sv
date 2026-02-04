`default_nettype none
//mwindex valries 0 to NSFULL. key to whole design.

import axi_if_pkg::*;

module master_if_bm_ip #(
    parameter NIC_ARADDR_WD = NIC_AWADDR_WD,
    parameter PARAM_LINGER  = 0,
    parameter [1:0] INTERCONNECT_ERROR = 2'b11
)(
    input  wire S_AXI_ACLK,
    input  wire S_AXI_ARESETN,
    AXI4_if.S_AXI_N2M_IF S_AXI,
    AXI4_if m_stall,

    input  wire logic write_qos_lockout,
    input  wire logic read_qos_lockout,

    input  wire logic [NS-1:0]     slv_wr_grant_i,
    input  wire logic [NS-1:0]     slv_rd_grant_i,
    input  wire logic [NSFULL-1:0] wr_priority_bank,
    input  wire logic [NSFULL-1:0] rd_priority_bank,

    output wire logic [NSFULL-1:0] wrequest_o,
    output wire logic [NSFULL-1:0] rrequest_o,

    //definitely w request is in central area
    input  wire logic [NSFULL-1:0]       m_axi_bvalid_allslv_i,
    input  wire logic [NSFULL-1:0]       m_axi_bid_allslv_i [NIC_ID_WIDTH-1:0],
    input  wire logic [1:0][NSFULL-1:0]  m_axi_bresp_allslv_i,

    input  wire logic [NSFULL-1:0] m_axi_rvalid_allslv_i,
    //{
    //input wire logic                  m_axi_rlast,
    //input wire logic [NIC_ID_WIDTH-1:0] m_axi_rid,
    //input wire logic [NIC_W_WD-1:0]   m_axi_rdata,

    input  wire logic [NSFULL-1:0] slave_awready,
    input  wire logic [NSFULL-1:0] slave_wready,
    input  wire logic [NSFULL-1:0] slave_arready,

    output wire logic slave_waccepts_o,
    output wire logic slave_awaccepts_o,
    output wire logic slave_raccepts_o,

    output wire [NS:0] wdecode_o,
    output wire [NS:0] rdecode_o,

    output wire logic mwempty,
    output wire logic mrempty,

    output wire logic [NS:0] wgrant,
    output wire logic [NS:0] rgrant,

    output wire logic mwgrant,
    output wire logic mrgrant,

    output wire logic [LGNS-1:0] mwindex_o,
    output wire logic [LGNS-1:0] mrindex_o,

    output wire logic bresp_stall_rdy_o,
    output wire logic rd_stall_rdy_o,

    output wire logic dcd_awalid_o,
    output wire logic dcd_arvalid_o,
    //generally not used.
    output wire logic slave_araccepts_o,
    output wire logic w_mrpending
);

localparam [0:0] PARAM_STALL_IP         = 0;
localparam [0:0] PARAM_ALWAYS           = -1;
localparam [0:0] PARAM_DECODER_REGSLICE = 1;

/////////////////////////////////////////control signals/////////////////////////////////////////

reg  slave_awaccepts, slave_waccepts;
wire dcd_awvalid;
reg  slave_araccepts, slave_raccepts;
reg  dcd_arvalid;
wire logic m_arvalid,m_rvalid,m_rlast;
wire logic m_awvalid,m_wvalid,m_wlast;
wire logic [NIC_ID_WIDTH-1:0] m_awid,m_arid;
reg  rd_stall_valid,rd_stall_rdy;
reg  bresp_stall_valid, bresp_stall_rdy_s;

wire logic [NS:0] wdecode;
reg  [NSFULL-1:0] rrequest_s;
wire logic [NS:0] rdecode;
//reg  [NSFULL-1:0] rrequest_s;

reg  [NSFULL-1:0] wrequest_s;
reg  [NS:0]       wgrant_s,rgrant_s;
reg  mwgrant_s,mrgrant_s;

reg  wr_rqst_chnl_avlbl;
reg  rd_rqst_chnl_avlbl;

wire wlasts_pending;
reg  r_awvalid;
reg  r_arvalid;
reg  rskd_rlast;
reg  m_arlen;

reg  rerr_outstanding;
reg  rerr_last;
reg  rerr_none;
reg  [LGOUTSTANDING-1:0] rpending;
//reg  rpending;
//reg  mrempty_s;
//reg  rd_outstanding_maxed;
reg  [NIC_W_WD-1:0]      i_axi_rdata;
reg  [NIC_ID_WIDTH-1:0]  i_axi_rid;
reg  [2-1:0]             i_axi_rresp;

wire [NIC_ID_WIDTH-1:0] skd_awid;


reg m_arlen;
reg [LGOUTSTANDING-1:0] rpending;
//reg    rpending;
//reg    mrempty_s;
//reg    rd_outstanding_maxed;
reg [NIC_W_WD-1:0]     i_axi_rdata;
reg [NIC_ID_WIDTH-1:0] i_axi_rid;
reg [2-1:0]            i_axi_rresp;

////////////////////////////////////////////////////////////////////////////////////////////////////

wire [NIC_ID_WIDTH-1:0]   skd_awid;
wire [NIC_AWADDR_WD-1:0]  skd_awaddr;
wire [8-1:0]              skd_awlen;
wire [3-1:0]              skd_awsize;
wire [2-1:0]              skd_awburst;
wire                       skd_awlock;
wire [4-1:0]              skd_awcache;
wire [3-1:0]              skd_awprot;
wire [4-1:0]              skd_awqos;
//
wire [NIC_ID_WIDTH-1:0]   skd_arid;
wire [NIC_AWADDR_WD-1:0]  skd_araddr;
wire [8-1:0]              skd_arlen;
wire [3-1:0]              skd_arsize;
wire [2-1:0]              skd_arburst;
wire                       skd_arlock;
wire [4-1:0]              skd_arcache;
wire [3-1:0]              skd_arprot;
wire [4-1:0]              skd_arqos;

reg berr_valid;
reg berr_id;
wire wdata_expected;
AXI_IF_internal stall_AXI_op;

reg                    r_stay_on_channel;
reg                    r_leave_channel;
reg [LGNS-1:0]          r_requested_index, r_mrindex;
wire logic              r_linger;

reg                    wr_stay_on_channel;
reg                    wr_leave_channel;
reg [LGNS-1:0]          wr_requested_index, r_mwindex;
wire logic              wr_linger;

wire logic [LGNS-1:0]   mwindex;
wire logic [LGNS-1:0]   mrindex;

reg [LGOUTSTANDING-1:0] wr_outstanding, wpending;
reg                    r_wdata_expected;
reg                    mwempty_s, mrempty_s;
reg                    wr_outstanding_maxed, rd_outstanding_maxed;

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Count outstanding transactions
// wpending is a count of all of the AW* packets that have
// been forwarded to the slave, but for which the slave has
// yet to return a B* response.  This number can be as large
// as (1<<LGOUTSTANDING)-1.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

generate
begin : W7_PENDING_WRITE_COUNT

    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
    begin
        wr_outstanding       <= 0;
        mwempty_s            <= 1;
        wr_outstanding_maxed <= 0;
    end else
    begin

        case ({(m_awvalid && slave_awaccepts),
               (bresp_stall_valid && bresp_stall_rdy_s)})
            2'b01: begin
                wr_outstanding       <= wr_outstanding - 1;
                mwempty_s            <= (wr_outstanding <= 1);
                wr_outstanding_maxed <= 0;
            end
            2'b10: begin
                wr_outstanding       <= wr_outstanding + 1;
                mwempty_s            <= 0;
                wr_outstanding_maxed <= &wr_outstanding[LGOUTSTANDING-1:1];
            end
            default: begin end
        endcase
    end

    // Addition: wpending.  wpending counts the number of write
    // bursts that are pending, based upon the write channel.
    // Bursts are counted from AWVALID & AWREADY, and decremented
    // once we see the WVALID & WREADY signal.  Packets should
    // not be accepted without a prior (or concurrent)

    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
    begin
        r_wdata_expected <= 0;
        wpending         <= 0;
    end else case ({(m_awvalid && slave_awaccepts),
                    (m_wvalid && slave_waccepts && m_wlast)})
        2'b01: begin
            r_wdata_expected <= (wpending > 1);
            wpending         <= wpending - 1;
        end

        2'b10: begin
            wpending         <= wpending + 1;
            r_wdata_expected <= 1;
        end

        default: begin end
    endcase

    assign wdata_expected  = r_wdata_expected;

    assign wlasts_pending  = wpending;
    assign mwempty         = mwempty_s;
end
endgenerate

// this is where the grant, index is registered to point to latest incoming be
// wrequest holds latest value already
integer islv;

generate
begin: W0_GRANT_REGISTERING
    always @(posedge S_AXI_ACLK)
    begin : WRITE_GRANT
        if (!S_AXI_ARESETN)
        begin
            wgrant_s  <= 0;
            mwgrant_s <= 0;
        end else if (!wr_stay_on_channel)
        begin
            if (wr_rqst_chnl_avlbl)
            begin
                // Switch to a new channel
                mwgrant_s <= 1'b1;
                wgrant_s  <= wrequest_s[NS:0];
            end else if (wr_leave_channel)
            begin
                // Revoke the given grant
                mwgrant_s <= 1'b0;
                wgrant_s  <= 0;
            end
        end
    end

always_comb
begin
    wr_requested_index = 0;

    for(islv=0; islv<=NS; islv=islv+1)
        if (wrequest_s[islv])
            wr_requested_index= wr_requested_index | islv[LGNS-1:0];
end

always @(posedge S_AXI_ACLK)
begin
    //tbd
    if (!wr_stay_on_channel && wr_rqst_chnl_avlbl)
        r_mwindex <= wr_requested_index;
end
assign mwindex_o = r_mwindex;
assign mwindex   = r_mwindex;
assign mwgrant   = mwgrant_s;
assign wgrant    = wgrant_s;

end
endgenerate

generate
begin : W1_SLAVE_AWACCEPTS_WACCEPTS
    always_comb
    begin
        slave_awaccepts = 1'b1;

        //accept/forward a packet without a bus grant
        // This handles whether or not write data is still
        // pending.

        if ((!mwgrant_s) || (write_qos_lockout) || (wr_outstanding_maxed))
            slave_awaccepts = 1'b0;
        //No packet-acceptance unless its to the same slave - the grant is issued for
        if (!wrequest_s[mwindex])
            slave_awaccepts = 1'b0;

        if ((!wgrant_s[NS]) && (!slave_awready[mwindex]))
        begin
            slave_awaccepts = 1'b0;


generate
begin : W1_SLAVE_AWACCEPTS_WACCEPTS
    always_comb
    begin
        slave_awaccepts = 1'b1;

        //accept/forward a packet without a bus grant
        // This handles whether or not write data is still
        // pending.

        if ((!mwgrant_s) || (write_qos_lockout) || (wr_outstanding_maxed))
            slave_awaccepts = 1'b0;

        //No packet-acceptance unless its to the same slave - the grant is issued for indicated from the ...
        if (!wrequest_s[mwindex])
            slave_awaccepts = 1'b0;

        if ((!wgrant_s[NS]) && (!slave_awready[mwindex]))
        begin
            slave_awaccepts = 1'b0;
        end
        else if ((wgrant_s[NS]) && (berr_valid && !bresp_stall_rdy_s))
        begin
            // no accept - write address channel request - no-address-mapped channel
            // when B* channel is stalled , the ID of the transaction may get lost
            // !berr_valid[N] => we have to accept more
            // write data before we can issue BVALID
            slave_awaccepts = 1'b0;
        end
    end

    always_comb
    begin
        slave_waccepts = 1'b1;

        if ((!mwgrant_s) || (wdata_expected && (!slave_awaccepts)))
            slave_waccepts = 1'b0;

        if ((!wgrant_s[NS]) && (!slave_wready[mwindex]))
        begin
            slave_waccepts = 1'b0;
        end
        else if ((wgrant_s[NS]) && (berr_valid && !bresp_stall_rdy_s))
            slave_waccepts = 1'b0;
    end

    always_comb
    begin
        r_awvalid  = dcd_awvalid && !wr_outstanding_maxed;
        wrequest_s = 0;

        if (!wr_outstanding_maxed)
            wrequest_s[NS:0] = wdecode;
    end

    assign wrequest_o = wrequest_s;
end
endgenerate



generate
begin : W6_WRITE_RESP_CHNL
    reg [1:0]              i_axi_bresp;
    reg [NIC_ID_WIDTH-1:0] i_axi_bid;

    // Write error (no slave selected) state machine
    always @(posedge S_AXI_ACLK)
        if (!S_AXI_ARESETN)
            berr_valid <= 0;
        else if (wgrant_s[NS] && m_wvalid && m_wlast
                 && slave_waccepts)
            berr_valid <= 1;
        else if (bresp_stall_rdy_s)
            berr_valid <= 0;

    always_comb
        if (berr_valid)
            bresp_stall_valid = 1;
        else
            bresp_stall_valid = mwgrant_s && m_axi_bvalid_allslv_i[mwindex];

    always @(posedge S_AXI_ACLK)
        if (m_awvalid && slave_awaccepts)
            berr_id <= m_awid;

    always_comb
        if (wgrant_s[NS])
        begin
            i_axi_bid   = berr_id;
            i_axi_bresp = INTERCONNECT_ERROR;
        end
        else
        begin
            i_axi_bid   = m_axi_bid_allslv_i[mwindex];
            i_axi_bresp = m_axi_bresp_allslv_i[mwindex];
        end

    stallbuffer #(
        .DW(NIC_ID_WIDTH+2),
        .PARAM_REGOUT(1)
    ) stall_bresp (
        .i_clk       (S_AXI_ACLK),
        .i_reset     (!S_AXI_ARESETN),
        .in_valid_i  (bresp_stall_valid),
        .in_rdy_o    (bresp_stall_rdy_s),
        .data_in     ({i_axi_bid, i_axi_bresp}),
        .out_valid_o (S_AXI_BVALID),
        .out_rdy_i   (S_AXI_BREADY),
        .data_out    ({S_AXI_BID, S_AXI_BRESP})
    );

    assign bresp_stall_rdy_o = bresp_stall_rdy_s;
end
endgenerate


generate
if (PARAM_LINGER == 0)
begin : NO_LINGER
    assign wr_linger = 0;
end
endgenerate
// wrequest_s , wrequest[N], m_axi_bvalid equivalent in ordering


generate
begin : W3_ARBITRATION_CONTROLS

    always_comb
    begin : STAY_ON_CHANNEL
        wr_stay_on_channel = |(wrequest_s[NS:0] & wgrant_s);
        if (write_qos_lockout)
            wr_stay_on_channel = 0;

        // We must stay on this channel until we've received
        // our last acknowledgment signal. only then can we
        // switch grants
        if (mwgrant_s && !mwempty_s)
            wr_stay_on_channel = 1;

        // if berr_valid is true, we have a grant to the
        // internal slave error channel. While this grant
        // exists, we cannot issue any others.
        if (berr_valid)
            wr_stay_on_channel = 1;
    end

    always_comb
    begin : ARBITRATION_CONTROL
        // The channel is available to us if 1) we want it,
        // 2) no one else is using it, and 3) no one earlier
        // has requested it
        wr_rqst_chnl_avlbl =
            |(wrequest_s[NS-1:0] & ~slv_wr_grant_i
              & ~wr_priority_bank[NS-1:0]);

        // Of course, the error pseudo-channel is *always*
        // available to us.
        if (wrequest_s[NS])
            wr_rqst_chnl_avlbl = 1;

        // Likewise, if we are the only master, then the
        // channel is always available on any request
        if (NM < 2)
            wr_rqst_chnl_avlbl = m_awvalid;
    end

    always_comb
    begin : DCSN_LEAVE_CHANNEL
        wr_leave_channel = 0;
        if (!m_awvalid)
        // Leave the channel when awvalid drops (through stall buffer) - cmplete work
        // second condition may be there in future tbd
            wr_leave_channel = 1;

        if (m_awvalid && !wrequest_s[mwindex])
            wr_leave_channel = 1;
        // master is switching the slave.

        if (write_qos_lockout)
        // Need to leave this channel for another higher
        // priority request
            wr_leave_channel = 1;
    end

    //wr stay on channel has higher priority than wr leave channel - and stay on channel mus...
    // mwindex (registered) <- can we make edge triggered by wrequest

end
endgenerate

//////////////////////////////
assign m_awvalid = r_awvalid;

generate
begin : AW_CHANNEL



// wrequest_s , wrequest[N], m_axi_bvalid equivalent in ordering
endgenerate

/////////////////////////////////////
assign m_awvalid = r_awvalid;

generate
begin : AW_CHANNEL

    stallbuffer #(
        .DW(NIC_ID_WIDTH+NIC_AWADDR_WD+AXI_AWLEN_WD+AXI_AWSIZE_WD+AXI_AWBURST_WD+AXI_AWLOCK_WD+AXI_AWCACHE_WD+AXI_AWPROT_WD+AXI_AWQOS_WD),
        .PARAM_REGOUT(PARAM_STALL_IP)
    ) awstall(
        .i_clk(S_AXI_ACLK),
        .i_reset(!S_AXI_ARESETN),
        .in_valid_i(S_AXI.AWVALID),
        .in_rdy_o(S_AXI.AWREADY),

        .data_in({
            S_AXI.AWID,   S_AXI.AWADDR,
            S_AXI.AWLEN,  S_AXI.AWSIZE,
            S_AXI.AWBURST,S_AXI.AWLOCK,
            S_AXI.AWCACHE,S_AXI.AWPROT,
            S_AXI.AWQOS
        }),

        .out_valid_o(stall_AXI_op.AWVALID),
        .out_rdy_i(!stall_AXI_op.AWSTALL),

        .data_out({
            stall_AXI_op.AWID,    stall_AXI_op.AWADDR, stall_AXI_op.AWLEN,
            stall_AXI_op.AWSIZE,  stall_AXI_op.AWBURST,stall_AXI_op.AWLOCK,
            stall_AXI_op.AWCACHE, stall_AXI_op.AWPROT, stall_AXI_op.AWQOS
        })
    );

    // Primarily internal secondarily output

    addr_decoder #(
        .AW(NIC_AWADDR_WD),
        .DW(NIC_ID_WIDTH+8+3+2+1+4+3+4),
        .NS(NS),
        //.SLAVE_ADDR(SLAVE_ADDR),
        //.SLAVE_MASK(SLAVE_MASK),
        .PARAM_REGISTERED(PARAM_DECODER_REGSLICE)
    ) wraddr_decode(
        .clk_in(S_AXI_ACLK),
        .rst_in(!S_AXI_ARESETN),
        .data_valid_i(stall_AXI_op.AWVALID),
        .data_stall_o(stall_AXI_op.AWSTALL),
        .bus_addr(stall_AXI_op.AWADDR),
        .bus_data({
            stall_AXI_op.AWID,
            stall_AXI_op.AWLEN, stall_AXI_op.AWSIZE, stall_AXI_op.AWBURST,
            stall_AXI_op.AWLOCK, stall_AXI_op.AWCACHE, stall_AXI_op.AWPROT,
            stall_AXI_op.AWQOS
        }),

        .data_valid_out(dcd_awvalid),
        .stall_in(!dcd_awvalid || !slave_awaccepts),

        .decode_sel(wdecode),
        .addr_out(m_stall.AWADDR),

        .data_out({
            m_awid, m_stall.AWLEN, m_stall.AWSIZE,
            m_stall.AWBURST, m_stall.AWLOCK, m_stall.AWCACHE,
            m_stall.AWPROT, m_stall.AWQOS
        })
    );

    );

    stallbuffer #(

        .DW(NIC_W_WD+NIC_W_WD/8+1),
        .PARAM_REGOUT(PARAM_STALL_IP || PARAM_DECODER_RESLICE)

    ) wstall(

        .l_clk(S_AXI_ACLK),
        .l_reset(!S_AXI_ARESETN),
        .in_valid_i(S_AXI.WVALID),
        .in_rdy_o(S_AXI.WREADY),
        .data_in({ S_AXI.WDATA, S_AXI.WSTRB, S_AXI.WLAST }),
        .out_valid_o(m_walid),
        .out_rdy_i(slave_waccepts),
        .data_out({ m_stall.WDATA, m_stall.WSTRB, m_wlast})

    );

end
endgenerate



////////////////////internal to outputs////////////////////
assign m_stall.WVALID      = m_walid;
assign m_stall.WLAST       = m_wlast;
assign m_stall.AWID        = m_awid;
assign m_stall.AWVALID     = m_awalid;
assign slave_waccepts_o     = slave_waccepts;
assign slave_awaccepts_o    = slave_awaccepts;
assign wdecode_o            = wdecode;
assign dcd_awvalid_o        = dcd_awvalid;  // tbd doubt
//only op - m_stall
//Primarily output secondarily internal
//m_stall.WLAST, slave_waccepts, m_stall.WVALID
//m_stall.AWID,  slave_awaccepts, dcd_awvalid

////////////////////////////////Read-Channel///////////////////////////////
reg rerr_id;

generate
begin : R7_COUNT_PENDING_READS

    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
    begin
        rpending                 <= 0;
        mrempty_s                <= 1;
        rd_outstanding_maxed     <= 0;
    end else case ({(m_arvalid && slave_raccepts && !rgrant_s[NS]),
                   (rd_stall_valid && rd_stall_rdy
                    && rskd_rlast && !rgrant_s[NS])})

    2'b01: begin
        rpending                 <= rpending - 1;
        mrempty_s                <= (rpending == 1);
        rd_outstanding_maxed     <= 0;
    end

    2'b10: begin
        rpending                 <= rpending + 1;
        rd_outstanding_maxed     <= &rpending[LGOUTSTANDING-1:1];
        mrempty_s                <= 0;
    end

    default: begin end
    endcase

    assign w_mrpending = rpending;

    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
    begin
        rerr_outstanding         <= 0;
        rerr_last                <= 0;
        rerr_none                <= 1;
    end else if (!rerr_none)
    begin
        if (!rd_stall_valid || rd_stall_rdy)
        begin
            rerr_none            <= (rerr_outstanding == 1);
            rerr_last            <= (rerr_outstanding == 2);
            rerr_outstanding     <= rerr_outstanding - 1;
        end
    end else if (m_arvalid && rrequest_s[NS] && slave_raccepts)
    begin
        rerr_none                <= 0;
        rerr_last                <= (m_arlen == 0);
        rerr_outstanding         <= m_arlen + 1;
    end

    // rerr_id is the ARID field of the currently outstanding
    // error.

    always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        rerr_id <= 0;













///////////////////////////////////////////////////////////
// ------------------------------------------------------------
// (Tail end of R7_COUNT_PENDING_READS visible in IMG_3479)
// ------------------------------------------------------------

end else if (m_arvalid && rrequest_s[NS] && slave_raccepts)
begin
    rerr_none        <= 0;
    rerr_last        <= (m_arlen == 0);
    rerr_outstanding <= m_arlen + 1;
end

// rerr_id is the ARID field of the currently outstanding
// error.

always @(posedge S_AXI_ACLK)
if (!S_AXI_ARESETN)
    rerr_id <= 0;
else if (m_arvalid && slave_raccepts)
begin
    if (rrequest_s[NS])
        rerr_id <= m_arid;
    else
        rerr_id <= 0;
end

end
endgenerate


// ------------------------------------------------------------
// Read-Channel
// ------------------------------------------------------------

generate
begin : R0_GRANT_CHANNEL

always @(posedge S_AXI_ACLK)
begin : READ_GRANT
    if (!S_AXI_ARESETN)
    begin
        rgrant_s  <= 0;
        mrgrant_s <= 0;
    end
    else if (!r_stay_on_channel)
    begin
        if (rd_rqst_chnl_avlbl)
        begin
            // Switching channels
            mrgrant_s <= 1'b1;
            rgrant_s  <= rrequest_s[NS:0];
        end
        else if (r_leave_channel)
        begin
            mrgrant_s <= 1'b0;
            rgrant_s  <= 0;
        end
    end
end

always_comb
begin
    r_requested_index = 0;
    for (islv=0; islv<=NS; islv=islv+1)
        if (rrequest_s[islv])
            r_requested_index = r_requested_index | islv[LGNS-1:0];
end

always @(posedge S_AXI_ACLK)
begin
    // tbd
    if (!r_stay_on_channel && rd_rqst_chnl_avlbl)
        r_mrindex <= r_requested_index;
end

assign mrindex   = r_mrindex;
assign mrindex_o = r_mrindex;

end
endgenerate


// ------------------------------------------------------------
// R1_SLAVE_ARACCEPTS (IMG_3482/3483)
// ------------------------------------------------------------

generate
begin : R1_SLAVE_ARACCEPTS

always_comb
begin
    r_arvalid  = dcd_arvalid && !rd_outstanding_maxed;
    rrequest_s = 0;
    if (!rd_outstanding_maxed)
        rrequest_s[NS:0] = rdecode;
end

assign rrequest_o = rrequest_s;
assign m_arvalid  = r_arvalid;

always_comb
begin
    slave_raccepts = 1'b1;

    if ((!mrgrant_s) || (read_qos_lockout) || (rd_outstanding_maxed))
        slave_raccepts = 1'b0;

    // verilator lint_off WIDTH
    if (!rrequest_s[mrindex])
        slave_raccepts = 1'b0;
    // verilator lint_on WIDTH

    if ((!rgrant_s[NS]) && (!slave_arready[mrindex]))
        slave_raccepts = 1'b0;
    else if ((rgrant_s[NS]) && (!mrempty_s || !rerr_none || rd_stall_valid))
        slave_raccepts = 1'b0;
end

assign slave_raccepts_o = slave_raccepts;

end
endgenerate


// ------------------------------------------------------------
// R6_READ_RETURN_CHANNEL_MUX (IMG_3484)
// ------------------------------------------------------------

generate
begin : R6_READ_RETURN_CHANNEL_MUX

// generate the read response
// Here we have two choices.  We can either generate our
// response from the slave itself, or from our internally
// generated (no-slave exists) FSM.

always_comb
    if (rgrant_s[NS])
        rd_stall_valid = !rerr_none;
    else
        rd_stall_valid = mrgrant_s && m_axi_rvalid_allslv_i[mrindex];

always_comb
if (rgrant_s[NS])
begin
    l_axi_rid    = rerr_id;
    l_axi_rdata  = 0;
    rskd_rlast   = rerr_last;
    l_axi_rresp  = INTERCONNECT_ERROR;
end
else begin
    l_axi_rid    = m_stall.RID;
    l_axi_rdata  = m_stall.RDATA;
    rskd_rlast   = m_stall.RLAST;
    l_axi_rresp  = m_stall.RRESP;
end

// mux will be during instantiation.

end
endgenerate


stallbuffer #(
    .DW(NIC_ID_WIDTH+NIC_W_WD+2),
    .PARAM_REGOUT(1)
) rstall_buffer (
    .i_clk      (S_AXI_ACLK),
    .i_reset    (!S_AXI_ARESETN),
    .in_valid_i (rd_stall_valid),
    .in_rdy_o   (rd_stall_rdy),
    .data_in    ({l_axi_rid, l_axi_rdata, rskd_rlast, l_axi_rresp}),
    .out_valid_o(S_AXI.RVALID),
    .out_rdy_i  (S_AXI.RREADY),
    .data_out   ({S_AXI.RID, S_AXI.RDATA, S_AXI.RLAST, S_AXI.RRESP})
);

assign rd_stall_rdy_o = rd_stall_rdy;


// ------------------------------------------------------------
// R3_ARBITRATION_CONTROL (partial — IMG_3486 ends mid-block)
// ------------------------------------------------------------

reg linger;
generate
begin : R3_ARBITRATION_CONTROL

always_comb
begin
    r_leave_channel = 0;

    if (!m_arvalid)
        r_leave_channel = 1;

    // && (!linger || requested[NM][mrindex]) - this condition might be there in future tbd

    if (m_arvalid && !rrequest_s[mrindex])
        // Need to leave this channel to connect
        // to any other channel
        r_leave_channel = 1;

    if (read_qos_lockout)
        r_leave_channel = 1;
end

always_comb
begin
    r_stay_on_channel = |(rrequest_s[NS:0] & rgrant_s);
    if (read_qos_lockout)
        r_stay_on_channel = 0;

// (continues beyond IMG_3486)

begin : R3_ARBITRATION_CONTROL

    always_comb
    begin
        r_stay_on_channel = |(rrequest_s[NS:0] & rgrant_s);
        if (read_qos_lockout)
            r_stay_on_channel = 0;

        // We must stay on this channel until we've received
        // our last acknowledgement signal.  Only then can we
        // switch grants
        if (mrgrant_s && !mrempty_s)
            r_stay_on_channel = 1;

        // if we have a grant to the internal slave-error
        // channel, then we cannot issue a grant to any other
        // while this grant is active
        if (rgrant[NS] && (!rerr_none || rd_stall_valid))
            r_stay_on_channel = 1;
    end

    always_comb
    begin
        // The channel is available to us if 1) we want it,
        // 2) no one else is using it, and 3) no one earlier
        // has requested it
        rd_rqst_chnl_avlbl =
            |(rrequest_s[NS-1:0] & ~slv_rd_grant_i
              & ~rd_priority_bank[NS-1:0]);

        // Of course, the error pseudo-channel is *always*
        // available to us.
        if (rrequest_s[NS])
            rd_rqst_chnl_avlbl = 1;

        // Likewise, if we are the only master, then the
        // channel is always available on any request
        if (NM < 2)
            rd_rqst_chnl_avlbl = m_arvalid;
    end

    if (PARAM_LINGER == 0)
    begin : NO_LINGER
        assign linger = 0;
    end

    // r_leave_channel
    // {{{
    // True of another master is requesting access to this slave,
    // or if we are requesting access to another slave. If QOS
    // lockout is enabled, then we also leave the channel if a
    // request with a higher QOS has arrived

endgenerate

wire logic skd_arvalid, skd_arstall;

generate
begin : READ_RQST_CHANNEL

    stallbuffer #(
        .DW(NIC_ID_WIDTH+NIC_AWADDR_WD+8+3+2+1+4+3+4),
        .PARAM_REGOUT(PARAM_STALL_IP)
    ) stall_ar(
        .i_clk(S_AXI_ACLK), .i_reset(!S_AXI_ARESETN),
        .in_valid_i(S_AXI.ARVALID),
        .in_rdy_o(S_AXI.ARREADY),
        .data_in(
            { S_AXI.ARID,  S_AXI.ARADDR,
              S_AXI.ARLEN, S_AXI.ARSIZE,
              S_AXI.ARBURST, S_AXI.ARLOCK,
              S_AXI.ARCACHE, S_AXI.ARPROT,
              S_AXI.ARQOS }),
        .out_valid_o(skd_arvalid),
        .out_rdy_i(!skd_arstall),
        .data_out(
            { skd_arid, skd_araddr, skd_arlen,
              skd_arsize, skd_arburst, skd_arlock,
              skd_arcache, skd_arprot, skd_arqos })
    );

    addr_decoder #(
        .AW(NIC_ARADDR_WD),
        .DW(NIC_ID_WIDTH+8+3+2+1+4+3+4),
        .NS(NS),
        // .SLAVE_ADDR(SLAVE_ADDR),
        // .SLAVE_MASK(SLAVE_MASK),
        .PARAM_REGISTERED(PARAM_DECODER_REGSLICE)
    ) rdaddr(
        .clk_in(S_AXI_ACLK),
        .rst_in(!S_AXI_ARESETN),
        .data_valid_i(skd_arvalid),
        .data_stall_o(skd_arstall),
        .bus_addr(skd_araddr),
        .bus_data({ skd_arid,
                    skd_arlen, skd_arsize, skd_arburst,
                    skd_arlock, skd_arcache, skd_arprot,
                    skd_arqos }),

        .data_valid_out(dcd_arvalid),

        .stall_in(!m_arvalid || !slave_raccepts),

        .decode_sel(rdecode),
        .addr_out(m_stall.ARADDR),

        .data_out({ m_arid, m_arlen, m_stall.ARSIZE,
                    m_stall.ARBURST, m_stall.ARLOCK, m_stall.ARCACHE,
                    m_stall.ARPROT, m_stall.ARQOS })
    );

end
endgenerate

assign m_stall.ARLEN = m_arlen;

assign rdecode_o      = rdecode;
assign dcd_arvalid_o  = dcd_arvalid;

assign m_stall.ARVALID = m_arvalid;
assign m_stall.ARID    = m_arid;

assign slave_raccepts_o  = slave_raccepts;
assign slave_araccepts_o = slave_araccepts;






endmodule