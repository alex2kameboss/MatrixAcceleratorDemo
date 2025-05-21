`define PRF_LOG_P 1
`define PRF_LOG_Q 2

module top(
    input   clk_in_p,
    input   clk_in_n,
    input   rst_n_in,
    output  tx      ,
    input   rx      
);

logic clk;
logic rst_n;
logic locked;
logic clk_hbm;

assign rst_n = locked & ~rst_n_in;

pll i_pll (
    .clk_in1_p  ( clk_in_p  ),
    .clk_in1_n  ( clk_in_n  ),
    .resetn     ( ~rst_n_in ),
    .locked     ( locked    ),
    .clk_out100 ( clk       )
);

matrix_accelerator_soc # (
    .PRF_LOG_P  ( `PRF_LOG_P),
    .PRF_LOG_Q  ( `PRF_LOG_Q)
) i_soc (
    .clk_hbm( clk       ),
    .clk    ( clk       ),
    .rst_n  ( rst_n     ),
    .tx     ( tx        ),
    .rx     ( rx        )
);

endmodule