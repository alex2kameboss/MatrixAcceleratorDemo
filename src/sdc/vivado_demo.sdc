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

# jtag
set_property CLOCK_BUFFER_TYPE BUFG [get_ports tck]
create_clock -period 1000 -name tck -waveform {0.000 50.000} [get_ports tck]
set_input_jitter tck 1.000

set_input_delay  -clock tck -clock_fall 5 [get_ports tdi    ]
set_input_delay  -clock tck -clock_fall 5 [get_ports tms    ]
set_output_delay -clock tck             5 [get_ports tdo    ]

set_input_delay  -clock tck -clock_fall 5 [get_ports tdi    ]
set_input_delay  -clock tck -clock_fall 5 [get_ports tms    ]
set_output_delay -clock tck             5 [get_ports tdo    ]
set_false_path   -from                    [get_ports trstn  ] 

set_property PACKAGE_PIN A21      [get_ports "tck"  ] ;# Bank  71 VCCO - VADJ     - IO_L22P_T3U_N6_DBC_AD0P_71
set_property IOSTANDARD  LVCMOS18 [get_ports "tck"  ] ;# Bank  71 VCCO - VADJ     - IO_L22P_T3U_N6_DBC_AD0P_71
set_property PACKAGE_PIN A20      [get_ports "tdi"  ] ;# Bank  71 VCCO - VADJ     - IO_L22N_T3U_N7_DBC_AD0N_71
set_property IOSTANDARD  LVCMOS18 [get_ports "tdi"  ] ;# Bank  71 VCCO - VADJ     - IO_L22N_T3U_N7_DBC_AD0N_71
set_property PACKAGE_PIN A19      [get_ports "tms"  ] ;# Bank  71 VCCO - VADJ     - IO_L23P_T3U_N8_71
set_property IOSTANDARD  LVCMOS18 [get_ports "tms"  ] ;# Bank  71 VCCO - VADJ     - IO_L23P_T3U_N8_71
set_property PACKAGE_PIN A18      [get_ports "tdo"  ] ;# Bank  71 VCCO - VADJ     - IO_L23N_T3U_N9_71
set_property IOSTANDARD  LVCMOS18 [get_ports "tdo"  ] ;# Bank  71 VCCO - VADJ     - IO_L23N_T3U_N9_71
set_property PACKAGE_PIN A16      [get_ports "trstn"] ;# Bank  71 VCCO - VADJ     - IO_L24N_T3U_N11_71
set_property IOSTANDARD  LVCMOS18 [get_ports "trstn"] ;# Bank  71 VCCO - VADJ     - IO_L24N_T3U_N11_71

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

# fix tck placing
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets tck_IBUF_inst/O]

# combinatorial loop
#set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets i_soc/i_debugger/i_slave_dm_axi_adapter/i_axi_to_mem/i_axi_to_detailed_mem/i_fork/inp_state_q_reg_0]
#set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets i_soc/i_debugger/i_slave_dm_axi_adapter/i_axi_to_mem/i_axi_to_detailed_mem/i_fork_dynamic/i_fork/gen_oup_state[0].oup_state_q_reg_1]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets i_soc/i_debugger/*]

set_clock_groups -asynchronous -group [get_clocks [list clk_in_p  [get_clocks -of_objects [get_pins i_pll/inst/plle4_adv_inst/CLKOUT0]] [get_clocks -of_objects [get_pins i_pll/inst/plle4_adv_inst/CLKOUT1]]]] -group [get_clocks tck] -group [get_clocks uart_rx_clk_virt] -group [get_clocks uart_tx_clk_virt]