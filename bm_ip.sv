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





endmodule