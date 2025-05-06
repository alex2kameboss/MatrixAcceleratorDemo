`timescale 1ns/1ps

`define PRF_LOG_P 1
`define PRF_LOG_Q 2

module soc_tb #(
    parameter PORT  =   1234
)();

localparam CLOCK_PERIOD  = 10ns;

logic jtag_working;
logic clk  ;
logic rst_n;
logic tck  ;
logic tms  ;
logic trstn;
logic tdi  ;
logic tdo  ;
logic [31:0] jtag_exit;

initial begin
    clk   = 1'b0;
    rst_n = 1'b0;
    // Synch reset for TB memories
    repeat (10) #(CLOCK_PERIOD/2) clk = ~clk;
    clk = 1'b0;

    // Asynch reset for main system
    repeat (5) #(CLOCK_PERIOD);
    rst_n = 1'b1;
    repeat (5) #(CLOCK_PERIOD);
    $display("LOG_P: %d, LOG_Q: %d", `PRF_LOG_P, `PRF_LOG_Q);
    $display("-------- STDOUT --------");
    // Start the clock
    forever #(CLOCK_PERIOD/2) clk = ~clk;
end

initial begin : wait_for_stop
    wait(i_dut.i_ctrl_regs.reg_q_o[0] == 'hFF);
    $finish();
end

/*
jtag_dpi #(
    .TCP_PORT   ( PORT  )
) i_jtag (
    .clk_i      ( clk   ),
    .enable_i   ( 1'b1  ),
    .tms_o      ( tms   ),
    .tck_o      ( tck   ),
    .trst_o     ( trstn ),
    .tdi_o      ( tdi   ),
    .tdo_i      ( tdo   )
);
*/

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

matrix_accelerator_soc #(
    .PRF_LOG_P  ( `PRF_LOG_P),
    .PRF_LOG_Q  ( `PRF_LOG_Q)
) i_dut (
    .clk    ( clk   ),
    .rst_n  ( rst_n ),
    .tx     (       ),
    .rx     ( 1'b1  ),
    .tck    ( tck   ),
    .tms    ( tms   ),
    .trstn  ( trstn ),
    .tdi    ( tdi   ),
    .tdo    ( tdo   )
);

endmodule