set mem_2MB [create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name mem_2MB]

# User Parameters
set_property -dict [list \
  CONFIG.AXI_ID_Width {6} \
  CONFIG.Coe_File [list $ROOT/src/tests/vivado/hello_world.coe] \
  CONFIG.Interface_Type {AXI4} \
  CONFIG.Load_Init_File {true} \
  CONFIG.Write_Depth_A {163840} \
  CONFIG.Write_Width_A {256} \
] [get_ips mem_2MB]
