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
current_instance -quiet
current_instance design_1_i/mdm_1/U0
create_clock -period 33.333 [get_pins Use*.BSCAN*/*/INTERNAL_TCK]
create_generated_clock -source [get_pins Use*.BSCAN*/*/INTERNAL_TCK] -divide_by 2 [get_pins Use*.BSCAN*/*/UPDATE]
create_generated_clock -source [get_pins Use*.BSCAN*/*/INTERNAL_TCK] -divide_by 1 [get_pins Use*.BSCAN*/*/DRCK]
create_generated_clock -source [get_pins Use*.BSCAN*/*/INTERNAL_TCK] -divide_by 1 [get_pins Use*.BSCAN*/*/TCK]
create_generated_clock -source [get_pins Use*.BSCAN*/*/INTERNAL_TCK] -divide_by 2 [get_pins */*/*.BUFG_UPDATE/*/O]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins Use*.BSCAN*/*/INTERNAL_TCK]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins Use*.BSCAN*/*/UPDATE]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins Use*.BSCAN*/*/DRCK]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins Use*.BSCAN*/*/TCK]]
set_clock_groups -asynchronous -group [get_clocks -quiet -of_objects [get_pins */*/*.BUFG_UPDATE/*/O]]
set_input_delay -clock [get_clocks -of_objects [get_pins Use*.BSCAN*/*/DRCK]] 1.000 [get_pins Use*.BSCAN*/*/INTERNAL_TDI]