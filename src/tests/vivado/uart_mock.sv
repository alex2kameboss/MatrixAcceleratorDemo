// TODO: Handle invalid addr

module uart_mock (
    input           clk     ,
    input           rst_n   ,
    AXI_LITE.Slave  axi     ,
    output          tx      ,
    input           rx           
);

xilinx_uart i_real_uart (
    .s_axi_aclk     ( clk               ),  // input wire s_axi_aclk
    .s_axi_aresetn  ( rst_n             ),  // input wire s_axi_aresetn
    .interrupt      (                   ),  // output wire interrupt
    .s_axi_awaddr   ( axi.aw_addr[3 : 0]),  // input wire [3 : 0] s_axi_awaddr
    .s_axi_awvalid  ( axi.aw_valid      ),  // input wire s_axi_awvalid
    .s_axi_awready  ( axi.aw_ready      ),  // output wire s_axi_awready
    .s_axi_wdata    ( axi.w_data        ),  // input wire [31 : 0] s_axi_wdata
    .s_axi_wstrb    ( axi.w_strb        ),  // input wire [3 : 0] s_axi_wstrb
    .s_axi_wvalid   ( axi.w_valid       ),  // input wire s_axi_wvalid
    .s_axi_wready   ( axi.w_ready       ),  // output wire s_axi_wready
    .s_axi_bresp    ( axi.b_resp        ),  // output wire [1 : 0] s_axi_bresp
    .s_axi_bvalid   ( axi.b_valid       ),  // output wire s_axi_bvalid
    .s_axi_bready   ( axi.b_ready       ),  // input wire s_axi_bready
    .s_axi_araddr   ( axi.ar_addr       ),  // input wire [3 : 0] s_axi_araddr
    .s_axi_arvalid  ( axi.ar_valid      ),  // input wire s_axi_arvalid
    .s_axi_arready  ( s_axi_arready     ),  // output wire s_axi_arready
    .s_axi_rdata    ( axi.r_data        ),  // output wire [31 : 0] s_axi_rdata
    .s_axi_rresp    ( axi.r_resp        ),  // output wire [1 : 0] s_axi_rresp
    .s_axi_rvalid   ( axi.r_valid       ),  // output wire s_axi_rvalid
    .s_axi_rready   ( axi.r_ready       ),  // input wire s_axi_rready
    .rx             ( rx                ),  // input wire rx
    .tx             ( tx                )   // output wire tx
);

endmodule