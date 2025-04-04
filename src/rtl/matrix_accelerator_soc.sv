`include "soc_parameters.svh"
`include "axi/typedef.svh"

module matrix_accelerator_soc (
    input           clk     ,
    input           rst_n   ,
    output          tx      ,
    input           rx      
);

typedef enum int unsigned {
    RAM             ,
    UART            ,
    CTRL            ,
    AXI_NO_SLAVES   
} axi_slaves_e;

// Local Parameters -----------------------------------------------------------
localparam COUNTER_WIDTH = 64;
localparam COUNTER_WIDTH_BYTES = COUNTER_WIDTH / 8;
localparam AXI_NO_MASTERS = 2;

localparam AXI_DATA_WIDTH   = `SOC_AXI_DATA_WIDTH;
localparam AXI_STROBE_WIDTH = AXI_DATA_WIDTH / 8;
localparam AXI_ADDR_WIDTH   = `SOC_AXI_ADDR_WIDTH;
localparam AXI_USER_WIDTH   = `SOC_AXI_USER_WIDTH;
localparam AXI_ID_WIDTH     = `SOC_AXI_ID_WIDTH;
localparam AXI_ID_WIDTH_SLAVE = AXI_ID_WIDTH + $clog2(AXI_NO_MASTERS);
localparam AXI_UART_DATA_WIDTH = 32;

localparam RAM_LENGTH = `SOC_RAM_LENGTH;
localparam UART_LENGTH = `SOC_UART_LENGTH;
localparam CTRL_LENGTH = `SOC_CTRL_REG_LENGTH;

localparam axi_pkg::xbar_cfg_t xbar_cfg = '{
    NoSlvPorts:         AXI_NO_MASTERS,
    NoMstPorts:         AXI_NO_SLAVES,
    MaxMstTrans:        4,
    MaxSlvTrans:        4,
    FallThrough:        1'b0,
    LatencyMode:        axi_pkg::CUT_MST_PORTS,
    PipelineStages:     0,
    AxiIdWidthSlvPorts: AXI_ID_WIDTH,
    AxiIdUsedSlvPorts:  AXI_ID_WIDTH,
    UniqueIds:          1'b0,
    AxiAddrWidth:       AXI_ADDR_WIDTH,
    AxiDataWidth:       AXI_DATA_WIDTH,
    NoAddrRules:        AXI_NO_SLAVES
};


// Data Types Definition ------------------------------------------------------
typedef logic [AXI_DATA_WIDTH-1:0] axi_data_t;
typedef logic [AXI_STROBE_WIDTH-1:0] axi_strobe_t;
typedef logic [AXI_ADDR_WIDTH-1:0] axi_addr_t;
typedef logic [AXI_ID_WIDTH-1:0] axi_master_id_t;
typedef logic [AXI_ID_WIDTH_SLAVE-1:0] axi_slave_id_t;
typedef logic [AXI_USER_WIDTH-1:0] axi_user_t;

`AXI_TYPEDEF_ALL(master_axi, axi_addr_t, axi_master_id_t, axi_data_t, axi_strobe_t, axi_user_t)
`AXI_TYPEDEF_ALL(slave_axi, axi_addr_t, axi_slave_id_t, axi_data_t, axi_strobe_t, axi_user_t)

typedef enum logic [`SOC_AXI_ADDR_WIDTH - 1 : 0] {
    RAM_BASE  = `SOC_RAM_BASE       ,
    UART_BASE = `SOC_UART_BASE      ,
    CTRL_BASE = `SOC_CTRL_REG_BASE  
} soc_bus_start_e;


// Wires ----------------------------------------------------------------------
AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH    ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH    ),
    .AXI_ID_WIDTH   ( AXI_ID_WIDTH      ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH    )
) master [AXI_NO_MASTERS-1:0] ();
AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH        ),
    .AXI_ID_WIDTH   ( AXI_ID_WIDTH_SLAVE    ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH        )
) slave [AXI_NO_SLAVES-1:0] ();
axi_pkg::xbar_rule_64_t [AXI_NO_SLAVES - 1 : 0] routing_rules;

// uart
AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_UART_DATA_WIDTH   ),
    .AXI_ID_WIDTH   ( AXI_ID_WIDTH_SLAVE    ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH        )
) uart_axi ();
AXI_LITE #(
  .AXI_ADDR_WIDTH   ( AXI_ADDR_WIDTH        ),
  .AXI_DATA_WIDTH   ( AXI_UART_DATA_WIDTH   )
) uart_axi_lite ();

// ctrl
AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_UART_DATA_WIDTH   ),
    .AXI_ID_WIDTH   ( AXI_ID_WIDTH_SLAVE    ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH        )
) ctrl_axi ();
AXI_LITE #(
  .AXI_ADDR_WIDTH   ( AXI_ADDR_WIDTH        ),
  .AXI_DATA_WIDTH   ( AXI_UART_DATA_WIDTH   )
) ctrl_axi_lite ();

logic [CTRL_LENGTH - 1 : 0][7 : 0] ctrl_out;
wor [CTRL_LENGTH - 1 : 0][7 : 0] ctrl_in;

// Combinatorial Logic --------------------------------------------------------
assign routing_rules = '{
    '{idx: RAM , start_addr: RAM_BASE , end_addr: RAM_BASE + RAM_LENGTH  },
    '{idx: UART, start_addr: UART_BASE, end_addr: UART_BASE + UART_LENGTH},
    '{idx: CTRL, start_addr: CTRL_BASE, end_addr: CTRL_BASE + CTRL_LENGTH}
};

assign ctrl_in = '0;


// Sequential Logic -----------------------------------------------------------


// Modules Instantiation ------------------------------------------------------
matrix_accelerator_subsystem  i_core (
    .clk         ( clk      ),
    .rst_n       ( rst_n    ),
    .boot_addr   ( RAM_BASE ),
    .core_axi    ( master[0]),
    .acc_axi     ( master[1])
);

// axi interconnect
axi_xbar_intf #(
    .AXI_USER_WIDTH ( AXI_USER_WIDTH            ),
    .Cfg            ( xbar_cfg                  ),
    .rule_t         ( axi_pkg::xbar_rule_64_t   )
) i_xbar (
    .clk_i                  ( clk           ),
    .rst_ni                 ( rst_n         ),
    .test_i                 ( 1'b0          ),
    .slv_ports              ( master        ),
    .mst_ports              ( slave         ),
    .addr_map_i             ( routing_rules ),
    .en_default_mst_port_i  ( '0            ),
    .default_mst_port_i     ( '0            )
);

// memory
ram_wrapper i_ram (
    .clk    ( clk           ),
    .rst_n  ( rst_n         ),
    .axi    ( slave[RAM]    )   
);

// uart
axi_dw_converter_intf #(
    .AXI_ID_WIDTH           ( AXI_ID_WIDTH_SLAVE    ),
    .AXI_ADDR_WIDTH         ( AXI_ADDR_WIDTH        ),
    .AXI_SLV_PORT_DATA_WIDTH( AXI_DATA_WIDTH        ),
    .AXI_MST_PORT_DATA_WIDTH( AXI_UART_DATA_WIDTH   ),
    .AXI_USER_WIDTH         ( AXI_USER_WIDTH        ),
    .AXI_MAX_READS          ( 1                     )
) i_uart_axi_dw (
    .clk_i  ( clk           ),
    .rst_ni ( rst_n         ),
    .slv    ( slave[UART]   ),
    .mst    ( uart_axi      )
);

axi_to_axi_lite_intf #(
    .AXI_ADDR_WIDTH     ( AXI_ADDR_WIDTH    ),
    .AXI_DATA_WIDTH     (AXI_UART_DATA_WIDTH),
    .AXI_ID_WIDTH       ( AXI_ID_WIDTH_SLAVE),
    .AXI_USER_WIDTH     ( AXI_USER_WIDTH    ),
    .AXI_MAX_WRITE_TXNS ( 1                 ),
    .AXI_MAX_READ_TXNS  ( 1                 ),
    .FALL_THROUGH       ( 1'b0              )
) i_uart_axi_to_lite (
    .clk_i      ( clk           ),
    .rst_ni     ( rst_n         ),
    .testmode_i ( '0            ),
    .slv        ( uart_axi      ),
    .mst        ( uart_axi_lite )
);

uart_mock i_uart (
    .clk    ( clk           ),
    .rst_n  ( rst_n         ),
    .axi    ( uart_axi_lite ),
    .tx     ( tx            ),
    .rx     ( rx            )
);

// ctrl
axi_dw_converter_intf #(
    .AXI_ID_WIDTH           ( AXI_ID_WIDTH_SLAVE    ),
    .AXI_ADDR_WIDTH         ( AXI_ADDR_WIDTH        ),
    .AXI_SLV_PORT_DATA_WIDTH( AXI_DATA_WIDTH        ),
    .AXI_MST_PORT_DATA_WIDTH( AXI_UART_DATA_WIDTH   ),
    .AXI_USER_WIDTH         ( AXI_USER_WIDTH        ),
    .AXI_MAX_READS          ( 1                     )
) i_ctrl_axi_dw (
    .clk_i  ( clk           ),
    .rst_ni ( rst_n         ),
    .slv    ( slave[CTRL]   ),
    .mst    ( ctrl_axi      )
);

axi_to_axi_lite_intf #(
    .AXI_ADDR_WIDTH     ( AXI_ADDR_WIDTH    ),
    .AXI_DATA_WIDTH     (AXI_UART_DATA_WIDTH),
    .AXI_ID_WIDTH       ( AXI_ID_WIDTH_SLAVE),
    .AXI_USER_WIDTH     ( AXI_USER_WIDTH    ),
    .AXI_MAX_WRITE_TXNS ( 1                 ),
    .AXI_MAX_READ_TXNS  ( 1                 ),
    .FALL_THROUGH       ( 1'b0              )
) i_ctrl_axi_to_lite (
    .clk_i      ( clk           ),
    .rst_ni     ( rst_n         ),
    .testmode_i ( '0            ),
    .slv        ( ctrl_axi      ),
    .mst        ( ctrl_axi_lite )
);

axi_lite_regs_intf #(
    .REG_NUM_BYTES  ( CTRL_LENGTH       ),
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH    ),
    .AXI_DATA_WIDTH (AXI_UART_DATA_WIDTH)
) i_ctrl_regs (
    .clk_i      ( clk           ),
    .rst_ni     ( rst_n         ),
    .slv        ( ctrl_axi_lite ),
    .wr_active_o(               ),
    .rd_active_o(               ),
    .reg_d_i    ( ctrl_in       ),
    .reg_load_i ( {{COUNTER_WIDTH_BYTES{1'b1}}, {(CTRL_LENGTH - COUNTER_WIDTH_BYTES){1'b0}}}            ),
    .reg_q_o    ( ctrl_out      )
);

// config timer byte 1
// values timer bytes 15 : 8

metrics_counter #(
    .COUNTER_WIDTH  ( COUNTER_WIDTH )
) i_metrics_counter (
    .clk    ( clk                                               ),
    .rst_n  ( rst_n                                             ),
    .en     ( ctrl_out[1][0]                                    ),
    .clear  ( ctrl_out[1][1]                                    ),
    .cnt    ( {ctrl_in[CTRL_LENGTH - 1 -: COUNTER_WIDTH_BYTES]} )
);

endmodule