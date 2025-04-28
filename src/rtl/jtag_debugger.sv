`include "axi/typedef.svh"
`include "axi/assign.svh"

module jtag_debugger (
    // global signals
    input   logic           clk         ,
    input   logic           rst_n       ,
    // jtag signals
    input   logic           tck         ,
    input   logic           tms         ,
    input   logic           trstn       ,
    input   logic           tdi         ,
    output  logic           tdo         ,
    // axi interfaces
    AXI_BUS.Master          master      ,
    AXI_BUS.Slave           slave       ,
    // internal signals
    output  logic           ndmreset    ,
    output  logic           debug_req   
);

localparam dm::hartinfo_t info = '{
    zero1       :   'd0,
    nscratch    :   2,
    zero0       :   'd0,
    dataaccess  :   'd1,
    datasize    :   dm::DataCount,
    dataaddr    :   0'h380
};

localparam config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(ma_cva6_config_pkg::cva6_cfg);
localparam XLEN = CVA6Cfg.XLEN;
localparam AxiNarrowDataWidth = XLEN;
localparam AxiNarrowStrbWidth = AxiNarrowDataWidth / 8;

typedef logic [AxiNarrowDataWidth-1:0]      axi_narrow_data_t;
typedef logic [AxiNarrowStrbWidth-1:0]      axi_narrow_strb_t;
typedef logic [master.AXI_ID_WIDTH-1:0]     axi_id_t;
typedef logic [master.AXI_ADDR_WIDTH-1:0]   axi_addr_t;
typedef logic [master.AXI_USER_WIDTH-1:0]   axi_user_t;

`AXI_TYPEDEF_ALL(master_narrow_axi, axi_addr_t, axi_id_t, axi_narrow_data_t, axi_narrow_strb_t, axi_user_t)


master_narrow_axi_req_t  master_narrow_axi_req  ;
master_narrow_axi_resp_t master_narrow_axi_resp ;

logic           dmi_rst_n       ;
logic           dmi_req_valid   ;
logic           dmi_req_ready   ;
dm::dmi_req_t   dmi_req         ;
logic           dmi_resp_valid  ;
logic           dmi_resp_ready  ;
dm::dmi_resp_t  dmi_resp        ;

logic                       dm_slave_req    ;
logic                       dm_slave_we     ;
logic       [XLEN - 1 : 0]  dm_slave_addr   ;
logic   [XLEN / 8 - 1 : 0]  dm_slave_be     ;
logic       [XLEN - 1 : 0]  dm_slave_wdata  ;
logic       [XLEN - 1 : 0]  dm_slave_rdata  ;

logic                       dm_master_req       ;
logic       [XLEN - 1 : 0]  dm_master_add       ;
logic                       dm_master_we        ;
logic       [XLEN - 1 : 0]  dm_master_wdata     ;
logic   [XLEN / 8 - 1 : 0]  dm_master_be        ;
logic                       dm_master_gnt       ;
logic                       dm_master_r_valid   ;
logic       [XLEN - 1 : 0]  dm_master_r_rdata   ;

logic [1:0]    axi_adapter_size;


AXI_BUS #(
    .AXI_ADDR_WIDTH ( slave.AXI_ADDR_WIDTH  ),
    .AXI_DATA_WIDTH ( XLEN                  ),
    .AXI_ID_WIDTH   ( slave.AXI_ID_WIDTH    ),
    .AXI_USER_WIDTH ( slave.AXI_USER_WIDTH  )
) slave_debugger_axi ();

AXI_BUS #(
    .AXI_ADDR_WIDTH ( master.AXI_ADDR_WIDTH ),
    .AXI_DATA_WIDTH ( XLEN                  ),
    .AXI_ID_WIDTH   ( master.AXI_ID_WIDTH   ),
    .AXI_USER_WIDTH ( master.AXI_USER_WIDTH )
) master_debugger_axi ();

`AXI_ASSIGN_FROM_REQ(master_debugger_axi, master_narrow_axi_req)
`AXI_ASSIGN_TO_RESP(master_narrow_axi_resp, master_debugger_axi)

assign axi_adapter_size = (CVA6Cfg.XLEN == 64) ? 2'b11 : 2'b10;


dmi_jtag #(
    .IdcodeValue    ( 32'hDEADBEEF  )
) (
    .clk_i              ( clk               ),  
    .rst_ni             ( rst_n             ),
    .testmode_i         ( 1'b0              ),
    .dmi_rst_no         ( dmi_rst_n         ),
    .dmi_req_o          ( dmi_req           ),
    .dmi_req_valid_o    ( dmi_req_ready     ),
    .dmi_req_ready_i    ( dmi_req_valid     ),
    .dmi_resp_i         ( dmi_resp          ),
    .dmi_resp_ready_o   ( dmi_resp_ready    ),
    .dmi_resp_valid_i   ( dmi_resp_valid    ),
    .tck_i              ( tck               ),
    .tms_i              ( tms               ),  
    .trst_ni            ( trstn             ),
    .td_i               ( tdi               ),   
    .td_o               ( tdo               ),   
    .tdo_oe_o           (                   ) 
);

dm_top #(
    .BusWidth   ( XLEN  )
) i_dm_top (
    .clk_i                  ( clk               ),
    .rst_ni                 ( rst_n             ),
    .next_dm_addr_i         ( 'd0               ),
    .testmode_i             ( 'd0               ),
    .ndmreset_o             ( ~ndmreset         ), // non-debug module reset
    .ndmreset_ack_i         ( 1'b1              ), // non-debug module reset acknowledgement pulse
    .dmactive_o             ( /*NOT CONNECTED*/ ), // debug module is active
    .debug_req_o            ( debug_req         ), // async debug request
    .unavailable_i          ( 'd0               ),
    .hartinfo_i             ( {info}            ),

    .slave_req_i            ( dm_slave_req      ),
    .slave_we_i             ( dm_slave_we       ),
    .slave_addr_i           ( dm_slave_addr     ),
    .slave_be_i             ( dm_slave_be       ),
    .slave_wdata_i          ( dm_slave_wdata    ),
    .slave_rdata_o          ( dm_slave_rdata    ),

    .master_req_o           ( dm_master_req     ),
    .master_add_o           ( dm_master_add     ),
    .master_we_o            ( dm_master_we      ),
    .master_wdata_o         ( dm_master_wdata   ),
    .master_be_o            ( dm_master_be      ),
    .master_gnt_i           ( dm_master_gnt     ),
    .master_r_valid_i       ( dm_master_r_valid ),
    .master_r_rdata_i       ( dm_master_r_rdata ),
    .master_r_err_i         ( 'd0               ),
    .master_r_other_err_i   ( 'd0               ),

    .dmi_rst_ni             ( dmi_rst_n         ),
    .dmi_req_valid_i        ( dmi_req_valid     ),
    .dmi_req_ready_o        ( dmi_req_ready     ),
    .dmi_req_i              ( dmi_req           ),
    .dmi_resp_valid_o       ( dmi_resp_valid    ),
    .dmi_resp_ready_i       ( dmi_resp_ready    ),
    .dmi_resp_o             ( dmi_resp          )
);

axi_to_mem_intf #(
    .ADDR_WIDTH ( slave.AXI_ADDR_WIDTH  ),
    .DATA_WIDTH ( XLEN                  ),
    .ID_WIDTH   ( slave.AXI_ID_WIDTH    ),
    .USER_WIDTH ( slave.AXI_USER_WIDTH  )
) i_slave_dm_axi_adapter (
    .clk_i          ( clk               ),
    .rst_ni         ( rst_n             ),
    .slv            ( slave_debugger_axi),
    .mem_req_o      ( dm_slave_req      ),
    .mem_gnt_i      ( dm_slave_req      ),
    .mem_addr_o     ( dm_slave_addr     ),
    .mem_wdata_o    ( dm_slave_wdata    ),
    .mem_strb_o     ( dm_slave_be       ),
    .mem_we_o       ( dm_slave_we       ),
    .mem_rvalid_i   ( dm_slave_req      ),
    .mem_rdata_i    ( dm_slave_rdata    ),
    .busy_o         ( /* Unused */      ),
    .mem_atop_o     ( /* Unused */      )
);

axi_dw_converter_intf #(
    .AXI_ID_WIDTH           ( slave.AXI_ID_WIDTH    ),
    .AXI_ADDR_WIDTH         ( slave.AXI_ADDR_WIDTH  ),
    .AXI_SLV_PORT_DATA_WIDTH( slave.AXI_DATA_WIDTH  ),
    .AXI_MST_PORT_DATA_WIDTH( XLEN                  ),
    .AXI_USER_WIDTH         ( slave.AXI_USER_WIDTH  ),
    .AXI_MAX_READS          ( 1                     )
) i_slave_dm_axi_dw (
    .clk_i  ( clk               ),
    .rst_ni ( rst_n             ),
    .slv    ( slave             ),
    .mst    ( slave_debugger_axi)
);

axi_adapter #(
    .CVA6Cfg               ( CVA6Cfg                    ),
    .DATA_WIDTH            ( XLEN                       ),
    .axi_req_t             ( master_narrow_axi_req_t    ),
    .axi_rsp_t             ( master_narrow_axi_resp_t   )
) i_master_dm_axi_adapter (
    .clk_i                 ( clk                    ),
    .rst_ni                ( rst_n                  ),
    .req_i                 ( dm_master_req          ),
    .type_i                ( ariane_pkg::SINGLE_REQ ),
    .amo_i                 ( ariane_pkg::AMO_NONE   ),
    .gnt_o                 ( dm_master_gnt          ),
    .addr_i                ( dm_master_add          ),
    .we_i                  ( dm_master_we           ),
    .wdata_i               ( dm_master_wdata        ),
    .be_i                  ( dm_master_be           ),
    .size_i                ( axi_adapter_size       ),
    .id_i                  ( '0                     ),
    .valid_o               ( dm_master_r_valid      ),
    .rdata_o               ( dm_master_r_rdata      ),
    .id_o                  (                        ),
    .critical_word_o       (                        ),
    .critical_word_valid_o (                        ),
    .axi_req_o             ( master_narrow_axi_req  ),
    .axi_resp_i            ( master_narrow_axi_resp )
);

axi_dw_converter_intf #(
    .AXI_ID_WIDTH           ( master.AXI_ID_WIDTH   ),
    .AXI_ADDR_WIDTH         ( master.AXI_ADDR_WIDTH ),
    .AXI_SLV_PORT_DATA_WIDTH( XLEN                  ),
    .AXI_MST_PORT_DATA_WIDTH( master.AXI_DATA_WIDTH ),
    .AXI_USER_WIDTH         ( master.AXI_USER_WIDTH ),
    .AXI_MAX_READS          ( 1                     )
) i_master_dm_axi_dw (
    .clk_i  ( clk               ),
    .rst_ni ( rst_n             ),
    .slv    (master_debugger_axi),
    .mst    ( master            )
);

endmodule