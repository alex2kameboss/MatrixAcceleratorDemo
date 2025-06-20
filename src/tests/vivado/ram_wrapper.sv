module ram_wrapper (
    input           hbm_clk ,
    input           clk     ,
    input           rst_n   ,
    AXI_BUS.Slave   axi        
);

localparam HBM_LENGTH = 64'h0_0000_0000;

localparam AXI_NO_MASTERS = 1;
localparam AXI_NO_SLAVES = 4; // 1GB of HBM
localparam AXI_ID_WIDTH_SLAVE = axi.AXI_ID_WIDTH + $clog2(AXI_NO_MASTERS);
localparam AXI_DATA_WIDTH   = 256; // HBM width
localparam AXI_ADDR_WIDTH   = axi.AXI_ADDR_WIDTH;
localparam AXI_USER_WIDTH   = axi.AXI_USER_WIDTH;

localparam axi_pkg::xbar_cfg_t xbar_cfg = '{
    NoSlvPorts:         AXI_NO_MASTERS,
    NoMstPorts:         AXI_NO_SLAVES,
    MaxMstTrans:        1,
    MaxSlvTrans:        1,
    FallThrough:        1'b0,
    LatencyMode:        axi_pkg::CUT_MST_PORTS,
    PipelineStages:     0,
    AxiIdWidthSlvPorts: axi.AXI_ID_WIDTH,
    AxiIdUsedSlvPorts:  axi.AXI_ID_WIDTH,
    UniqueIds:          1'b0,
    AxiAddrWidth:       AXI_ADDR_WIDTH,
    AxiDataWidth:       AXI_DATA_WIDTH,
    NoAddrRules:        AXI_NO_SLAVES
};

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH    ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH    ),
    .AXI_ID_WIDTH   ( axi.AXI_ID_WIDTH  ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH    )
) axi_256 [0:0] ();

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH        ),
    .AXI_ID_WIDTH   ( AXI_ID_WIDTH_SLAVE    ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH        )
) slave [AXI_NO_SLAVES-1:0] ();
axi_pkg::xbar_rule_64_t [AXI_NO_SLAVES - 1 : 0] routing_rules;


assign routing_rules = '{
    '{idx: 0, start_addr: 0 * HBM_LENGTH, end_addr: 1 * HBM_LENGTH},
    '{idx: 1, start_addr: 1 * HBM_LENGTH, end_addr: 2 * HBM_LENGTH},
    '{idx: 2, start_addr: 2 * HBM_LENGTH, end_addr: 3 * HBM_LENGTH},
    '{idx: 3, start_addr: 3 * HBM_LENGTH, end_addr: 4 * HBM_LENGTH}
};


axi_dw_converter_intf #(
    .AXI_ID_WIDTH               ( axi.AXI_ID_WIDTH  ),
    .AXI_ADDR_WIDTH             ( AXI_ADDR_WIDTH    ),
    .AXI_SLV_PORT_DATA_WIDTH    ( axi.AXI_DATA_WIDTH),
    .AXI_MST_PORT_DATA_WIDTH    ( AXI_DATA_WIDTH    ),
    .AXI_USER_WIDTH             ( AXI_USER_WIDTH    ),
    .AXI_MAX_READS              ( 2                 )
) i_axi_to_hbm (
    .clk_i  ( clk       ),
    .rst_ni ( rst_n     ),
    .slv    ( axi       ),
    .mst    ( axi_256[0])
);

axi_xbar_intf #(
    .AXI_USER_WIDTH ( AXI_USER_WIDTH            ),
    .Cfg            ( xbar_cfg                  ),
    .rule_t         ( axi_pkg::xbar_rule_64_t   )
) i_xbar (
    .clk_i                  ( clk           ),
    .rst_ni                 ( rst_n         ),
    .test_i                 ( 1'b0          ),
    .slv_ports              ( axi_256       ),
    .mst_ports              ( slave         ),
    .addr_map_i             ( routing_rules ),
    .en_default_mst_port_i  ( '0            ),
    .default_mst_port_i     ( '0            )
);

hbm_ram i_hbm (
    .HBM_REF_CLK_0      ( hbm_clk                   ),  // input wire HBM_REF_CLK_0

    .AXI_00_ACLK        ( clk                       ),  // input wire AXI_00_ACLK
    .AXI_00_ARESET_N    ( rst_n                     ),  // input wire AXI_00_ARESET_N
    .AXI_00_ARADDR      ( slave[0].ar_addr[32:0]    ),  // input wire [32 : 0] AXI_00_ARADDR
    .AXI_00_ARBURST     ( slave[0].ar_burst         ),  // input wire [1 : 0] AXI_00_ARBURST
    .AXI_00_ARID        ( slave[0].ar_id            ),  // input wire [5 : 0] AXI_00_ARID
    .AXI_00_ARLEN       ( slave[0].ar_len[3 : 0]    ),  // input wire [3 : 0] AXI_00_ARLEN
    .AXI_00_ARSIZE      ( slave[0].ar_size          ),  // input wire [2 : 0] AXI_00_ARSIZE
    .AXI_00_ARVALID     ( slave[0].ar_valid         ),  // input wire AXI_00_ARVALID
    .AXI_00_AWADDR      ( slave[0].aw_addr[32:0]    ),  // input wire [32 : 0] AXI_00_AWADDR
    .AXI_00_AWBURST     ( slave[0].aw_burst         ),  // input wire [1 : 0] AXI_00_AWBURST
    .AXI_00_AWID        ( slave[0].aw_id            ),  // input wire [5 : 0] AXI_00_AWID
    .AXI_00_AWLEN       ( slave[0].aw_len[3 : 0]    ),  // input wire [3 : 0] AXI_00_AWLEN
    .AXI_00_AWSIZE      ( slave[0].aw_size          ),  // input wire [2 : 0] AXI_00_AWSIZE
    .AXI_00_AWVALID     ( slave[0].aw_valid         ),  // input wire AXI_00_AWVALID
    .AXI_00_RREADY      ( slave[0].r_ready          ),  // input wire AXI_00_RREADY
    .AXI_00_BREADY      ( slave[0].b_ready          ),  // input wire AXI_00_BREADY
    .AXI_00_WDATA       ( slave[0].w_data           ),  // input wire [255 : 0] AXI_00_WDATA
    .AXI_00_WLAST       ( slave[0].w_last           ),  // input wire AXI_00_WLAST
    .AXI_00_WSTRB       ( slave[0].w_strb           ),  // input wire [31 : 0] AXI_00_WSTRB
    .AXI_00_WDATA_PARITY( 'd0                       ),  // input wire [31 : 0] AXI_00_WDATA_PARITY
    .AXI_00_WVALID      ( slave[0].w_valid          ),  // input wire AXI_00_WVALID

    .AXI_01_ACLK        ( clk                       ),  // input wire AXI_01_ACLK
    .AXI_01_ARESET_N    ( rst_n                     ),  // input wire AXI_01_ARESET_N
    .AXI_01_ARADDR      ( slave[1].ar_addr[32:0]    ),  // input wire [32 : 0] AXI_01_ARADDR
    .AXI_01_ARBURST     ( slave[1].ar_burst         ),  // input wire [1 : 0] AXI_01_ARBURST
    .AXI_01_ARID        ( slave[1].ar_id            ),  // input wire [5 : 0] AXI_01_ARID
    .AXI_01_ARLEN       ( slave[1].ar_len[3 : 0]    ),  // input wire [3 : 0] AXI_01_ARLEN
    .AXI_01_ARSIZE      ( slave[1].ar_size          ),  // input wire [2 : 0] AXI_01_ARSIZE
    .AXI_01_ARVALID     ( slave[1].ar_valid         ),  // input wire AXI_01_ARVALID
    .AXI_01_AWADDR      ( slave[1].aw_addr[32:0]    ),  // input wire [32 : 0] AXI_01_AWADDR
    .AXI_01_AWBURST     ( slave[1].aw_burst         ),  // input wire [1 : 0] AXI_01_AWBURST
    .AXI_01_AWID        ( slave[1].aw_id            ),  // input wire [5 : 0] AXI_01_AWID
    .AXI_01_AWLEN       ( slave[1].aw_len[3 : 0]    ),  // input wire [3 : 0] AXI_01_AWLEN
    .AXI_01_AWSIZE      ( slave[1].aw_size          ),  // input wire [2 : 0] AXI_01_AWSIZE
    .AXI_01_AWVALID     ( slave[1].aw_valid         ),  // input wire AXI_01_AWVALID
    .AXI_01_RREADY      ( slave[1].r_ready          ),  // input wire AXI_01_RREADY
    .AXI_01_BREADY      ( slave[1].b_ready          ),  // input wire AXI_01_BREADY
    .AXI_01_WDATA       ( slave[1].w_data           ),  // input wire [255 : 0] AXI_01_WDATA
    .AXI_01_WLAST       ( slave[1].w_last           ),  // input wire AXI_01_WLAST
    .AXI_01_WSTRB       ( slave[1].w_strb           ),  // input wire [31 : 0] AXI_01_WSTRB
    .AXI_01_WDATA_PARITY( 'd0                       ),  // input wire [31 : 0] AXI_01_WDATA_PARITY
    .AXI_01_WVALID      ( slave[1].w_valid          ),  // input wire AXI_01_WVALID

    .AXI_02_ACLK        ( clk                       ),  // input wire AXI_02_ACLK
    .AXI_02_ARESET_N    ( rst_n                     ),  // input wire AXI_02_ARESET_N
    .AXI_02_ARADDR      ( slave[2].ar_addr[32:0]    ),  // input wire [32 : 0] AXI_02_ARADDR
    .AXI_02_ARBURST     ( slave[2].ar_burst         ),  // input wire [1 : 0] AXI_02_ARBURST
    .AXI_02_ARID        ( slave[2].ar_id            ),  // input wire [5 : 0] AXI_02_ARID
    .AXI_02_ARLEN       ( slave[2].ar_len[3 : 0]    ),  // input wire [3 : 0] AXI_02_ARLEN
    .AXI_02_ARSIZE      ( slave[2].ar_size          ),  // input wire [2 : 0] AXI_02_ARSIZE
    .AXI_02_ARVALID     ( slave[2].ar_valid         ),  // input wire AXI_02_ARVALID
    .AXI_02_AWADDR      ( slave[2].aw_addr[32:0]    ),  // input wire [32 : 0] AXI_02_AWADDR
    .AXI_02_AWBURST     ( slave[2].aw_burst         ),  // input wire [1 : 0] AXI_02_AWBURST
    .AXI_02_AWID        ( slave[2].aw_id            ),  // input wire [5 : 0] AXI_02_AWID
    .AXI_02_AWLEN       ( slave[2].aw_len[3 : 0]    ),  // input wire [3 : 0] AXI_02_AWLEN
    .AXI_02_AWSIZE      ( slave[2].aw_size          ),  // input wire [2 : 0] AXI_02_AWSIZE
    .AXI_02_AWVALID     ( slave[2].aw_valid         ),  // input wire AXI_02_AWVALID
    .AXI_02_RREADY      ( slave[2].r_ready          ),  // input wire AXI_02_RREADY
    .AXI_02_BREADY      ( slave[2].b_ready          ),  // input wire AXI_02_BREADY
    .AXI_02_WDATA       ( slave[2].w_data           ),  // input wire [255 : 0] AXI_02_WDATA
    .AXI_02_WLAST       ( slave[2].w_last           ),  // input wire AXI_02_WLAST
    .AXI_02_WSTRB       ( slave[2].w_strb           ),  // input wire [31 : 0] AXI_02_WSTRB
    .AXI_02_WDATA_PARITY( 'd0                       ),  // input wire [31 : 0] AXI_02_WDATA_PARITY
    .AXI_02_WVALID      ( slave[2].w_valid          ),  // input wire AXI_02_WVALID

    .AXI_03_ACLK        ( clk                       ),  // input wire AXI_03_ACLK
    .AXI_03_ARESET_N    ( rst_n                     ),  // input wire AXI_03_ARESET_N
    .AXI_03_ARADDR      ( slave[3].ar_addr[32:0]    ),  // input wire [32 : 0] AXI_03_ARADDR
    .AXI_03_ARBURST     ( slave[3].ar_burst         ),  // input wire [1 : 0] AXI_03_ARBURST
    .AXI_03_ARID        ( slave[3].ar_id            ),  // input wire [5 : 0] AXI_03_ARID
    .AXI_03_ARLEN       ( slave[3].ar_len[3 : 0]    ),  // input wire [3 : 0] AXI_03_ARLEN
    .AXI_03_ARSIZE      ( slave[3].ar_size          ),  // input wire [2 : 0] AXI_03_ARSIZE
    .AXI_03_ARVALID     ( slave[3].ar_valid         ),  // input wire AXI_03_ARVALID
    .AXI_03_AWADDR      ( slave[3].aw_addr[32:0]    ),  // input wire [32 : 0] AXI_03_AWADDR
    .AXI_03_AWBURST     ( slave[3].aw_burst         ),  // input wire [1 : 0] AXI_03_AWBURST
    .AXI_03_AWID        ( slave[3].aw_id            ),  // input wire [5 : 0] AXI_03_AWID
    .AXI_03_AWLEN       ( slave[3].aw_len[3 : 0]    ),  // input wire [3 : 0] AXI_03_AWLEN
    .AXI_03_AWSIZE      ( slave[3].aw_size          ),  // input wire [2 : 0] AXI_03_AWSIZE
    .AXI_03_AWVALID     ( slave[3].aw_valid         ),  // input wire AXI_03_AWVALID
    .AXI_03_RREADY      ( slave[3].r_ready          ),  // input wire AXI_03_RREADY
    .AXI_03_BREADY      ( slave[3].b_ready          ),  // input wire AXI_03_BREADY
    .AXI_03_WDATA       ( slave[3].w_data           ),  // input wire [255 : 0] AXI_03_WDATA
    .AXI_03_WLAST       ( slave[3].w_last           ),  // input wire AXI_03_WLAST
    .AXI_03_WSTRB       ( slave[3].w_strb           ),  // input wire [31 : 0] AXI_03_WSTRB
    .AXI_03_WDATA_PARITY( 'd0                       ),  // input wire [31 : 0] AXI_03_WDATA_PARITY
    .AXI_03_WVALID      ( slave[3].w_valid          ),  // input wire AXI_03_WVALID

    .APB_0_PCLK         ( clk                       ),  // input wire APB_0_PCLK
    .APB_0_PRESET_N     ( rst_n                     ),  // input wire APB_0_PRESET_N

    .AXI_00_ARREADY     ( slave[0].ar_ready         ),  // output wire AXI_00_ARREADY
    .AXI_00_AWREADY     ( slave[0].aw_ready         ),  // output wire AXI_00_AWREADY
    .AXI_00_RDATA_PARITY( /*NOT CONNECTED*/         ),  // output wire [31 : 0] AXI_00_RDATA_PARITY
    .AXI_00_RDATA       ( slave[0].r_data           ),  // output wire [255 : 0] AXI_00_RDATA
    .AXI_00_RID         ( slave[0].r_id             ),  // output wire [5 : 0] AXI_00_RID
    .AXI_00_RLAST       ( slave[0].r_last           ),  // output wire AXI_00_RLAST
    .AXI_00_RRESP       ( slave[0].r_resp           ),  // output wire [1 : 0] AXI_00_RRESP
    .AXI_00_RVALID      ( slave[0].r_valid          ),  // output wire AXI_00_RVALID
    .AXI_00_WREADY      ( slave[0].w_ready          ),  // output wire AXI_00_WREADY
    .AXI_00_BID         ( slave[0].b_id             ),  // output wire [5 : 0] AXI_00_BID
    .AXI_00_BRESP       ( slave[0].b_resp           ),  // output wire [1 : 0] AXI_00_BRESP
    .AXI_00_BVALID      ( slave[0].b_valid          ),  // output wire AXI_00_BVALID

    .AXI_01_ARREADY     ( slave[1].ar_ready         ),  // output wire AXI_01_ARREADY
    .AXI_01_AWREADY     ( slave[1].aw_ready         ),  // output wire AXI_01_AWREADY
    .AXI_01_RDATA_PARITY( /*NOT CONNECTED*/         ),  // output wire [31 : 0] AXI_01_RDATA_PARITY
    .AXI_01_RDATA       ( slave[1].r_data           ),  // output wire [255 : 0] AXI_01_RDATA
    .AXI_01_RID         ( slave[1].r_id             ),  // output wire [5 : 0] AXI_01_RID
    .AXI_01_RLAST       ( slave[1].r_last           ),  // output wire AXI_01_RLAST
    .AXI_01_RRESP       ( slave[1].r_resp           ),  // output wire [1 : 0] AXI_01_RRESP
    .AXI_01_RVALID      ( slave[1].r_valid          ),  // output wire AXI_01_RVALID
    .AXI_01_WREADY      ( slave[1].w_ready          ),  // output wire AXI_01_WREADY
    .AXI_01_BID         ( slave[1].b_id             ),  // output wire [5 : 0] AXI_01_BID
    .AXI_01_BRESP       ( slave[1].b_resp           ),  // output wire [1 : 0] AXI_01_BRESP
    .AXI_01_BVALID      ( slave[1].b_valid          ),  // output wire AXI_01_BVALID

    .AXI_02_ARREADY     ( slave[2].ar_ready         ),  // output wire AXI_02_ARREADY
    .AXI_02_AWREADY     ( slave[2].aw_ready         ),  // output wire AXI_02_AWREADY
    .AXI_02_RDATA_PARITY( /*NOT CONNECTED*/         ),  // output wire [31 : 0] AXI_02_RDATA_PARITY
    .AXI_02_RDATA       ( slave[2].r_data           ),  // output wire [255 : 0] AXI_02_RDATA
    .AXI_02_RID         ( slave[2].r_id             ),  // output wire [5 : 0] AXI_02_RID
    .AXI_02_RLAST       ( slave[2].r_last           ),  // output wire AXI_02_RLAST
    .AXI_02_RRESP       ( slave[2].r_resp           ),  // output wire [1 : 0] AXI_02_RRESP
    .AXI_02_RVALID      ( slave[2].r_valid          ),  // output wire AXI_02_RVALID
    .AXI_02_WREADY      ( slave[2].w_ready          ),  // output wire AXI_02_WREADY
    .AXI_02_BID         ( slave[2].b_id             ),  // output wire [5 : 0] AXI_02_BID
    .AXI_02_BRESP       ( slave[2].b_resp           ),  // output wire [1 : 0] AXI_02_BRESP
    .AXI_02_BVALID      ( slave[2].b_valid          ),  // output wire AXI_02_BVALID

    .AXI_03_ARREADY     ( slave[3].ar_ready         ),  // output wire AXI_03_ARREADY
    .AXI_03_AWREADY     ( slave[3].aw_ready         ),  // output wire AXI_03_AWREADY
    .AXI_03_RDATA_PARITY( /*NOT CONNECTED*/         ),  // output wire [31 : 0] AXI_03_RDATA_PARITY
    .AXI_03_RDATA       ( slave[3].r_data           ),  // output wire [255 : 0] AXI_03_RDATA
    .AXI_03_RID         ( slave[3].r_id             ),  // output wire [5 : 0] AXI_03_RID
    .AXI_03_RLAST       ( slave[3].r_last           ),  // output wire AXI_03_RLAST
    .AXI_03_RRESP       ( slave[3].r_resp           ),  // output wire [1 : 0] AXI_03_RRESP
    .AXI_03_RVALID      ( slave[3].r_valid          ),  // output wire AXI_03_RVALID
    .AXI_03_WREADY      ( slave[3].w_ready          ),  // output wire AXI_03_WREADY
    .AXI_03_BID         ( slave[3].b_id             ),  // output wire [5 : 0] AXI_03_BID
    .AXI_03_BRESP       ( slave[3].b_resp           ),  // output wire [1 : 0] AXI_03_BRESP
    .AXI_03_BVALID      ( slave[3].b_valid          ),  // output wire AXI_03_BVALID

    .apb_complete_0     ( /*NOT CONNECTED*/         ),  // output wire apb_complete_0
    .DRAM_0_STAT_CATTRIP( /*NOT CONNECTED*/         ),  // output wire DRAM_0_STAT_CATTRIP
    .DRAM_0_STAT_TEMP   ( /*NOT CONNECTED*/         )   // output wire [6 : 0] DRAM_0_STAT_TEMP
);

endmodule