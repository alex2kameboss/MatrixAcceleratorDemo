# clock
set_property BOARD_PART_PIN default_100mhz_clk_p [get_ports clk_in_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports clk_in_p]
set_property BOARD_PART_PIN default_100mhz_clk_n [get_ports clk_in_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports clk_in_n]
set_property PACKAGE_PIN BH51 [get_ports clk_in_p]
set_property PACKAGE_PIN BJ51 [get_ports clk_in_n]

# reset
set_property BOARD_PART_PIN CPU_RESET [get_ports rst_n_in]
set_property IOSTANDARD LVCMOS12 [get_ports rst_n_in]
set_property PACKAGE_PIN BM29 [get_ports rst_n_in]

set_false_path -from [get_ports {rst_n_in}]

# uart
create_clock -period 8680 -name uart_rx_clk_virt
set_input_delay -clock { uart_rx_clk_virt } 0 [get_ports rx]
create_clock -period 8680 -name uart_tx_clk_virt
set_output_delay -clock { uart_tx_clk_virt } 0 [get_ports tx]

# jtag
create_clock -period 100.000 -name tck -waveform {0.000 50.000} [get_ports tck]
set_input_jitter tck 1.000

set_input_delay  -clock tck -clock_fall 5 [get_ports tdi    ]
set_input_delay  -clock tck -clock_fall 5 [get_ports tms    ]
set_output_delay -clock tck             5 [get_ports tdo    ]
set_false_path   -from                    [get_ports trstn  ] 

# i_mem multi clock cycle
set_multicycle_path -from [get_clocks clk_out200_pll] -to [get_clocks clk_out100_pll] 2
