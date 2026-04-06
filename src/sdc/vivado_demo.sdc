# clock
set_property IOSTANDARD DIFF_SSTL12 [get_ports clk_in_n]
set_property PACKAGE_PIN BH51 [get_ports clk_in_p]
set_property PACKAGE_PIN BJ51 [get_ports clk_in_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports clk_in_p]

#hbm clock
set_property PACKAGE_PIN BJ4 [get_ports hbm_clk]
set_property IOSTANDARD LVCMOS12 [get_ports hbm_clk]

# reset
set_false_path -from [get_ports rst_in]
set_input_delay 0.000 [get_ports rst_in]

set_property PACKAGE_PIN BM29 [get_ports rst_in]
set_property IOSTANDARD LVCMOS12 [get_ports rst_in]

# jtag
set_property CLOCK_BUFFER_TYPE BUFG [get_ports tck]
create_clock -period 1000.000 -name tck [get_ports tck]
set_input_delay 0.000 [get_ports tck]
set_input_jitter tck 1.000

set_input_delay -clock tck -clock_fall 5.000 [get_ports tdi]
set_input_delay -clock tck -clock_fall 5.000 [get_ports tms]
set_output_delay -clock tck 5.000 [get_ports tdo]
set_false_path -from [get_ports trstn]

set_property PACKAGE_PIN A21 [get_ports tck]
set_property IOSTANDARD LVCMOS18 [get_ports tck]
set_property PACKAGE_PIN A20 [get_ports tdi]
set_property IOSTANDARD LVCMOS18 [get_ports tdi]
set_property PACKAGE_PIN A19 [get_ports tms]
set_property IOSTANDARD LVCMOS18 [get_ports tms]
set_property PACKAGE_PIN A18 [get_ports tdo]
set_property IOSTANDARD LVCMOS18 [get_ports tdo]
set_property PACKAGE_PIN A16 [get_ports trstn]
set_property IOSTANDARD LVCMOS18 [get_ports trstn]

# uart
create_clock -period 104166.000 -name uart_rx_clk_virt
set_input_delay -clock uart_rx_clk_virt 0.000 [get_ports rx]
create_clock -period 104166.000 -name uart_tx_clk_virt
set_output_delay -clock uart_tx_clk_virt 0.000 [get_ports tx]

set_property PACKAGE_PIN C18 [get_ports rx]
set_property IOSTANDARD LVCMOS18 [get_ports rx]
set_property PACKAGE_PIN C17 [get_ports tx]
set_property IOSTANDARD LVCMOS18 [get_ports tx]

# i_mem multi clock cycle
#set_multicycle_path -from [get_clocks clk_out200_pll] -to [get_clocks clk_out100_pll] 2
# 100 -> 200
set_multicycle_path 2 -setup -from [get_clocks clk_out100_pll] -to [get_clocks clk_out200_pll] 
set_multicycle_path 1 -hold -end -from [get_clocks clk_out100_pll] -to [get_clocks clk_out200_pll]
# 200 -> 100
set_multicycle_path 2 -setup -start -from [get_clocks clk_out200_pll] -to [get_clocks clk_out100_pll]
set_multicycle_path 1 -hold -from [get_clocks clk_out200_pll] -to [get_clocks clk_out100_pll]

#set_multicycle_path -setup -from [get_clocks clk_out100_pll] -through [get_cells i_soc/i_core/i_matrix_accelerator/i_dma_unit] -to [get_clocks clk_out200_pll] 2
#set_multicycle_path -hold -end -from [get_clocks clk_out100_pll] -through [get_cells i_soc/i_core/i_matrix_accelerator/i_dma_unit] -to [get_clocks clk_out200_pll] 1

# from axi clock to HBM 50 -> 200
set_multicycle_path 4 -setup -from [get_clocks clk_out100_pll] -to [get_clocks clk_out450_pll] 
set_multicycle_path 3 -hold -end -from [get_clocks clk_out100_pll] -to [get_clocks clk_out450_pll]

# from axi clock to HBM 200 -> 50
set_multicycle_path 4 -setup -start -from [get_clocks clk_out450_pll] -to [get_clocks clk_out100_pll] 
set_multicycle_path 3 -hold -from [get_clocks clk_out450_pll] -to [get_clocks clk_out100_pll]

set_false_path -from [get_pins i_soc/i_ram/init_complete_out_0]

#set_false_path -from [get_clocks clk_out450_pll] -to [get_clocks clk_out100_pll]
#set_false_path -from [get_clocks clk_out100_pll] -to [get_clocks clk_out450_pll]

# fix tck placing
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets tck_IBUF_inst/O]

# combinatorial loop
#set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets i_soc/i_debugger/i_slave_dm_axi_adapter/i_axi_to_mem/i_axi_to_detailed_mem/i_fork/inp_state_q_reg_0]
#set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets i_soc/i_debugger/i_slave_dm_axi_adapter/i_axi_to_mem/i_axi_to_detailed_mem/i_fork_dynamic/i_fork/gen_oup_state[0].oup_state_q_reg_1]
#set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets i_soc/i_debugger/*]

set_clock_groups -asynchronous -group [get_clocks [list clk_in_p [get_clocks -of_objects [get_pins i_pll/inst/plle4_adv_inst/CLKOUT0]] [get_clocks -of_objects [get_pins i_pll/inst/plle4_adv_inst/CLKOUT1]]] [get_clocks -of_objects [get_pins i_pll/inst/plle4_adv_inst/CLKOUT2]]] -group [get_clocks tck] -group [get_clocks uart_rx_clk_virt] -group [get_clocks uart_tx_clk_virt]

#set_property CASCADE_HEIGHT 2 [get_cells -hierarchical xpm_memory_tdpram_inst]
#set_property RAM_DECOMP area [get_cells -hierarchical xpm_memory_tdpram_inst]

set_false_path -from [get_pins -hierarchical -regexp .*i_soc/i_core/i_matrix_accelerator/i_control_unit/config_intf.*]


