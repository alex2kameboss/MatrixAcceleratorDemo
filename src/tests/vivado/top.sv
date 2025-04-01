module top(
    input   clk_in  ,
    input   rst_n_in,
    output  tx      ,
    input   rx      
);

logic clk;
logic rst_n;
logic locked;

assign rst_n = locked & rst_n_in;

pll i_pll (
    .clk_in1    ( clk       ),
    .resetn     ( rst_n_in  ),
    .locked     ( locked    ),
    .clk_out100 ( clk       )
);

matrix_accelerator_soc i_soc (
    .clk    ( clk   ),
    .rst_n  ( rst_n ),
    .tx     ( tx    ),
    .rx     ( rx    )
);

endmodule