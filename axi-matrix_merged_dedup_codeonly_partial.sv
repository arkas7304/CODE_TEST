`default_nettype none

import axi_if_pkg::*;


module axi4_nic_fixed #(
    //`include parameter_decl.sv
)(
    input  wire  S_AXI_ACLK,
    input  wire  S_AXI_ARESETN,
    AXI4_if.S_AXI_N2M_IF  S_AXI [NM-1:0],
    AXI4_if.M_AXI_N2S_IF  M_AXI [NS-1:0]
);





    localparam  LGNM   = (NM>1) ? $clog2(NM)   : 1;
    localparam  LGNS   = (NS>1) ? $clog2(NS+1) : 1;
    localparam  NMFULL = (NM>1) ? (1<<LGNM)    : 1;
    localparam  NSFULL = (NS>1) ? (1<<LGNS)    : 2;

    localparam  [1:0]  INTERCONNECT_ERROR = 2'b11;

    genvar islv, imstr;
    integer i;

    AXI_IF_internal  m_axi      [NSFULL-1:0];
    AXI4_if          bm2slv_if  [NMFULL-1:0]();

    AXI_IF_internal  bm2slv_arr [NMFULL-1:0];



    reg [NSFULL-1:0] slv_awready_s;
    reg [NSFULL-1:0] slv_wready_s;
    reg [NSFULL-1:0] slv_arready_s;


    wire logic bresp_stall_rdy_s [NM-1:0];
    wire logic rd_stall_rdy_s    [NM-1:0];

    wire logic slv_awaccepts [NM-1:0];
    wire logic slv_waccepts  [NM-1:0];
    wire logic slv_raccepts  [NM-1:0];

    wire logic [LGNS-1:0] mw_ptr [0:NMFULL-1];
    wire logic [LGNS-1:0] mr_ptr [0:NMFULL-1];

    wire logic [LGNM-1:0] sw_ptr [0:NSFULL-1];
    wire logic [LGNM-1:0] sr_ptr [0:NSFULL-1];

    wire logic mrempty_s [NM-1:0];
    wire logic mwempty_s [NM-1:0];
    wire logic mrgrant_s [NM-1:0];
    wire logic mwgrant_s [NM-1:0];

    wire logic [NSFULL-1:0]                m_axi_bvalid_allslv_s;
    wire logic [NSFULL-1:0][NIC_ID_WIDTH-1:0] m_axi_bid_allslv_s;
    wire logic [NSFULL-1:0][1:0]           m_axi_bresp_allslv_s;
    wire logic [NSFULL-1:0]                m_axi_rvalid_allslv_s;

    wire logic [NS:0] wgrant_s [0:NM-1];
    wire logic [NS:0] rgrant_s [0:NM-1];

    reg [NS-1:0] swgrant_s;
    reg [NS-1:0] srgrant_s;
    wire logic read_qos_lockout, write_qos_lockout;

    reg [NSFULL-1:0] wrequest     [0:NM-1];
    reg [NSFULL-1:0] rrequest     [0:NM-1];
    reg [NSFULL-1:0] wr_order_arr [0:NM];
    reg [NSFULL-1:0] rd_order_arr [0:NM];

    generate for(imstr=0; imstr<NM; imstr=imstr+1)
    begin : SLV2MSTR_ROUTE
            master_if_bm_ip #(
                            )
            slv2masters_if
            (

            .S_AXI_ACLK        (S_AXI_ACLK),
            .S_AXI_ARESETN     (S_AXI_ARESETN),
            .S_AXI             (S_AXI[imstr]),
            .m_stall           (bm2slv_if[imstr]),
            .write_qos_lockout (1'b0),
            .read_qos_lockout  (1'b0),
            .slv_wr_grant_i    (swgrant_s),
            .slv_rd_grant_i    (srgrant_s),
            .wr_priority_bank  (wr_order_arr[imstr]),
            .rd_priority_bank  (rd_order_arr[imstr]),
            .wrequest_o        (wrequest[imstr]),
            .rrequest_o        (rrequest[imstr]),
            .m_axi_bvalid_allslv_i (m_axi_bvalid_allslv_s),
            .m_axi_bid_allslv_i    (m_axi_bid_allslv_s),
            .m_axi_bresp_allslv_i  (m_axi_bresp_allslv_s),
            .m_axi_rvalid_allslv_i (m_axi_rvalid_allslv_s),
            .slave_awready      (slv_awready_s),
            .slave_wready       (slv_wready_s),
            .slave_arready      (slv_arready_s),

            .slave_waccepts_o   (slv_waccepts[imstr]),
            .slave_awaccepts_o  (slv_awaccepts[imstr]),
            .slave_raccepts_o   (slv_raccepts[imstr]),

            .wdecode_o          (),
            .rdecode_o          (),

            .rdecode_o          (),
            .mwempty            (mwempty_s[imstr]),
            .mrempty            (mrempty_s[imstr]),
            .wgrant             (wgrant_s[imstr]),
            .rgrant             (rgrant_s[imstr]),
            .mwgrant            (mwgrant_s[imstr]),
            .mrgrant            (mrgrant_s[imstr]),
            .mwindex_o          (mw_ptr[imstr]),
            .mrindex_o          (mr_ptr[imstr]),
            .bresp_stall_rdy_o  (bresp_stall_rdy_s[imstr]),
            .rd_stall_rdy_o     (rd_stall_rdy_s[imstr]),
            .dcd_awvalid_o      (),
            .dcd_arvalid_o      ()
    );

    end
    endgenerate

    genvar ik;
    generate for(ik=0; ik<NM; ik=ik+1)

    
generate for(ik=0; ik<NM; ik=ik+1)
begin: ASSIGNMENT_TYPE
		
		// Write slave channels from the controlling AXI masters;
		assign bm2slv_arr[ik].AWVALID = bm2slv_if[ik].AWVALID;
		assign bm2slv_if[ik].AWREADY = bm2slv_arr[ik].AWREADY;
		assign bm2slv_arr[ik].AWID    = bm2slv_if[ik].AWID;
		assign bm2slv_arr[ik].AWADDR  = bm2slv_if[ik].AWADDR;
		assign bm2slv_arr[ik].AWLEN   = bm2slv_if[ik].AWLEN;
		assign bm2slv_arr[ik].AWSIZE  = bm2slv_if[ik].AWSIZE;
		assign bm2slv_arr[ik].AWBURST = bm2slv_if[ik].AWBURST;
		
		// Verilator coverage off;
		assign bm2slv_arr[ik].AWLOCK  = bm2slv_if[ik].AWLOCK;
		assign bm2slv_arr[ik].AWCACHE = bm2slv_if[ik].AWCACHE;
		assign bm2slv_arr[ik].AWPROT  = bm2slv_if[ik].AWPROT;
		assign bm2slv_arr[ik].AWQOS   = bm2slv_if[ik].AWQOS;
		
		// Verilator coverage on;
		//};
		
		assign bm2slv_arr[ik].WALID   = bm2slv_if[ik].WALID;
		assign bm2slv_if[ik].WREADY   = bm2slv_arr[ik].WREADY;
		assign bm2slv_arr[ik].WDATA   = bm2slv_if[ik].WDATA;
		assign bm2slv_arr[ik].WSTRB   = bm2slv_if[ik].WSTRB;
		assign bm2slv_arr[ik].WLAST   = bm2slv_if[ik].WLAST;
		
		assign bm2slv_if[ik].BVALID   = bm2slv_arr[ik].BVALID;
		assign bm2slv_arr[ik].BREADY  = bm2slv_if[ik].BREADY;
		assign bm2slv_if[ik].BID      = bm2slv_arr[ik].BID;
		assign bm2slv_if[ik].BRESP    = bm2slv_arr[ik].BRESP;
		
		// Read slave channels from the controlling AXI masters;
		// {{{;
		assign bm2slv_arr[ik].ARVALID  = bm2slv_if[ik].ARVALID;
		assign bm2slv_if[ik].ARREADY  = bm2slv_arr[ik].ARREADY;
		assign bm2slv_arr[ik].ARID     = bm2slv_if[ik].ARID;
		assign bm2slv_arr[ik].ARADDR   = bm2slv_if[ik].ARADDR;
		assign bm2slv_arr[ik].ARLEN    = bm2slv_if[ik].ARLEN;
		assign bm2slv_arr[ik].ARSIZE   = bm2slv_if[ik].ARSIZE;
		
		assign bm2slv_arr[ik].ARBURST  = bm2slv_if[ik].ARBURST;
		
		// Verilator coverage off;
		assign bm2slv_arr[ik].ARLOCK   = bm2slv_if[ik].ARLOCK;
		assign bm2slv_arr[ik].ARCACHE  = bm2slv_if[ik].ARCACHE;
		assign bm2slv_arr[ik].ARPROT   = bm2slv_if[ik].ARPROT;
		assign bm2slv_arr[ik].ARQOS    = bm2slv_if[ik].ARQOS;
		
		// Verilator coverage on;
		//};
		
		assign bm2slv_if[ik].RVALID    = bm2slv_arr[ik].RVALID;
		assign bm2slv_arr[ik].RREADY   = bm2slv_if[ik].RREADY;
		assign bm2slv_if[ik].RID       = bm2slv_arr[ik].RID;
		assign bm2slv_if[ik].RDATA       = bm2slv_arr[ik].RDATA;
		assign bm2slv_if[ik].RRESP       = bm2slv_arr[ik].RRESP;
		assign bm2slv_if[ik].RLAST       = bm2slv_arr[ik].RLAST;
end
endgenerate
assign  write_qos_lockout = 0;
assign  read_qos_lockout  = 0;

generate for (imstr=NM; imstr<NMFULL; imstr=imstr+1)
begin : UNUSED_MASTER_MATRIX

        assign bm2slv_arr[imstr].AWID     = 0;
        assign bm2slv_arr[imstr].AWADDR   = 0;
        assign bm2slv_arr[imstr].AWLEN    = 0;
        assign bm2slv_arr[imstr].AWSIZE   = 0;
        assign bm2slv_arr[imstr].AWBURST  = 0;
        assign bm2slv_arr[imstr].AWLOCK   = 0;
        assign bm2slv_arr[imstr].AWCACHE  = 0;
        assign bm2slv_arr[imstr].AWPROT   = 0;
        assign bm2slv_arr[imstr].AWQOS    = 0;
        assign bm2slv_arr[imstr].AWVALID  = 0;
        assign bm2slv_arr[imstr].WVALID   = 0;
        assign bm2slv_arr[imstr].WDATA    = 0;
        assign bm2slv_arr[imstr].WSTRB    = 0;
        assign bm2slv_arr[imstr].WLAST    = 0;

        assign bm2slv_arr[imstr].ARVALID  = 0;
        assign bm2slv_arr[imstr].ARID     = 0;
        assign bm2slv_arr[imstr].ARADDR   = 0;
        assign bm2slv_arr[imstr].ARLEN    = 0;
        assign bm2slv_arr[imstr].ARSIZE   = 0;
        assign bm2slv_arr[imstr].ARBURST  = 0;
        assign bm2slv_arr[imstr].ARLOCK   = 0;
        assign bm2slv_arr[imstr].ARCACHE  = 0;
        assign bm2slv_arr[imstr].ARPROT   = 0;
        assign bm2slv_arr[imstr].ARQOS    = 0;

        assign mw_ptr[imstr] = 0;
        assign mr_ptr[imstr] = 0;

end endgenerate


generate for(ik=0; ik<NS; ik=ik+1)
begin: SLAVE_PORT_TRANSFER_2
    // Write slave channels from the controlling AXI masters; tbd
    assign m_axi[ik].AWREADY   =  M_AXI[ik].AWREADY;
    assign m_axi[ik].WREADY   =  M_AXI[ik].WREADY;
    assign m_axi[ik].BVALID   =  M_AXI[ik].BVALID;
    assign m_axi[ik].BID   =  M_AXI[ik].BID;
    assign m_axi[ik].BRESP   =  M_AXI[ik].BRESP;
    assign m_axi[ik].ARREADY   =  M_AXI[ik].ARREADY;
    assign m_axi[ik].RVALID = M_AXI[ik].RVALID;
    assign m_axi[ik].RID    = M_AXI[ik].RID;
    assign m_axi[ik].RDATA  = M_AXI[ik].RDATA;
    assign m_axi[ik].RRESP  = M_AXI[ik].RRESP;
    assign m_axi[ik].RLAST  = M_AXI[ik].RLAST;



end
endgenerate

generate for(islv=0; islv<NS; islv=islv+1)
begin: SLAVE_PORT_TRANSFER

    assign m_axi_bvalid_allslv_s [islv] = M_AXI[islv].BVALID ;
    assign m_axi_bid_allslv_s    [islv] = M_AXI[islv].BID    ;
    assign m_axi_bresp_allslv_s  [islv] = M_AXI[islv].BRESP  ;
    assign m_axi_rvalid_allslv_s [islv] = M_AXI[islv].RVALID ;
end
endgenerate

generate for(islv=NS; islv<NSFULL; islv=islv+1)
begin: UNUSED_SLAVE_MATRIX

    assign m_axi[islv].AWID   = 0;
    assign m_axi[islv].AWLEN  = 0;
    assign m_axi[islv].BID    = 0;
    assign m_axi[islv].RID    = 0;
    assign m_axi[islv].RDATA  = 0;
    assign m_axi[islv].RLAST  = 1;
    assign m_axi[islv].ARID   = 0;
    assign m_axi[islv].ARLEN  = 0;

    assign m_axi[islv].RRESP  = INTERCONNECT_ERROR;
    assign m_axi[islv].BRESP  = INTERCONNECT_ERROR;
    assign sw_ptr[islv]       = 0;
    assign sr_ptr[islv]       = 0;

end
endgenerate

generate
    for (islv = 0; islv < NS; islv = islv + 1) begin : SLV_STATE

        always_comb begin
            // Default all to 1 (assuming logic type, equivalent to -1 for bitwise)
            //slv_awready_s = '1;
            //slv_wready_s  = '1;
            //slv_arready_s = '1;

            // Assign based on M_AXI signals
            slv_awready_s[islv] = ~M_AXI[islv].AWVALID | M_AXI[islv].AWREADY;
            slv_wready_s[islv]  = ~M_AXI[islv].WVALID  | M_AXI[islv].WREADY;
            slv_arready_s[islv] = ~M_AXI[islv].ARVALID | M_AXI[islv].ARREADY;
        end
    end
endgenerate

// [missing lines 218-345]

    generate for (islv = 0; islv < NS; islv = islv + 1)
    begin : BM2SLV_ROUTE_WR
    
        reg sawstall, swstall;
        reg awaccepts;
        reg axi_awvalid;
        reg [NIC_ID_WIDTH-1:0] axi_awid;
        reg [NIC_AWADDR_WD-1:0] axi_awaddr;
        reg [7:0] axi_awlen;
        reg [2:0] axi_awsize;
        reg [1:0] axi_awburst;
        reg axi_awlock;
        reg [3:0] axi_awcache;
        reg [2:0] axi_awprot;
        reg [3:0] axi_awqos;

        reg axi_wvalid;
        reg [NIC_W_WD-1:0] axi_wdata;
        reg [NIC_W_WD/8-1:0] axi_wstrb;
        reg axi_wlast;
        reg axi_bready;
        always_comb
            awaccepts = slv_awaccepts[sw_ptr[islv]];

        always_comb
            sawstall = (M_AXI[islv].AWVALID && !M_AXI[islv].AWREADY);

        always_comb
            swstall = (M_AXI[islv].WVALID && !M_AXI[islv].WREADY);
        
        always @(posedge S_AXI_ACLK)
        begin
            if (!S_AXI_ARESETN || !swgrant_s[islv])
                axi_awvalid <= 0;
            else if (!sawstall)
            begin
                axi_awvalid <= (bm2slv_arr[sw_ptr[islv]].AWVALID && (slv_awaccepts[sw_ptr[islv]]));

            end 
        end

        always @(posedge S_AXI_ACLK)
        begin
            if (!S_AXI_ARESETN || !swgrant_s[islv])
                axi_wvalid <= 0;
            else if (!swstall)
            begin
                axi_wvalid <= (bm2slv_arr[sw_ptr[islv]].WVALID && (slv_waccepts[sw_ptr[islv]]));
            end
        end

        // !OPT_LOWPOWER tbd




        always @(posedge S_AXI_ACLK)
        begin
            if (!sawstall)
            begin


                if (bm2slv_arr[sw_ptr[islv]].AWVALID && slv_awaccepts[sw_ptr[islv]])
                begin
                    axi_awid    <= bm2slv_arr[sw_ptr[islv]].AWID    ;
                    axi_awaddr  <= bm2slv_arr[sw_ptr[islv]].AWADDR  ;
                    axi_awlen   <= bm2slv_arr[sw_ptr[islv]].AWLEN   ;
                    axi_awsize  <= bm2slv_arr[sw_ptr[islv]].AWSIZE  ;
                    axi_awburst <= bm2slv_arr[sw_ptr[islv]].AWBURST ;
                    axi_awlock  <= bm2slv_arr[sw_ptr[islv]].AWLOCK  ;
                    axi_awcache <= bm2slv_arr[sw_ptr[islv]].AWCACHE ;
                    axi_awprot  <= bm2slv_arr[sw_ptr[islv]].AWPROT  ;
                    axi_awqos   <= bm2slv_arr[sw_ptr[islv]].AWQOS   ;
                end else begin
                    axi_awid    <= 0;
                    axi_awaddr  <= 0;
                    axi_awlen   <= 0;
                    axi_awsize  <= 0;
                    axi_awburst <= 0;
                    axi_awlock  <= 0;
                    axi_awcache <= 0;
                    axi_awprot  <= 0;
                    axi_awqos   <= 0;
                end
            end

            if (!swstall)
            begin

                if ((bm2slv_arr[sw_ptr[islv]].WVALID && slv_waccepts[sw_ptr[islv]]))
                begin
                    // If NM <= 1, sw_ptr[islv] is already defined
                    // to be zero above
                    axi_wdata <= bm2slv_arr[sw_ptr[islv]].WDATA;
                    axi_wstrb <= bm2slv_arr[sw_ptr[islv]].WSTRB;
                    axi_wlast <= bm2slv_arr[sw_ptr[islv]].WLAST;
                end else begin
                    axi_wdata <= 0;
                    axi_wstrb <= 0;
                    axi_wlast <= 0;
                end

            end
        
        end
        always_comb
        begin
            if (!swgrant_s[islv])
                axi_bready = 1;
            else
                axi_bready = bresp_stall_rdy_s[sw_ptr[islv]];

        end

        assign  M_AXI[islv].AWVALID  = axi_awvalid;
        assign  M_AXI[islv].AWID     = axi_awid;
        assign  M_AXI[islv].AWADDR   = axi_awaddr;
        assign  M_AXI[islv].AWLEN    = axi_awlen;
        assign  M_AXI[islv].AWSIZE   = axi_awsize;
        assign  M_AXI[islv].AWBURST  = axi_awburst;
        assign  M_AXI[islv].AWLOCK   = axi_awlock;
        assign  M_AXI[islv].AWCACHE  = axi_awcache;
        assign  M_AXI[islv].AWPROT   = axi_awprot;
        assign  M_AXI[islv].AWQOS    = axi_awqos;

        assign  M_AXI[islv].WVALID   = axi_wvalid;
        assign  M_AXI[islv].WDATA    = axi_wdata;
        assign  M_AXI[islv].WSTRB    = axi_wstrb;
        assign  M_AXI[islv].WLAST    = axi_wlast;
        assign  M_AXI[islv].BREADY   = axi_bready;
    end 
    endgenerate


    generate for(islv=0; islv<NS; islv=islv+1)
    begin : BM2SLV_ROUTE_RD

        reg                       axi_arvalid;
        reg [NIC_ID_WIDTH-1:0]     axi_arid;
        reg [NIC_AWADDR_WD-1:0]    axi_araddr;
        reg [7:0]                  axi_arlen;
        reg [2:0]                  axi_arsize;
        reg [1:0]                  axi_arburst;
        reg                       axi_arlock;
        reg [3:0]                  axi_arcache;
        reg [2:0]                  axi_arprot;
        reg [3:0]                  axi_arqos;
        //
        reg                       axi_rready;
        reg                       arstall;

        always @(posedge S_AXI_ACLK)
        begin
            if (!S_AXI_ARESETN || !srgrant_s[islv])
                axi_arvalid <= 0;
            else if (!arstall)
                axi_arvalid <= bm2slv_arr[sr_ptr[islv]].ARVALID && slv_raccepts[sr_ptr[islv]];
            else if (M_AXI[islv].ARREADY)
                axi_arvalid <= 0;
        end

        always_comb
            arstall = axiarvalid && !M_AXI[islv].ARREADY;

        always @(posedge S_AXI_ACLK)
        begin
        
            if (!arstall)
            begin

                if (bm2slv_arr[sr_ptr[islv]].ARVALID && slv_raccepts[sr_ptr[islv]])
                begin   
                    

                    axi_arid    <= bm2slv_arr[sr_ptr[islv]].ARID;
                    axi_araddr  <= bm2slv_arr[sr_ptr[islv]].ARADDR;
                    axi_arlen   <= bm2slv_arr[sr_ptr[islv]].ARLEN;
                    axi_arsize  <= bm2slv_arr[sr_ptr[islv]].ARSIZE;
                    axi_arburst <= bm2slv_arr[sr_ptr[islv]].ARBURST;
                    axi_arlock  <= bm2slv_arr[sr_ptr[islv]].ARLOCK;
                    axi_arcache <= bm2slv_arr[sr_ptr[islv]].ARCACHE;
                    axi_arprot  <= bm2slv_arr[sr_ptr[islv]].ARPROT;
                    axi_arqos   <= bm2slv_arr[sr_ptr[islv]].ARQOS;


                end else begin
                    axi_arid    <= 0;
                    axi_araddr  <= 0;
                    axi_arlen   <= 0;
                    axi_arsize  <= 0;
                    axi_arburst <= 0;
                    axi_arlock  <= 0;
                    axi_arcache <= 0;
                    axi_arprot  <= 0;
                    axi_arqos   <= 0;

                end
            end
        end

        always_comb
        begin
            if (!srgrant_s[islv])
                axi_rready = 1;
            else
                axi_rready = rd_stall_rdy_s[sr_ptr[islv]];
        end
        assign  M_AXI[islv].ARVALID  = axi_arvalid;
        assign  M_AXI[islv].ARID     = axi_arid;
        assign  M_AXI[islv].ARADDR   = axi_araddr;
        assign  M_AXI[islv].ARLEN    = axi_arlen;
        assign  M_AXI[islv].ARSIZE   = axi_arsize;
        assign  M_AXI[islv].ARBURST  = axi_arburst;
        assign  M_AXI[islv].ARLOCK   = axi_arlock;

        assign M_AXI[islv].ARCACHE  = axi_arcache;
        assign M_AXI[islv].ARPROT   = axi_arprot;
        assign M_AXI[islv].ARQOS    = axi_arqos;
        assign M_AXI[islv].RREADY   = axi_rready;

    end
    endgenerate

    integer mstr_i, slv_i;
    
    generate
    begin : PRIORITY_ARBITER
        always_comb
        begin
                // [missing lines 570-570]
            for(mstr_i=0; mstr_i<=NM; mstr_i=mstr_i+1)
                wr_order_arr[mstr_i] = 0;
                // [missing lines 573-580]
            wr_order_arr[NM] = 0;
                // [missing lines 582-582]
            for(slv_i=0; slv_i<NS; slv_i=slv_i+1)
            begin
                wr_order_arr[0][slv_i] = 1'b0;
                for(mstr_i=1; mstr_i<NM; mstr_i=mstr_i+1)
                begin
                    // Continue to request any channel with
                    // a grant and pending operations
                    if (wrequest[mstr_i-1][slv_i] && wgrant_s[mstr_i-1][slv_i])
                        wr_order_arr[mstr_i][slv_i] = 1;
                    if (wrequest[mstr_i-1][slv_i] && (!(mwgrant_s[mstr_i-1]) || mwempty_s[mstr_i-1]))
                        wr_order_arr[mstr_i][slv_i] = 1;
                    // Otherwise, if it's already claimed, then
                    // it can't be claimed again
                    if (wr_order_arr[mstr_i-1][slv_i])
                        wr_order_arr[mstr_i][slv_i] = 1;
                    // [missing lines 598-598]
                end
                wr_order_arr[NM][slv_i] = wrequest[NM-1][slv_i] || wr_order_arr[NM-1][slv_i];
            end
        end            
            
            
        always_comb
        begin
            // [missing lines 604-604]
            for(mstr_i=0; mstr_i<NM; mstr_i=mstr_i+1)
                rd_order_arr[mstr_i] = 0;
            
            rd_order_arr[NM] = 0;
            
            for(slv_i=0; slv_i<NS; slv_i=slv_i+1)
            begin
                rd_order_arr[0][slv_i] = 0;
                for(mstr_i=1; mstr_i<NM; mstr_i=mstr_i+1)
                begin
                    // Continue to request any channel with
                    // a grant and pending operations
                    if (rrequest[mstr_i-1][slv_i] && rgrant_s[mstr_i-1][slv_i])
                        rd_order_arr[mstr_i][slv_i] = 1;
                    if (rrequest[mstr_i-1][slv_i] && (!(mrgrant_s[mstr_i-1]) || mrempty_s[mstr_i-1]))
                        rd_order_arr[mstr_i][slv_i] = 1;
                    // Otherwise, if it's already claimed, then
                    // it can't be claimed again
                    if (rd_order_arr[mstr_i-1][slv_i])
                        rd_order_arr[mstr_i][slv_i] = 1;
                end
                rd_order_arr[NM][slv_i] = rrequest[NM-1][slv_i] || rd_order_arr[NM-1][slv_i];
             
            end
        end
       
        always_comb
        begin

            for (slv_i=0; slv_i<NS; slv_i=slv_i+1)
            begin : SGRANTW

                swgrant_s[slv_i] = 0;
                for (mstr_i=0; mstr_i<NM; mstr_i=mstr_i+1)
                    if (wgrant_s[mstr_i][slv_i])
                        swgrant_s[slv_i] = 1;

            end

        end

        always_comb
        begin
            for (slv_i=0; slv_i<NS; slv_i=slv_i+1)
            begin : SGRANTR

                srgrant_s[slv_i] = 0;
                for (mstr_i=0; mstr_i<NM; mstr_i=mstr_i+1)
                    if (rgrant_s[mstr_i][slv_i])
                        srgrant_s[slv_i] = 1;

            end
        end

    end
    endgenerate

    generate for (islv=0; islv<NS; islv=islv+1)
    begin : W4_SLAVE_WRITE_INDEX
        // {{{
        // sw_ptr is a per slave index, containing the index of the
        // master that has currently won write arbitration
        // has permission to access this slave
        integer imstr_t;
        if (NM <= 1)
        begin : ONE_MASTER

            // If there's only ever one master, that index is
            // always the index of the one master.
            assign sw_ptr[islv] = 0;

        end else begin : MULTIPLE_MASTERS

            reg [LGNM-1:0] reqwindex, r_sw_ptr;

            always_comb
            begin
                reqwindex = 0;
                for(imstr_t=0; imstr_t<NM; imstr_t=imstr_t+1)
                begin
                    if ((!mwgrant_s[imstr_t] || mwempty_s[imstr_t])
                        &&(wrequest[imstr_t][islv] && !wr_order_arr[imstr_t][islv]))
                        reqwindex = reqwindex | imstr_t[LGNM-1:0];
                end
            end

            // if slave is not busy then only T-1 sw_ptr is updated,
            //

            always @(posedge S_AXI_ACLK)
                if (!swgrant_s[islv])
                    r_sw_ptr <= reqwindex;

            assign sw_ptr[islv] = r_sw_ptr;

        end
    end endgenerate


    generate for (islv=0; islv<NS; islv=islv+1)
    begin : R4_SLAVE_READ_INDEX
        // {{{
        // sr_ptr is an index to the master that has currently won
        // read arbitration to the given slave.
        integer imstr_t;
        if (NM <= 1)
        begin : ONE_MASTER

            // If there's only one master; sr_ptr can always
            // point to that master--no logic required
            assign sr_ptr[islv] = 0;

        end else begin : MULTIPLE_MASTERS

            reg [LGNM-1:0] reqrindex, r_sr_ptr;

            always_comb
            begin
                reqrindex = 0;
                for(imstr_t=0; imstr_t<NM; imstr_t=imstr_t+1)
                begin
                    if ((!mrgrant_s[imstr_t] || mrempty_s[imstr_t])
                        &&(rrequest[imstr_t][islv] && !rd_order_arr[imstr_t][islv]))
                        reqrindex = reqrindex | imstr_t[LGNM-1:0];
                end
            end

            always @(posedge S_AXI_ACLK)
                if (!srgrant_s[islv])
                    r_sr_ptr <= reqrindex;

            assign sr_ptr[islv] = r_sr_ptr;

        end
    end endgenerate

endmodule
