create_ip -name axi_uartlite -vendor xilinx.com -library ip -version 2.0 -module_name xilinx_uart
set_property CONFIG.C_BAUDRATE {115200} [get_ips xilinx_uart]