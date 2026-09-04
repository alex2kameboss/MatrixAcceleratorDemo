
################################################################
# This is a generated script based on design: hbm_susbsystem
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source hbm_subsystem_script.tcl

# CHANGE DESIGN NAME HERE
variable design_name
set design_name hbm_subsystem

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:hbm:1.0\
xilinx.com:ip:rama:1.1\
xilinx.com:ip:axi_memory_init:1.0\
xilinx.com:ip:xlconstant:1.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set s_axi_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {33} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.FREQ_HZ {50000000} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {6} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $s_axi_0


  # Create ports
  set axi_aclk_0 [ create_bd_port -dir I -type clk -freq_hz 50000000 axi_aclk_0 ]
  set axi_aresetn_0 [ create_bd_port -dir I -type rst axi_aresetn_0 ]
  set HBM_REF_CLK_0_0 [ create_bd_port -dir I -type clk HBM_REF_CLK_0_0 ]
  set init_complete_out_0 [ create_bd_port -dir O init_complete_out_0 ]

  # Create instance: hbm_0, and set properties
  set hbm_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:hbm:1.0 hbm_0 ]
  set_property -dict [list \
    CONFIG.USER_APB_EN {false} \
    CONFIG.USER_HBM_DENSITY {8GB} \
    CONFIG.USER_MC0_ECC_BYPASS {true} \
    CONFIG.USER_MC0_TRAFFIC_OPTION {Linear} \
    CONFIG.USER_MC_ENABLE_01 {TRUE} \
    CONFIG.USER_MC_ENABLE_02 {TRUE} \
    CONFIG.USER_MC_ENABLE_03 {TRUE} \
    CONFIG.USER_MC_ENABLE_04 {TRUE} \
    CONFIG.USER_MC_ENABLE_05 {TRUE} \
    CONFIG.USER_MC_ENABLE_06 {TRUE} \
    CONFIG.USER_MC_ENABLE_07 {TRUE} \
    CONFIG.USER_SWITCH_ENABLE_00 {FALSE} \
    CONFIG.USER_SWITCH_ENABLE_01 {FALSE} \
    CONFIG.USER_XSDB_INTF_EN {FALSE} \
  ] $hbm_0


  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [list \
    CONFIG.NUM_MI {32} \
    CONFIG.S00_HAS_DATA_FIFO {2} \
    CONFIG.STRATEGY {2} \
  ] $axi_interconnect_0


  # Create instance: rama_0, and set properties
  set rama_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:rama:1.1 rama_0 ]
  set_property -dict [list \
    CONFIG.ADDR_WIDTH {33} \
    CONFIG.ID_WIDTH {6} \
  ] $rama_0


  # Create instance: axi_memory_init_0, and set properties
  set axi_memory_init_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_memory_init:1.0 axi_memory_init_0 ]
  set_property -dict [list \
    CONFIG.ADDR_SIZE {9} \
    CONFIG.ADDR_WIDTH {33} \
    CONFIG.ARUSER_WIDTH {4} \
    CONFIG.AWUSER_WIDTH {4} \
    CONFIG.BUSER_WIDTH {4} \
    CONFIG.DATA_WIDTH {256} \
    CONFIG.HAS_ACLKEN {0} \
    CONFIG.ID_WIDTH {6} \
    CONFIG.INIT_VALUE {0x0000006f0000006f0000006f0000006f0000006f0000006f0000006f0000006f} \
    CONFIG.RUSER_WIDTH {4} \
    CONFIG.WUSER_WIDTH {4} \
  ] $axi_memory_init_0


  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins hbm_0/SAXI_00]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins hbm_0/SAXI_01]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins hbm_0/SAXI_02]
  connect_bd_intf_net -intf_net axi_interconnect_0_M03_AXI [get_bd_intf_pins axi_interconnect_0/M03_AXI] [get_bd_intf_pins hbm_0/SAXI_03]
  connect_bd_intf_net -intf_net axi_interconnect_0_M04_AXI [get_bd_intf_pins axi_interconnect_0/M04_AXI] [get_bd_intf_pins hbm_0/SAXI_04]
  connect_bd_intf_net -intf_net axi_interconnect_0_M05_AXI [get_bd_intf_pins axi_interconnect_0/M05_AXI] [get_bd_intf_pins hbm_0/SAXI_05]
  connect_bd_intf_net -intf_net axi_interconnect_0_M06_AXI [get_bd_intf_pins axi_interconnect_0/M06_AXI] [get_bd_intf_pins hbm_0/SAXI_06]
  connect_bd_intf_net -intf_net axi_interconnect_0_M07_AXI [get_bd_intf_pins axi_interconnect_0/M07_AXI] [get_bd_intf_pins hbm_0/SAXI_07]
  connect_bd_intf_net -intf_net axi_interconnect_0_M08_AXI [get_bd_intf_pins axi_interconnect_0/M08_AXI] [get_bd_intf_pins hbm_0/SAXI_08]
  connect_bd_intf_net -intf_net axi_interconnect_0_M09_AXI [get_bd_intf_pins axi_interconnect_0/M09_AXI] [get_bd_intf_pins hbm_0/SAXI_09]
  connect_bd_intf_net -intf_net axi_interconnect_0_M10_AXI [get_bd_intf_pins axi_interconnect_0/M10_AXI] [get_bd_intf_pins hbm_0/SAXI_10]
  connect_bd_intf_net -intf_net axi_interconnect_0_M11_AXI [get_bd_intf_pins axi_interconnect_0/M11_AXI] [get_bd_intf_pins hbm_0/SAXI_11]
  connect_bd_intf_net -intf_net axi_interconnect_0_M12_AXI [get_bd_intf_pins axi_interconnect_0/M12_AXI] [get_bd_intf_pins hbm_0/SAXI_12]
  connect_bd_intf_net -intf_net axi_interconnect_0_M13_AXI [get_bd_intf_pins axi_interconnect_0/M13_AXI] [get_bd_intf_pins hbm_0/SAXI_13]
  connect_bd_intf_net -intf_net axi_interconnect_0_M14_AXI [get_bd_intf_pins axi_interconnect_0/M14_AXI] [get_bd_intf_pins hbm_0/SAXI_14]
  connect_bd_intf_net -intf_net axi_interconnect_0_M15_AXI [get_bd_intf_pins axi_interconnect_0/M15_AXI] [get_bd_intf_pins hbm_0/SAXI_15]
  connect_bd_intf_net -intf_net axi_interconnect_0_M16_AXI [get_bd_intf_pins axi_interconnect_0/M16_AXI] [get_bd_intf_pins hbm_0/SAXI_16]
  connect_bd_intf_net -intf_net axi_interconnect_0_M17_AXI [get_bd_intf_pins axi_interconnect_0/M17_AXI] [get_bd_intf_pins hbm_0/SAXI_17]
  connect_bd_intf_net -intf_net axi_interconnect_0_M18_AXI [get_bd_intf_pins axi_interconnect_0/M18_AXI] [get_bd_intf_pins hbm_0/SAXI_18]
  connect_bd_intf_net -intf_net axi_interconnect_0_M19_AXI [get_bd_intf_pins axi_interconnect_0/M19_AXI] [get_bd_intf_pins hbm_0/SAXI_19]
  connect_bd_intf_net -intf_net axi_interconnect_0_M20_AXI [get_bd_intf_pins axi_interconnect_0/M20_AXI] [get_bd_intf_pins hbm_0/SAXI_20]
  connect_bd_intf_net -intf_net axi_interconnect_0_M21_AXI [get_bd_intf_pins axi_interconnect_0/M21_AXI] [get_bd_intf_pins hbm_0/SAXI_21]
  connect_bd_intf_net -intf_net axi_interconnect_0_M22_AXI [get_bd_intf_pins axi_interconnect_0/M22_AXI] [get_bd_intf_pins hbm_0/SAXI_22]
  connect_bd_intf_net -intf_net axi_interconnect_0_M23_AXI [get_bd_intf_pins axi_interconnect_0/M23_AXI] [get_bd_intf_pins hbm_0/SAXI_23]
  connect_bd_intf_net -intf_net axi_interconnect_0_M24_AXI [get_bd_intf_pins axi_interconnect_0/M24_AXI] [get_bd_intf_pins hbm_0/SAXI_24]
  connect_bd_intf_net -intf_net axi_interconnect_0_M25_AXI [get_bd_intf_pins axi_interconnect_0/M25_AXI] [get_bd_intf_pins hbm_0/SAXI_25]
  connect_bd_intf_net -intf_net axi_interconnect_0_M26_AXI [get_bd_intf_pins axi_interconnect_0/M26_AXI] [get_bd_intf_pins hbm_0/SAXI_26]
  connect_bd_intf_net -intf_net axi_interconnect_0_M27_AXI [get_bd_intf_pins axi_interconnect_0/M27_AXI] [get_bd_intf_pins hbm_0/SAXI_27]
  connect_bd_intf_net -intf_net axi_interconnect_0_M28_AXI [get_bd_intf_pins axi_interconnect_0/M28_AXI] [get_bd_intf_pins hbm_0/SAXI_28]
  connect_bd_intf_net -intf_net axi_interconnect_0_M29_AXI [get_bd_intf_pins axi_interconnect_0/M29_AXI] [get_bd_intf_pins hbm_0/SAXI_29]
  connect_bd_intf_net -intf_net axi_interconnect_0_M30_AXI [get_bd_intf_pins axi_interconnect_0/M30_AXI] [get_bd_intf_pins hbm_0/SAXI_30]
  connect_bd_intf_net -intf_net axi_interconnect_0_M31_AXI [get_bd_intf_pins axi_interconnect_0/M31_AXI] [get_bd_intf_pins hbm_0/SAXI_31]
  connect_bd_intf_net -intf_net axi_memory_init_0_M_AXI [get_bd_intf_pins axi_memory_init_0/M_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net rama_0_m_axi [get_bd_intf_pins rama_0/m_axi] [get_bd_intf_pins axi_memory_init_0/S_AXI]
  connect_bd_intf_net -intf_net s_axi_0_1 [get_bd_intf_ports s_axi_0] [get_bd_intf_pins rama_0/s_axi]

  # Create port connections
  connect_bd_net -net HBM_REF_CLK_0_0_1 [get_bd_ports HBM_REF_CLK_0_0] [get_bd_pins hbm_0/HBM_REF_CLK_0] [get_bd_pins hbm_0/HBM_REF_CLK_1]
  connect_bd_net -net axi_aclk_0_1 [get_bd_ports axi_aclk_0] [get_bd_pins rama_0/axi_aclk] [get_bd_pins axi_memory_init_0/aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_0/M03_ACLK] [get_bd_pins hbm_0/AXI_00_ACLK] [get_bd_pins hbm_0/AXI_01_ACLK] [get_bd_pins hbm_0/AXI_02_ACLK] [get_bd_pins hbm_0/AXI_03_ACLK] [get_bd_pins hbm_0/APB_0_PCLK] [get_bd_pins axi_interconnect_0/M04_ACLK] [get_bd_pins hbm_0/AXI_04_ACLK] [get_bd_pins axi_interconnect_0/M05_ACLK] [get_bd_pins hbm_0/AXI_05_ACLK] [get_bd_pins axi_interconnect_0/M06_ACLK] [get_bd_pins hbm_0/AXI_06_ACLK] [get_bd_pins axi_interconnect_0/M07_ACLK] [get_bd_pins hbm_0/AXI_07_ACLK] [get_bd_pins hbm_0/AXI_08_ACLK] [get_bd_pins hbm_0/AXI_09_ACLK] [get_bd_pins hbm_0/AXI_10_ACLK] [get_bd_pins hbm_0/AXI_11_ACLK] [get_bd_pins hbm_0/AXI_12_ACLK] [get_bd_pins hbm_0/AXI_13_ACLK] [get_bd_pins hbm_0/AXI_14_ACLK] [get_bd_pins hbm_0/AXI_15_ACLK] [get_bd_pins hbm_0/AXI_16_ACLK] [get_bd_pins hbm_0/AXI_17_ACLK] [get_bd_pins hbm_0/AXI_18_ACLK] [get_bd_pins hbm_0/AXI_19_ACLK] [get_bd_pins hbm_0/AXI_20_ACLK] [get_bd_pins hbm_0/AXI_21_ACLK] [get_bd_pins hbm_0/AXI_22_ACLK] [get_bd_pins hbm_0/AXI_23_ACLK] [get_bd_pins hbm_0/AXI_24_ACLK] [get_bd_pins hbm_0/AXI_25_ACLK] [get_bd_pins hbm_0/AXI_26_ACLK] [get_bd_pins hbm_0/AXI_27_ACLK] [get_bd_pins hbm_0/AXI_28_ACLK] [get_bd_pins hbm_0/AXI_29_ACLK] [get_bd_pins hbm_0/AXI_30_ACLK] [get_bd_pins hbm_0/AXI_31_ACLK] [get_bd_pins hbm_0/APB_1_PCLK] [get_bd_pins axi_interconnect_0/M08_ACLK] [get_bd_pins axi_interconnect_0/M09_ACLK] [get_bd_pins axi_interconnect_0/M10_ACLK] [get_bd_pins axi_interconnect_0/M11_ACLK] [get_bd_pins axi_interconnect_0/M12_ACLK] [get_bd_pins axi_interconnect_0/M13_ACLK] [get_bd_pins axi_interconnect_0/M14_ACLK] [get_bd_pins axi_interconnect_0/M15_ACLK] [get_bd_pins axi_interconnect_0/M16_ACLK] [get_bd_pins axi_interconnect_0/M17_ACLK] [get_bd_pins axi_interconnect_0/M18_ACLK] [get_bd_pins axi_interconnect_0/M19_ACLK] [get_bd_pins axi_interconnect_0/M20_ACLK] [get_bd_pins axi_interconnect_0/M21_ACLK] [get_bd_pins axi_interconnect_0/M22_ACLK] [get_bd_pins axi_interconnect_0/M23_ACLK] [get_bd_pins axi_interconnect_0/M24_ACLK] [get_bd_pins axi_interconnect_0/M25_ACLK] [get_bd_pins axi_interconnect_0/M26_ACLK] [get_bd_pins axi_interconnect_0/M27_ACLK] [get_bd_pins axi_interconnect_0/M28_ACLK] [get_bd_pins axi_interconnect_0/M29_ACLK] [get_bd_pins axi_interconnect_0/M30_ACLK] [get_bd_pins axi_interconnect_0/M31_ACLK]
  connect_bd_net -net axi_aresetn_0_1 [get_bd_ports axi_aresetn_0] [get_bd_pins rama_0/axi_aresetn] [get_bd_pins axi_memory_init_0/aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins axi_interconnect_0/M03_ARESETN] [get_bd_pins hbm_0/AXI_00_ARESET_N] [get_bd_pins hbm_0/AXI_01_ARESET_N] [get_bd_pins hbm_0/AXI_02_ARESET_N] [get_bd_pins hbm_0/AXI_03_ARESET_N] [get_bd_pins hbm_0/APB_0_PRESET_N] [get_bd_pins axi_interconnect_0/M04_ARESETN] [get_bd_pins hbm_0/AXI_04_ARESET_N] [get_bd_pins axi_interconnect_0/M05_ARESETN] [get_bd_pins hbm_0/AXI_05_ARESET_N] [get_bd_pins axi_interconnect_0/M06_ARESETN] [get_bd_pins hbm_0/AXI_06_ARESET_N] [get_bd_pins axi_interconnect_0/M07_ARESETN] [get_bd_pins hbm_0/AXI_07_ARESET_N] [get_bd_pins hbm_0/AXI_08_ARESET_N] [get_bd_pins hbm_0/AXI_09_ARESET_N] [get_bd_pins hbm_0/AXI_10_ARESET_N] [get_bd_pins hbm_0/AXI_11_ARESET_N] [get_bd_pins hbm_0/AXI_12_ARESET_N] [get_bd_pins hbm_0/AXI_13_ARESET_N] [get_bd_pins hbm_0/AXI_14_ARESET_N] [get_bd_pins hbm_0/AXI_15_ARESET_N] [get_bd_pins hbm_0/AXI_16_ARESET_N] [get_bd_pins hbm_0/AXI_17_ARESET_N] [get_bd_pins hbm_0/AXI_18_ARESET_N] [get_bd_pins hbm_0/AXI_19_ARESET_N] [get_bd_pins hbm_0/AXI_20_ARESET_N] [get_bd_pins hbm_0/AXI_21_ARESET_N] [get_bd_pins hbm_0/AXI_22_ARESET_N] [get_bd_pins hbm_0/AXI_23_ARESET_N] [get_bd_pins hbm_0/AXI_24_ARESET_N] [get_bd_pins hbm_0/AXI_25_ARESET_N] [get_bd_pins hbm_0/AXI_26_ARESET_N] [get_bd_pins hbm_0/AXI_27_ARESET_N] [get_bd_pins hbm_0/AXI_28_ARESET_N] [get_bd_pins hbm_0/AXI_29_ARESET_N] [get_bd_pins hbm_0/AXI_30_ARESET_N] [get_bd_pins hbm_0/AXI_31_ARESET_N] [get_bd_pins hbm_0/APB_1_PRESET_N] [get_bd_pins axi_interconnect_0/M08_ARESETN] [get_bd_pins axi_interconnect_0/M09_ARESETN] [get_bd_pins axi_interconnect_0/M10_ARESETN] [get_bd_pins axi_interconnect_0/M11_ARESETN] [get_bd_pins axi_interconnect_0/M12_ARESETN] [get_bd_pins axi_interconnect_0/M13_ARESETN] [get_bd_pins axi_interconnect_0/M14_ARESETN] [get_bd_pins axi_interconnect_0/M15_ARESETN] [get_bd_pins axi_interconnect_0/M16_ARESETN] [get_bd_pins axi_interconnect_0/M17_ARESETN] [get_bd_pins axi_interconnect_0/M18_ARESETN] [get_bd_pins axi_interconnect_0/M19_ARESETN] [get_bd_pins axi_interconnect_0/M20_ARESETN] [get_bd_pins axi_interconnect_0/M21_ARESETN] [get_bd_pins axi_interconnect_0/M22_ARESETN] [get_bd_pins axi_interconnect_0/M23_ARESETN] [get_bd_pins axi_interconnect_0/M24_ARESETN] [get_bd_pins axi_interconnect_0/M25_ARESETN] [get_bd_pins axi_interconnect_0/M26_ARESETN] [get_bd_pins axi_interconnect_0/M27_ARESETN] [get_bd_pins axi_interconnect_0/M28_ARESETN] [get_bd_pins axi_interconnect_0/M29_ARESETN] [get_bd_pins axi_interconnect_0/M30_ARESETN] [get_bd_pins axi_interconnect_0/M31_ARESETN]
  connect_bd_net -net axi_memory_init_0_init_complete_out [get_bd_pins axi_memory_init_0/init_complete_out] [get_bd_ports init_complete_out_0]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconstant_0/dout] [get_bd_pins axi_memory_init_0/init_complete_in]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_00/HBM_MEM00] -force
  assign_bd_address -offset 0x10000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_01/HBM_MEM01] -force
  assign_bd_address -offset 0x20000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_02/HBM_MEM02] -force
  assign_bd_address -offset 0x30000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_03/HBM_MEM03] -force
  assign_bd_address -offset 0x40000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_04/HBM_MEM04] -force
  assign_bd_address -offset 0x50000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_05/HBM_MEM05] -force
  assign_bd_address -offset 0x60000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_06/HBM_MEM06] -force
  assign_bd_address -offset 0x70000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_07/HBM_MEM07] -force
  assign_bd_address -offset 0x80000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_08/HBM_MEM08] -force
  assign_bd_address -offset 0x90000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_09/HBM_MEM09] -force
  assign_bd_address -offset 0xA0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_10/HBM_MEM10] -force
  assign_bd_address -offset 0xB0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_11/HBM_MEM11] -force
  assign_bd_address -offset 0xC0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_12/HBM_MEM12] -force
  assign_bd_address -offset 0xD0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_13/HBM_MEM13] -force
  assign_bd_address -offset 0xE0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_14/HBM_MEM14] -force
  assign_bd_address -offset 0xF0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_15/HBM_MEM15] -force
  assign_bd_address -offset 0x000100000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_16/HBM_MEM16] -force
  assign_bd_address -offset 0x000110000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_17/HBM_MEM17] -force
  assign_bd_address -offset 0x000120000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_18/HBM_MEM18] -force
  assign_bd_address -offset 0x000130000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_19/HBM_MEM19] -force
  assign_bd_address -offset 0x000140000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_20/HBM_MEM20] -force
  assign_bd_address -offset 0x000150000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_21/HBM_MEM21] -force
  assign_bd_address -offset 0x000160000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_22/HBM_MEM22] -force
  assign_bd_address -offset 0x000170000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_23/HBM_MEM23] -force
  assign_bd_address -offset 0x000180000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_24/HBM_MEM24] -force
  assign_bd_address -offset 0x000190000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_25/HBM_MEM25] -force
  assign_bd_address -offset 0x0001A0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_26/HBM_MEM26] -force
  assign_bd_address -offset 0x0001B0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_27/HBM_MEM27] -force
  assign_bd_address -offset 0x0001C0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_28/HBM_MEM28] -force
  assign_bd_address -offset 0x0001D0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_29/HBM_MEM29] -force
  assign_bd_address -offset 0x0001E0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_30/HBM_MEM30] -force
  assign_bd_address -offset 0x0001F0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces s_axi_0] [get_bd_addr_segs hbm_0/SAXI_31/HBM_MEM31] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""
