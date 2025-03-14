module matrix_accelerator_soc (
    input   clk     ,
    input   rst_n   
);
    
// Local Parameters -----------------------------------------------------------
localparam AXI_NO_MASTERS = 2;
localparam AXI_NO_SLAVES = 1;

localparam AXI_DATA_WIDTH = 128;
localparam AXI_STROBE_WIDTH = AXI_DATA_WIDTH / 8;
localparam AXI_ADDR_WIDTH = 32;
localparam AXI_USER_WIDTH = 4;
localparam AXI_ID_WIDTH = 5;
localparam AXI_ID_WIDTH_SLAVE = AXI_ID_WIDTH + $clog2(AXI_NO_MASTERS);

localparam RAM_LENGTH = 32'h4000_0000;
localparam RAM_WORDS = RAM_LENGTH / AXI_DATA_WIDTH;

localparam axi_pkg::xbar_cfg_t xbar_cfg = '{
    NoSlvPorts:         AXI_NO_MASTERS,
    NoMstPorts:         AXI_NO_SLAVES,
    MaxMstTrans:        4,
    MaxSlvTrans:        4,
    FallThrough:        1'b0,
    LatencyMode:        axi_pkg::CUT_MST_PORTS,
    PipelineStages:     0,
    AxiIdWidthSlvPorts: AXI_ID_WIDTH,
    AxiIdUsedSlvPorts:  AXI_ID_WIDTH_SLAVE,
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

typedef enum int unsigned {
    RAM 
} axi_slaves_e;

typedef enum logic [32:0] {
    RAM_BASE = 32'h0000_0000,
} soc_bus_start_e;


// Wires ----------------------------------------------------------------------
logic                               ram_req;
logic                               ram_we;
logic [AXI_ADDR_WIDTH - 1 : 0]      ram_addr;
logic [AXI_DATA_WIDTH / 8 - 1 : 0]  ram_be;
logic [AXI_DATA_WIDTH - 1 : 0]      ram_wdata;
logic [AXI_DATA_WIDTH - 1 : 0]      ram_rdata;
logic                               ram_rvalid;

AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH      ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH      ),
    .AXI_ID_WIDTH   ( TbAxiIdWidthMasters ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH      )
) master [AXI_NO_MASTERS-1:0] ();
AXI_BUS #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH     ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH     ),
    .AXI_ID_WIDTH   ( TbAxiIdWidthSlaves ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH     )
) slave [AXI_NO_SLAVES-1:0] ();
axi_pkg::xbar_rule_32_t [AXI_NO_SLAVES - 1 : 0] routing_rules;


// Combinatorial Logic --------------------------------------------------------
assign routing_rules = '{
    '{idx: RAM, start_addr: RAM_BASE, end_addr: RAM_BASE + RAM_LENGTH}
};


// Modules Instantiation ------------------------------------------------------


// axi interconnect
axi_xbar_intf #(
    .AXI_USER_WIDTH ( AXI_USER_WIDTH            ),
    .Cfg            ( xbar_cfg                  ),
    .rule_t         ( axi_pkg::xbar_rule_32_t   )
) i_xbar_dut (
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
axi_to_mem_intf #(
    .ADDR_WIDTH ( AXI_ADDR_WIDTH    ),
    .DATA_WIDTH ( AXI_DATA_WIDTH    ),
    .ID_WIDTH   ( AXI_ID_WIDTH_SLAVE),
    .USER_WIDTH ( AXI_USER_WIDTH    ),
    .NUM_BANKS  ( 1                 ),
) i_axi_to_mem (
    .clk_i          ( clk           ),
    .rst_ni         ( rst_n         ),
    .slv            ( slave[RAM]    ),
    .mem_req_o      ( ram_req       ),
    .mem_gnt_i      ( ram_req       ),
    .mem_addr_o     ( ram_we        ),
    .mem_wdata_o    ( ram_addr      ),
    .mem_strb_o     ( ram_be        ),
    .mem_we_o       ( ram_wdata     ),
    .mem_rvalid_i   ( ram_rdata     ),
    .mem_rdata_i    ( ram_rvalid    ),
    .busy_o         ( /* Unused */  ),
    .mem_atop_o     ( /* Unused */  ),
);

tc_sram #(
    .NumWords ( RAM_WORDS       ),
    .NumPorts ( 1               ),
    .DataWidth( AXI_DATA_WIDTH  ),
    .SimInit("random")
) i_dram (
    .clk_i  (clk_i                                                                          ),
    .rst_ni (rst_ni                                                                         ),
    .req_i  (ram_req                                                                        ),
    .we_i   (ram_we                                                                         ),
    .addr_i (ram_addr[$clog2(RAM_WORDS)-1+$clog2(AXI_DATA_WIDTH/8):$clog2(AXI_DATA_WIDTH/8)]),
    .wdata_i(ram_wdata                                                                      ),
    .be_i   (ram_be                                                                         ),
    .rdata_o(ram_rdata                                                                      )
);

endmodule