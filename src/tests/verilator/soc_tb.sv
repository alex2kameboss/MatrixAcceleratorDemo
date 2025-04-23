module soc_tb # (
    parameter   PRF_LOG_P   =   1   ,
    parameter   PRF_LOG_Q   =   2   
) (
    input   logic   clk     ,
    input   logic   rst_n   
);

initial $display("LOG_P: %d, LOG_Q: %d", PRF_LOG_P, PRF_LOG_Q);

initial begin : wait_for_stop
    wait(i_dut.i_ctrl_regs.reg_q_o[0] == 'hFF);
    $finish();
end

matrix_accelerator_soc #(
    .PRF_LOG_P  ( PRF_LOG_P ),
    .PRF_LOG_Q  ( PRF_LOG_Q )
) i_dut (
    .clk    ( clk   ),
    .rst_n  ( rst_n ),
    .tx     (       ),
    .rx     ( 1'b1  )
);

endmodule
