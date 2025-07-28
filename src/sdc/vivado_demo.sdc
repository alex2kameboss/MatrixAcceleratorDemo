# clock
set_property PACKAGE_PIN BJ51        [get_ports "clk_in_n"] ;# Bank  66 VCCO - DDR4_VDDQ_1V2 - IO_L11N_T1U_N9_GC_66
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "clk_in_n"] ;# Bank  66 VCCO - DDR4_VDDQ_1V2 - IO_L11N_T1U_N9_GC_66
set_property PACKAGE_PIN BH51        [get_ports "clk_in_p"] ;# Bank  66 VCCO - DDR4_VDDQ_1V2 - IO_L11P_T1U_N8_GC_66
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "clk_in_p"] ;# Bank  66 VCCO - DDR4_VDDQ_1V2 - IO_L11P_T1U_N8_GC_66

#hbm clock
set_property PACKAGE_PIN BJ4         [get_ports "hbm_clk"] ;# Bank  69 VCCO - QDR4_VDDQ_1V2 - IO_L11P_T1U_N8_GC_69
set_property IOSTANDARD  LVCMOS12    [get_ports "hbm_clk"] ;# Bank  69 VCCO - QDR4_VDDQ_1V2 - IO_L11P_T1U_N8_GC_69

# reset
set_false_path -from [get_ports {rst_n_in}]

set_property PACKAGE_PIN BM29      [get_ports "rst_n_in"] ;# Bank  64 VCCO - DDR4_VDDQ_1V2 - IO_L1N_T0L_N1_DBC_64
set_property IOSTANDARD  LVCMOS12  [get_ports "rst_n_in"] ;# Bank  64 VCCO - DDR4_VDDQ_1V2 - IO_L1N_T0L_N1_DBC_64


# uart
create_clock -period 8680 -name uart_rx_clk_virt
set_input_delay -clock { uart_rx_clk_virt } 0 [get_ports rx]
create_clock -period 8680 -name uart_tx_clk_virt
set_output_delay -clock { uart_tx_clk_virt } 0 [get_ports tx]

set_property PACKAGE_PIN C18      [get_ports "rx"] ;# Bank  71 VCCO - VADJ     - IO_L19P_T3L_N0_DBC_AD9P_71
set_property IOSTANDARD  LVCMOS18 [get_ports "rx"] ;# Bank  71 VCCO - VADJ     - IO_L19P_T3L_N0_DBC_AD9P_71
set_property PACKAGE_PIN C17      [get_ports "tx"] ;# Bank  71 VCCO - VADJ     - IO_L19N_T3L_N1_DBC_AD9N_71
set_property IOSTANDARD  LVCMOS18 [get_ports "tx"] ;# Bank  71 VCCO - VADJ     - IO_L19N_T3L_N1_DBC_AD9N_71

# i_mem multi clock cycle
set_multicycle_path -from [get_clocks clk_out200_pll] -to [get_clocks clk_out100_pll] 2

# combinatorial loop
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets i_soc/i_debugger/i_slave_dm_axi_adapter/i_axi_to_mem/i_axi_to_detailed_mem/i_fork/inp_state_q_reg_0]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets i_soc/i_debugger/i_slave_dm_axi_adapter/i_axi_to_mem/i_axi_to_detailed_mem/i_fork_dynamic/i_fork/gen_oup_state[0].oup_state_q_reg_1]
