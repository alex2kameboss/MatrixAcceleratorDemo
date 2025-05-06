`timescale 1ns/1ns

module jtag_dpi_test();

localparam dm::hartinfo_t info = '{
    zero1       :   'd0,
    nscratch    :   2,
    zero0       :   'd0,
    dataaccess  :   'd1,
    datasize    :   dm::DataCount,
    dataaddr    :   dm::DataAddr
};

logic clk  ;
logic rst_n;
logic tck  ;
logic tms  ;
logic trstn;
logic tdi  ;
logic tdo  ;
logic [31:0] jtag_exit;

logic           dmi_rst_n       ;
logic           dmi_req_valid   ;
logic           dmi_req_ready   ;
dm::dmi_req_t   dmi_req         ;
logic           dmi_resp_valid  ;
logic           dmi_resp_ready  ;
dm::dmi_resp_t  dmi_resp        ;

initial begin
    clk = 1'b1;
    forever #5 clk = ~clk;
end

initial begin
    rst_n = 1'b0;
    repeat(5) @(negedge clk);
    rst_n = 1'b1;
end

SimJTAG #(
    .TICK_DELAY ( 1     ),
    .PORT       ( 9999  )
) i_jtag (
    .clock          ( clk           ),
    .reset          ( ~rst_n        ),
    .enable         ( 1'b1          ),
    .init_done      ( rst_n         ),
    .jtag_TCK       ( tck           ),
    .jtag_TMS       ( tms           ),
    .jtag_TDI       ( tdi           ),
    .jtag_TRSTn     ( trstn         ),
    .jtag_TDO_data  ( tdo           ),
    .jtag_TDO_driven( 1'b1          ),
    .exit           ( jtag_exit     )
);

dmi_jtag #(
    .IdcodeValue    ( 32'hDEADBEEF  )
) i_dmi_jtag (
    .clk_i              ( clk               ),  
    .rst_ni             ( rst_n             ),
    .testmode_i         ( 1'b0              ),
    .dmi_rst_no         ( dmi_rst_n         ),
    .dmi_req_o          ( dmi_req           ),
    .dmi_req_valid_o    ( dmi_req_valid     ),
    .dmi_req_ready_i    ( dmi_req_ready     ),
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
    .BusWidth           ( 32  ),
    .NrHarts            ( 1     ),
    .SelectableHarts    ( 1     )
) i_dm_top (
    .clk_i                  ( clk                           ),
    .rst_ni                 ( rst_n                         ),
    .next_dm_addr_i         ( 'd0                           ),
    .testmode_i             ( 1'b0                          ),
    .ndmreset_o             (                               ), // non-debug module reset
    .ndmreset_ack_i         ( 1'b1                          ), // non-debug module reset acknowledgement pulse
    .dmactive_o             ( /*NOT CONNECTED*/             ), // debug module is active
    .debug_req_o            (                               ), // async debug request
    .unavailable_i          ( 1'b0                          ),
    .hartinfo_i             ( info                          ),

    .slave_req_i            ( 1'b0                  ),
    .slave_we_i             ( 1'b0                   ),
    .slave_addr_i           ( 'd0   ),
    .slave_be_i             ( 'd0                   ),
    .slave_wdata_i          ( 'd0                ),
    .slave_rdata_o          (                 ),

    .master_req_o           (                ),
    .master_add_o           (                ),
    .master_we_o            (                ),
    .master_wdata_o         (                ),
    .master_be_o            (                ),
    .master_gnt_i           ( 1'b0                 ),
    .master_r_valid_i       ( 'd0             ),
    .master_r_rdata_i       ( 'd0             ),
    .master_r_err_i         ( 1'b0                          ),
    .master_r_other_err_i   ( 1'b0                          ),

    .dmi_rst_ni             ( dmi_rst_n                     ),
    .dmi_req_valid_i        ( dmi_req_valid                 ),
    .dmi_req_ready_o        ( dmi_req_ready                 ),
    .dmi_req_i              ( dmi_req                       ),
    .dmi_resp_valid_o       ( dmi_resp_valid                ),
    .dmi_resp_ready_i       ( dmi_resp_ready                ),
    .dmi_resp_o             ( dmi_resp                      )
);


endmodule
