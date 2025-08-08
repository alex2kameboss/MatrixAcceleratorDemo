set hbm_ram [create_ip -name hbm -vendor xilinx.com -library ip -module_name hbm_ram]

# User Parameters
set_property -dict [list \
  CONFIG.USER_APB_EN {false} \
  CONFIG.USER_AUTO_POPULATE {yes} \
  CONFIG.USER_AXI_CLK_FREQ {450} \
  CONFIG.USER_DEBUG_EN {FALSE} \
  CONFIG.USER_EXAMPLE_TG {SYNTHESIZABLE} \
  CONFIG.USER_HBM_TCK_0 {900} \
  CONFIG.USER_MC0_BG_INTERLEAVE_EN {false} \
  CONFIG.USER_MC0_BURST_RW_REFRESH_HOLDOFF {false} \
  CONFIG.USER_MC0_CA_PARITY_EN {false} \
  CONFIG.USER_MC0_DQ_PARITY_EN {false} \
  CONFIG.USER_MC0_ECC_BYPASS {false} \
  CONFIG.USER_MC0_ENABLE_ECC_CORRECTION {false} \
  CONFIG.USER_MC0_EN_DATA_MASK {true} \
  CONFIG.USER_MC0_EN_SBREF {false} \
  CONFIG.USER_MC0_LOOKAHEAD_ACT {true} \
  CONFIG.USER_MC0_LOOKAHEAD_PCH {true} \
  CONFIG.USER_MC0_LOOKAHEAD_SBRF {false} \
  CONFIG.USER_MC0_MAINTAIN_COHERENCY {true} \
  CONFIG.USER_MC0_MANUAL_ADDR_MAP_SEL {false} \
  CONFIG.USER_MC0_POP_EN {false} \
  CONFIG.USER_MC0_PRE_DEF_ADDR_MAP_SEL {ROW_BANK_COLUMN} \
  CONFIG.USER_MC0_Q_AGE_LIMIT {0x7F} \
  CONFIG.USER_MC0_REF_TEMP_COMP {false} \
  CONFIG.USER_MC0_REORDER_EN {false} \
  CONFIG.USER_MC0_TEMP_CTRL_SELF_REF_INTVL {false} \
  CONFIG.USER_MC0_TRAFFIC_OPTION {User_Defined} \
  CONFIG.USER_MC_ENABLE_02 {FALSE} \
  CONFIG.USER_MC_ENABLE_03 {FALSE} \
  CONFIG.USER_MC_ENABLE_04 {FALSE} \
  CONFIG.USER_MC_ENABLE_05 {FALSE} \
  CONFIG.USER_MC_ENABLE_06 {FALSE} \
  CONFIG.USER_MC_ENABLE_07 {FALSE} \
  CONFIG.USER_SAXI_14 {false} \
  CONFIG.USER_SAXI_15 {false} \
  CONFIG.USER_SWITCH_ENABLE_00 {FALSE} \
  CONFIG.USER_XSDB_INTF_EN {TRUE} \
] [get_ips hbm_ram]

set riscv_loop [create_ip -name axi_memory_init -vendor xilinx.com -library ip -module_name riscv_loop]

# User Parameters
set_property -dict [list \
  CONFIG.ADDR_SIZE {9} \
  CONFIG.ADDR_WIDTH {33} \
  CONFIG.ARUSER_WIDTH {4} \
  CONFIG.AWUSER_WIDTH {4} \
  CONFIG.BUSER_WIDTH {4} \
  CONFIG.DATA_WIDTH {256} \
  CONFIG.HAS_ACLKEN {0} \
  CONFIG.HAS_CACHE {0} \
  CONFIG.HAS_LOCK {0} \
  CONFIG.HAS_PROT {0} \
  CONFIG.HAS_QOS {0} \
  CONFIG.HAS_REGION {0} \
  CONFIG.ID_WIDTH {6} \
  CONFIG.INIT_VALUE {0x0000006f0000006f0000006f0000006f0000006f0000006f0000006f0000006f} \
  CONFIG.RUSER_WIDTH {4} \
  CONFIG.WUSER_WIDTH {4} \
] [get_ips riscv_loop]

set rama_0 [create_ip -name rama -vendor xilinx.com -library ip -module_name rama_0]

# User Parameters
set_property -dict [list \
  CONFIG.ADDR_WIDTH {30} \
  CONFIG.ID_WIDTH {6} \
] [get_ips rama_0]

set axi_vip_0 [create_ip -name axi_vip -vendor xilinx.com -library ip -module_name axi_vip_0]

# User Parameters
set_property -dict [list \
  CONFIG.ADDR_WIDTH {33} \
  CONFIG.ARUSER_WIDTH {0} \
  CONFIG.AWUSER_WIDTH {0} \
  CONFIG.BUSER_WIDTH {0} \
  CONFIG.DATA_WIDTH {256} \
  CONFIG.HAS_CACHE {0} \
  CONFIG.HAS_LOCK {0} \
  CONFIG.HAS_PROT {0} \
  CONFIG.HAS_QOS {0} \
  CONFIG.HAS_REGION {0} \
  CONFIG.HAS_SIZE {1} \
  CONFIG.ID_WIDTH {6} \
  CONFIG.RUSER_WIDTH {0} \
  CONFIG.WUSER_WIDTH {0} \
] [get_ips axi_vip_0]

set mem_2MB [create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name mem_2MB]

# User Parameters
set_property -dict [list \
  CONFIG.AXI_ID_Width {6} \
  CONFIG.Coe_File [list $ROOT/src/tests/vivado/hello_world.coe] \
  CONFIG.Interface_Type {AXI4} \
  CONFIG.Load_Init_File {true} \
  CONFIG.Write_Depth_A {65536} \
  CONFIG.Write_Width_A {256} \
] [get_ips mem_2MB]

set riscv_loop_bram [create_ip -name axi_memory_init -vendor xilinx.com -library ip -module_name riscv_loop_bram]

# User Parameters
set_property -dict [list \
  CONFIG.ADDR_SIZE {9} \
  CONFIG.ADDR_WIDTH {30} \
  CONFIG.ARUSER_WIDTH {4} \
  CONFIG.AWUSER_WIDTH {4} \
  CONFIG.BASE_ADDR {0x0000000000000000} \
  CONFIG.BUSER_WIDTH {4} \
  CONFIG.DATA_WIDTH {256} \
  CONFIG.HAS_ACLKEN {0} \
  CONFIG.HAS_CACHE {0} \
  CONFIG.HAS_LOCK {0} \
  CONFIG.HAS_PROT {0} \
  CONFIG.HAS_QOS {0} \
  CONFIG.HAS_REGION {0} \
  CONFIG.ID_WIDTH {6} \
  CONFIG.INIT_VALUE {0x0000006f0000006f0000006f0000006f0000006f0000006f0000006f0000006f} \
  CONFIG.RUSER_WIDTH {4} \
  CONFIG.WUSER_WIDTH {4} \
] [get_ips riscv_loop_bram]