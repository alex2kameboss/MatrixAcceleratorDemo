set xilinx_uart [create_ip -name axi_uartlite -vendor xilinx.com -library ip -module_name xilinx_uart]

# User Parameters
set_property -dict [list \
  CONFIG.C_BAUDRATE {115200} \
  CONFIG.C_S_AXI_ACLK_FREQ_HZ_d {50} \
] [get_ips xilinx_uart]