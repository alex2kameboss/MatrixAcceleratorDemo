module top(
    input   clk_in  ,
    input   rst_n_in,
    output  tx      ,
    input   rx      ,
    input   tck     ,
    input   tms     ,
    input   trstn   ,
    input   tdi     ,
    output  tdo     
);

logic clk, clk_2x;
logic rst_n;
logic locked;
logic clk_hbm;

assign rst_n = locked & rst_n_in;

pll i_pll (
    .clk_in1_p  ( clk_in_p  ),
    .clk_in1_n  ( clk_in_n  ),
    .resetn     ( rst_n_in  ),
    .locked     ( locked    ),
    .clk_out100 ( clk       ),
    .clk_out200 ( clk_2x    )
);

matrix_accelerator_soc i_soc (
    .clk_hbm( clk_hbm   ),
    .clk    ( clk       ),
    .clk_2x ( clk_2x    ),
    .rst_n  ( rst_n     ),
    .tx     ( tx        ),
    .rx     ( rx        ),
    .tck    ( tck       ),
    .tms    ( tms       ),
    .trstn  ( trstn     ),
    .tdi    ( tdi       ),
    .tdo    ( tdo       )
);

endmodule