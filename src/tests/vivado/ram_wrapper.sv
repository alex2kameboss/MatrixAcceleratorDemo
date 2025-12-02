module ram_wrapper (
    input           hbm_clk         ,
    output          init_complete   ,
    input           clk             ,
    input           rst_n           ,
    AXI_BUS.Slave   axi                
);

localparam HBM_LENGTH = 64'h0_1000_0000;

localparam AXI_NO_MASTERS = 1;
localparam AXI_NO_SLAVES = 4; // 1GB of HBM
localparam AXI_ID_WIDTH_SLAVE = axi.AXI_ID_WIDTH + $clog2(AXI_NO_MASTERS);
localparam AXI_DATA_WIDTH   = 256; // HBM width
localparam AXI_ADDR_WIDTH   = 33;
localparam AXI_USER_WIDTH   = axi.AXI_USER_WIDTH;

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH    ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH    ),
    .AXI_ID_WIDTH   ( axi.AXI_ID_WIDTH  ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH    )
) axi_256 [0:0] ();

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

`ifdef HBM

hbm_subsystem_wrapper i_hbm_subsystem(
    .HBM_REF_CLK_0_0    ( hbm_clk                           ), //   input HBM_REF_CLK_0_0;
    .axi_aclk_0         ( clk                               ), //   input axi_aclk_0;
    .axi_aresetn_0      ( rst_n                             ), //   input axi_aresetn_0;
    .init_complete_out_0( init_complete                     ), //   output init_complete_out_0;
    
    .s_axi_0_araddr     ( {2'd0, axi_256[0].ar_addr[30:0]}  ), //   input [32:0]s_axi_0_araddr;
    .s_axi_0_arburst    ( axi_256[0].ar_burst               ), //   input [1:0]s_axi_0_arburst;
    .s_axi_0_arid       ( axi_256[0].ar_id                  ), //   input [5:0]s_axi_0_arid;
    .s_axi_0_arlen      ( axi_256[0].ar_len                 ), //   input [7:0]s_axi_0_arlen;
    .s_axi_0_arready    ( axi_256[0].ar_ready               ), //   output s_axi_0_arready;
    .s_axi_0_arsize     ( axi_256[0].ar_size                ), //   input [2:0]s_axi_0_arsize;
    .s_axi_0_arvalid    ( axi_256[0].ar_valid               ), //   input s_axi_0_arvalid;
    
    .s_axi_0_awaddr     ( {2'd0, axi_256[0].aw_addr[30:0]}  ), //   input [32:0]s_axi_0_awaddr;
    .s_axi_0_awburst    ( axi_256[0].aw_burst               ), //   input [1:0]s_axi_0_awburst;
    .s_axi_0_awid       ( axi_256[0].aw_id                  ), //   input [5:0]s_axi_0_awid;
    .s_axi_0_awlen      ( axi_256[0].aw_len                 ), //   input [7:0]s_axi_0_awlen;
    .s_axi_0_awready    ( axi_256[0].aw_ready               ), //   output s_axi_0_awready;
    .s_axi_0_awsize     ( axi_256[0].aw_size                ), //   input [2:0]s_axi_0_awsize;
    .s_axi_0_awvalid    ( axi_256[0].aw_valid               ), //   input s_axi_0_awvalid;
    
    .s_axi_0_bid        ( axi_256[0].b_id                   ), //   output [5:0]s_axi_0_bid;
    .s_axi_0_bready     ( axi_256[0].b_ready                ), //   input s_axi_0_bready;
    .s_axi_0_bresp      ( axi_256[0].b_resp                 ), //   output [1:0]s_axi_0_bresp;
    .s_axi_0_bvalid     ( axi_256[0].b_valid                ), //   output s_axi_0_bvalid;
    
    .s_axi_0_rdata      ( axi_256[0].r_data                 ), //   output [255:0]s_axi_0_rdata;
    .s_axi_0_rid        ( axi_256[0].r_id                   ), //   output [5:0]s_axi_0_rid;
    .s_axi_0_rlast      ( axi_256[0].r_last                 ), //   output s_axi_0_rlast;
    .s_axi_0_rready     ( axi_256[0].r_ready                ), //   input s_axi_0_rready;
    .s_axi_0_rresp      ( axi_256[0].r_resp                 ), //   output [1:0]s_axi_0_rresp;
    .s_axi_0_rvalid     ( axi_256[0].r_valid                ), //   output s_axi_0_rvalid;
    
    .s_axi_0_wdata      ( axi_256[0].w_data                 ), //   input [255:0]s_axi_0_wdata;
    .s_axi_0_wlast      ( axi_256[0].w_last                 ), //   input s_axi_0_wlast;
    .s_axi_0_wready     ( axi_256[0].w_ready                ), //   output s_axi_0_wready;
    .s_axi_0_wstrb      ( axi_256[0].w_strb                 ), //   input [31:0]s_axi_0_wstrb;
    .s_axi_0_wvalid     ( axi_256[0].w_valid                )  //   input s_axi_0_wvalid;
);

`else

assign init_complete = 1'b1;

mem_2MB i_ram (
    .rsta_busy      (                                   ),  // output wire rsta_busy
    .rstb_busy      (                                   ),  // output wire rstb_busy
    
    .s_aclk         ( clk                               ),  // input wire s_aclk
    .s_aresetn      ( rst_n                             ),  // input wire s_aresetn
    
    .s_axi_awid     ( axi_256[0].aw_id                  ),  // input wire [5 : 0] s_axi_awid
    .s_axi_awaddr   ( {3'd0, axi_256[0].aw_addr[29:0]}  ),  // input wire [31 : 0] s_axi_awaddr
    .s_axi_awlen    ( axi_256[0].aw_len                 ),  // input wire [7 : 0] s_axi_awlen
    .s_axi_awsize   ( axi_256[0].aw_size                ),  // input wire [2 : 0] s_axi_awsize
    .s_axi_awburst  ( axi_256[0].aw_burst               ),  // input wire [1 : 0] s_axi_awburst
    .s_axi_awvalid  ( axi_256[0].aw_valid               ),  // input wire s_axi_awvalid
    .s_axi_awready  ( axi_256[0].aw_ready               ),  // output wire s_axi_awready
    
    .s_axi_wdata    ( axi_256[0].w_data                 ),  // input wire [255 : 0] s_axi_wdata
    .s_axi_wstrb    ( axi_256[0].w_strb                 ),  // input wire [31 : 0] s_axi_wstrb
    .s_axi_wlast    ( axi_256[0].w_last                 ),  // input wire s_axi_wlast
    .s_axi_wvalid   ( axi_256[0].w_valid                ),  // input wire s_axi_wvalid
    .s_axi_wready   ( axi_256[0].w_ready                ),  // output wire s_axi_wready
    
    .s_axi_bid      (axi_256[0].b_id                    ),  // output wire [5 : 0] s_axi_bid
    .s_axi_bresp    (axi_256[0].b_resp                  ),  // output wire [1 : 0] s_axi_bresp
    .s_axi_bvalid   (axi_256[0].b_valid                 ),  // output wire s_axi_bvalid
    .s_axi_bready   (axi_256[0].b_ready                 ),  // input wire s_axi_bready
    
    .s_axi_arid     ( axi_256[0].ar_id                  ),  // input wire [5 : 0] s_axi_arid
    .s_axi_araddr   ( {3'd0, axi_256[0].ar_addr[29:0]}  ),  // input wire [31 : 0] s_axi_araddr
    .s_axi_arlen    ( axi_256[0].ar_len                 ),  // input wire [7 : 0] s_axi_arlen
    .s_axi_arsize   ( axi_256[0].ar_size                ),  // input wire [2 : 0] s_axi_arsize
    .s_axi_arburst  ( axi_256[0].ar_burst               ),  // input wire [1 : 0] s_axi_arburst
    .s_axi_arvalid  ( axi_256[0].ar_valid               ),  // input wire s_axi_arvalid
    .s_axi_arready  ( axi_256[0].ar_ready               ),  // output wire s_axi_arready
    
    .s_axi_rid      ( axi_256[0].r_id                   ),  // output wire [5 : 0] s_axi_rid
    .s_axi_rdata    ( axi_256[0].r_data                 ),  // output wire [255 : 0] s_axi_rdata
    .s_axi_rresp    ( axi_256[0].r_resp                 ),  // output wire [1 : 0] s_axi_rresp
    .s_axi_rlast    ( axi_256[0].r_last                 ),  // output wire s_axi_rlast
    .s_axi_rvalid   ( axi_256[0].r_valid                ),  // output wire s_axi_rvalid
    .s_axi_rready   ( axi_256[0].r_ready                )   // input wire s_axi_rready
);

`endif
endmodule