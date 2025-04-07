module top(
    input   clk_in  ,
    input   rst_n_in,
    output  tx      ,
    input   rx      
);

logic clk;
logic rst_n;
logic locked;
logic clk_hbm;

assign rst_n = locked & rst_n_in;

pll i_pll (
    .clk_in1    ( clk       ),
    .resetn     ( rst_n_in  ),
    .locked     ( locked    ),
    .clk_out100 ( clk       ),
    .clk_hbm    ( clk_hbm   )
);

matrix_accelerator_soc i_soc (
    .clk_hbm( clk_hbm   ),
    .clk    ( clk       ),
    .rst_n  ( rst_n     ),
    .tx     ( tx        ),
    .rx     ( rx        )
);

endmodule