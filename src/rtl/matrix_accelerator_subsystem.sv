`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "cva6_parameters.svh"
`include "ma_cvxif_types.svh"

module matrix_accelerator_subsystem #(
    parameter PRF_LOG_P =   1   ,
    parameter PRF_LOG_Q =   2   ,
    parameter PRF_LOG_N =   10  ,
    parameter PRF_LOG_M =   10  
) (
    input                                       clk         ,
    input                                       clk_2x      ,
    input                                       rst_n       ,
    input logic [`CVA6_AXI_ADDR_WIDTH - 1 : 0]  boot_addr   ,
    input logic                                 debug_req   ,
    // core axi
    AXI_BUS.Master                              core_axi    ,
    // accelerator axi
    AXI_BUS.Master                              acc_axi     
);

// Local Parameters -----------------------------------------------------------
localparam config_pkg::cva6_cfg_t CVA6Cfg = build_config_pkg::build_config(ma_cva6_config_pkg::cva6_cfg);
localparam AxiNarrowDataWidth = ma_cva6_config_pkg::cva6_cfg.AxiDataWidth;
localparam AxiNarrowStrbWidth = AxiNarrowDataWidth / 8;
localparam AxiWideDataWidth   = core_axi.AXI_DATA_WIDTH;
localparam AXiWideStrbWidth   = AxiWideDataWidth / 8;


// Data Types Definition ------------------------------------------------------
typedef logic [AxiNarrowDataWidth-1:0]      axi_narrow_data_t;
typedef logic [AxiNarrowStrbWidth-1:0]      axi_narrow_strb_t;
typedef logic [AxiWideDataWidth-1:0]        axi_wide_data_t;
typedef logic [AXiWideStrbWidth-1:0]        axi_wide_strb_t;
typedef logic [core_axi.AXI_ID_WIDTH-1:0]   axi_id_t;
typedef logic [core_axi.AXI_ADDR_WIDTH-1:0] axi_addr_t;
typedef logic [core_axi.AXI_USER_WIDTH-1:0] axi_user_t;

`AXI_TYPEDEF_ALL(core_wide_axi, axi_addr_t, axi_id_t, axi_wide_data_t, axi_wide_strb_t, axi_user_t)
`AXI_TYPEDEF_ALL(core_narrow_axi, axi_addr_t, axi_id_t, axi_narrow_data_t, axi_narrow_strb_t, axi_user_t)

typedef `MA_READREGFLAGS_T(CVA6Cfg) xif_readregflags_t;
typedef `MA_WRITEREGFLAGS_T(CVA6Cfg) xif_writeregflags_t;
typedef `MA_ID_T(CVA6Cfg) xif_id_t;
typedef `MA_HARTID_T(CVA6Cfg) xif_hartid_t;
typedef `MA_X_COMPRESSED_REQ_T(CVA6Cfg, xif_hartid_t) xif_compressed_req_t;
typedef `MA_X_COMPRESSED_RESP_T(CVA6Cfg) xif_compressed_resp_t;
typedef `MA_X_ISSUE_REQ_T(CVA6Cfg, xif_hartid_t, xif_id_t) xif_issue_req_t;
typedef `MA_X_ISSUE_RESP_T(CVA6Cfg, xif_writeregflags_t, xif_readregflags_t) xif_issue_resp_t;
typedef `MA_X_REGISTER_T(CVA6Cfg, xif_hartid_t, xif_id_t, xif_readregflags_t) xif_register_req_t;
typedef `MA_X_COMMIT_T(CVA6Cfg, xif_hartid_t, xif_id_t) xif_commit_t;
typedef `MA_X_RESULT_T(CVA6Cfg, xif_hartid_t, xif_id_t, xif_writeregflags_t) xif_result_t;
typedef `MA_CVXIF_REQ_T(CVA6Cfg, xif_compressed_req_t, xif_issue_req_t, xif_register_req_t, xif_commit_t) xif_req_t;
typedef `MA_CVXIF_RESP_T(CVA6Cfg, xif_compressed_resp_t, xif_issue_resp_t, xif_result_t) xif_resp_t;


// Wires ----------------------------------------------------------------------
core_wide_axi_req_t  core_wide_axi_req;
core_wide_axi_resp_t core_wide_axi_resp;
core_narrow_axi_req_t  core_narrow_axi_req;
core_narrow_axi_resp_t core_narrow_axi_resp;
xif_req_t xif_req;
xif_resp_t xif_resp;

core_v_xif #(
    .X_NUM_RS              ( CVA6Cfg.X_NUM_RS               ),
    .X_ID_WIDTH            ( CVA6Cfg.X_ID_WIDTH             ),
    .X_RFR_WIDTH           ( CVA6Cfg.X_RFR_WIDTH            ),
    .X_RFW_WIDTH           ( CVA6Cfg.X_RFW_WIDTH            ),
    .X_NUM_HARTS           ( CVA6Cfg.X_NUM_HARTS            ),
    .X_HARTID_WIDTH        ( CVA6Cfg.X_HARTID_WIDTH         ),
    .X_MISA                ( 'd0                            ),
    .X_DUALREAD            ( CVA6Cfg.X_DUALREAD             ),
    .X_DUALWRITE           ( CVA6Cfg.X_DUALWRITE            ),
    .X_ISSUE_REGISTER_SPLIT( CVA6Cfg.X_ISSUE_REGISTER_SPLIT ),
    .X_MEM_WIDTH           ( CVA6Cfg.AxiDataWidth           ) 
) xif ();


// Combinatorial Logic --------------------------------------------------------
`AXI_ASSIGN_FROM_REQ(core_axi, core_wide_axi_req)
`AXI_ASSIGN_TO_RESP(core_wide_axi_resp, core_axi)

// connect xif
    // req
assign xif.compressed_valid = xif_req.compressed_valid;
assign xif.compressed_req = xif_req.compressed_req;
assign xif.issue_valid = xif_req.issue_valid;
assign xif.issue_req = xif_req.issue_req;
assign xif.register_valid = xif_req.register_valid;
assign xif.register = xif_req.register;
assign xif.commit_valid = xif_req.commit_valid;
assign xif.commit = xif_req.commit;
assign xif.result_ready = xif_req.result_ready;
    // resp
assign xif_resp.compressed_ready = xif.compressed_ready;
assign xif_resp.compressed_resp = xif.compressed_resp;
assign xif_resp.issue_ready = xif.issue_ready;
assign xif_resp.issue_resp = xif.issue_resp;
assign xif_resp.register_ready = xif.register_ready;
assign xif_resp.result_valid = xif.result_valid;
assign xif_resp.result = xif.result;


// Modules Instantiation ------------------------------------------------------
cva6 #(
    .CVA6Cfg                ( CVA6Cfg                   ),
    .axi_ar_chan_t          ( core_narrow_axi_ar_chan_t ),
    .axi_aw_chan_t          ( core_narrow_axi_aw_chan_t ),
    .axi_w_chan_t           ( core_narrow_axi_w_chan_t  ),
    .b_chan_t               ( core_narrow_axi_b_chan_t  ),
    .r_chan_t               ( core_narrow_axi_r_chan_t  ),    
    .noc_req_t              ( core_narrow_axi_req_t     ),
    .noc_resp_t             ( core_narrow_axi_resp_t    ),
    .readregflags_t         ( xif_readregflags_t        ),
    .writeregflags_t        ( xif_writeregflags_t       ),
    .id_t                   ( xif_id_t                  ),
    .hartid_t               ( xif_hartid_t              ),
    .x_compressed_req_t     ( xif_compressed_req_t      ),
    .x_compressed_resp_t    ( xif_compressed_resp_t     ),
    .x_issue_req_t          ( xif_issue_req_t           ),
    .x_issue_resp_t         ( xif_issue_resp_t          ),
    .x_register_t           ( xif_register_req_t        ),
    .x_commit_t             ( xif_commit_t              ),
    .x_result_t             ( xif_result_t              ),
    .cvxif_req_t            ( xif_req_t                 ),
    .cvxif_resp_t           ( xif_resp_t                )
) i_cva6_core (
    .clk_i          ( clk                   ),
    .rst_ni         ( rst_n                 ),
    .boot_addr_i    ( boot_addr             ),
    .hart_id_i      ( '0                    ),
    .irq_i          ( '0                    ),
    .ipi_i          ( '0                    ),
    .time_irq_i     ( '0                    ),
    .debug_req_i    ( debug_req             ),
    .rvfi_probes_o  ( /* empty */           ),
    .cvxif_req_o    ( xif_req               ),
    .cvxif_resp_i   ( xif_resp              ),
    .noc_req_o      ( core_narrow_axi_req   ),
    .noc_resp_i     ( core_narrow_axi_resp  )
  );

matrix_accelerator #(
    .OPCODE             ( 7'h2B                 ),
    .ADDR_WIDTH         ( `CVA6_AXI_ADDR_WIDTH  ),
    .REGISTER_NUMBERS   ( 32                    ),
    .PRF_LOG_P          ( PRF_LOG_P             ),
    .PRF_LOG_Q          ( PRF_LOG_Q             ),
    .PRF_LOG_N          ( PRF_LOG_N             ),
    .PRF_LOG_M          ( PRF_LOG_M             )
) i_matrix_accelerator (
    .clk             ( clk      ),
    .clk_2x          ( clk_2x   ),
    .rst_n           ( rst_n    ),
    .instr_if        ( xif      ),
    .registers_if    ( xif      ),
    .commit_if       ( xif      ),
    .result_if       ( xif      ),
    .aclk            ( clk      ),
    .arst_n          ( rst_n    ),
    .axi             ( acc_axi  )
);

axi_dw_converter #(
    .AxiSlvPortDataWidth    ( AxiNarrowDataWidth        ),
    .AxiMstPortDataWidth    ( core_axi.AXI_DATA_WIDTH   ),
    .AxiAddrWidth           ( core_axi.AXI_ADDR_WIDTH   ),
    .AxiIdWidth             ( core_axi.AXI_ID_WIDTH     ),
    .AxiMaxReads            ( 2                         ),
    .ar_chan_t              ( core_narrow_axi_ar_chan_t ),
    .mst_r_chan_t           ( core_wide_axi_r_chan_t    ),
    .slv_r_chan_t           ( core_narrow_axi_r_chan_t  ),
    .aw_chan_t              ( core_narrow_axi_aw_chan_t ),
    .b_chan_t               ( core_narrow_axi_b_chan_t  ),
    .mst_w_chan_t           ( core_wide_axi_w_chan_t    ),
    .slv_w_chan_t           ( core_narrow_axi_w_chan_t  ),
    .axi_mst_req_t          ( core_wide_axi_req_t       ),
    .axi_mst_resp_t         ( core_wide_axi_resp_t      ),
    .axi_slv_req_t          ( core_narrow_axi_req_t     ),
    .axi_slv_resp_t         ( core_narrow_axi_resp_t    )
) i_core_axi_dwc (
    .clk_i      ( clk                   ),
    .rst_ni     ( rst_n                 ),
    .slv_req_i  ( core_narrow_axi_req   ),
    .slv_resp_o ( core_narrow_axi_resp  ),
    .mst_req_o  ( core_wide_axi_req     ),
    .mst_resp_i ( core_wide_axi_resp    )
);

endmodule