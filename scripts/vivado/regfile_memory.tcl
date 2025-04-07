create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name reg_file_memory
set_property -dict [list \
  CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
  CONFIG.Operating_Mode_A {READ_FIRST} \
  CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
  CONFIG.Write_Depth_A {131072} \
  CONFIG.Write_Width_A {32} \
] [get_ips reg_file_memory]
