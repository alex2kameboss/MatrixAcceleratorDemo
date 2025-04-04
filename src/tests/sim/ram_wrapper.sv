`include "soc_parameters.svh"

module ram_wrapper (
    input           clk     ,
    input           rst_n   ,
    AXI_BUS.Slave   axi        
);

localparam AXI_STROBE_WIDTH = axi.AXI_DATA_WIDTH / 8;
localparam RAM_LENGTH = `SOC_RAM_LENGTH;
localparam RAM_WORDS = RAM_LENGTH / AXI_STROBE_WIDTH;

logic                                   ram_req;
logic                                   ram_we;
logic [axi.AXI_ADDR_WIDTH - 1 : 0]      ram_addr;
logic [axi.AXI_DATA_WIDTH / 8 - 1 : 0]  ram_be;
logic [axi.AXI_DATA_WIDTH - 1 : 0]      ram_wdata;
logic [axi.AXI_DATA_WIDTH - 1 : 0]      ram_rdata;
logic                                   ram_rvalid;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )           ram_rvalid <= 'd0;          else
                            ram_rvalid <= ram_req;

axi_to_mem_intf #(
    .ADDR_WIDTH ( axi.AXI_ADDR_WIDTH    ),
    .DATA_WIDTH ( axi.AXI_DATA_WIDTH    ),
    .ID_WIDTH   ( axi.AXI_ID_WIDTH      ),
    .USER_WIDTH ( axi.AXI_USER_WIDTH    ),
    .NUM_BANKS  ( 1                     )
) i_axi_to_mem (
    .clk_i          ( clk           ),
    .rst_ni         ( rst_n         ),
    .slv            ( axi           ),
    .mem_req_o      ( ram_req       ),
    .mem_gnt_i      ( ram_req       ),
    .mem_addr_o     ( ram_addr      ),
    .mem_wdata_o    ( ram_wdata     ),
    .mem_strb_o     ( ram_be        ),
    .mem_we_o       ( ram_we        ),
    .mem_rvalid_i   ( ram_rvalid    ),
    .mem_rdata_i    ( ram_rdata     ),
    .busy_o         ( /* Unused */  ),
    .mem_atop_o     ( /* Unused */  )
);

tc_sram #(
    .NumWords   ( RAM_WORDS         ),
    .NumPorts   ( 1                 ),
    .DataWidth  ( axi.AXI_DATA_WIDTH),
    .SimInit    ( "random"          )
) i_dram (
    .clk_i  (clk                                                                                    ),
    .rst_ni (rst_n                                                                                  ),
    .req_i  (ram_req                                                                                ),
    .we_i   (ram_we                                                                                 ),
    .addr_i (ram_addr[$clog2(RAM_WORDS)-1+$clog2(axi.AXI_DATA_WIDTH/8):$clog2(axi.AXI_DATA_WIDTH/8)]),
    .wdata_i(ram_wdata                                                                              ),
    .be_i   (ram_be                                                                                 ),
    .rdata_o(ram_rdata                                                                              )
);

endmodule