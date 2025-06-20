`timescale 1ns/1ps

module top_tb #(
    parameter PORT  =   1234
)();

localparam CLOCK_PERIOD  = 10ns;

logic clk  ;
logic rst_n;
logic tck  ;
logic tms  ;
logic trstn;
logic tdi  ;
logic tdo  ;
logic [31:0] jtag_exit;

logic tx;
logic uart_rcv;
logic [7 : 0] uart_data;

initial begin
    clk = 1'b1;
    // Start the clock
    forever #(CLOCK_PERIOD/2) clk = ~clk;
end

initial begin
    rst_n = 1'b0;

    repeat(5) @(negedge clk);
    rst_n = 1'b1;
end

initial begin : wait_for_stop
    wait(i_dut.i_soc.i_ctrl_regs.reg_q_o[0] == 'hFF);
    $finish();
end

always_ff @(posedge clk)
    if ( uart_rcv ) $write("%c", uart_data);

always_comb begin : jtag_exit_handler
    if (jtag_exit)
        $finish(2);
end

SimJTAG #(
    .TICK_DELAY ( 1     ),
    .PORT       ( PORT  )
) i_jtag (
    .clock          ( clk           ),
    .reset          ( ~rst_n        ),
    .enable         ( rst_n         ),
    .init_done      ( rst_n         ),
    .jtag_TCK       ( tck           ),
    .jtag_TMS       ( tms           ),
    .jtag_TDI       ( tdi           ),
    .jtag_TRSTn     ( trstn         ),
    .jtag_TDO_data  ( tdo           ),
    .jtag_TDO_driven( 1'b1          ),
    .exit           ( jtag_exit     )
);

top i_dut (
    .clk_in_p   ( clk   ),
    .clk_in_n   ( ~clk  ),
    .rst_n_in   ( rst_n ),
    .tx         ( tx    ),
    .rx         ( 1'b1  ),
    .tck        ( tck   ),
    .tms        ( tms   ),
    .trstn      ( trstn ),
    .tdi        ( tdi   ),
    .tdo        ( tdo   )
);

uart_rx #(
    .CLKS_PER_BIT ( 868 )
) i_rx_decoder (
    .i_Clock    ( clk       ),
    .i_Rx_Serial( tx        ),
    .o_Rx_DV    ( uart_rcv  ),
    .o_Rx_Byte  ( uart_data )
);

endmodule