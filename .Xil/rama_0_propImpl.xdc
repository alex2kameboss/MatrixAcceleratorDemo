set_property SRC_FILE_INFO {cfile:/tools/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_memory/tcl/xpm_memory_xdc.tcl rfile:../../../../../tools/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_memory/tcl/xpm_memory_xdc.tcl id:1 order:LATE scoped_inst:U0/rama_read_core_inst/rama_read_reorder_core_inst/rama_read_reorder_mem_inst/xpm_memory_sdpram_inst unmanaged:yes} [current_design]
set_property SRC_FILE_INFO {cfile:/tools/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_memory/tcl/xpm_memory_xdc.tcl rfile:../../../../../tools/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_memory/tcl/xpm_memory_xdc.tcl id:2 order:LATE scoped_inst:U0/rama_write_core_inst/rama_write_reorder_core_inst/rama_write_reorder_mem_inst/xpm_memory_sdpram_inst unmanaged:yes} [current_design]
current_instance U0/rama_read_core_inst/rama_read_reorder_core_inst/rama_read_reorder_mem_inst/xpm_memory_sdpram_inst
set_property src_info {type:SCOPED_XDC file:1 line:55 export:INPUT save:NONE read:READ} [current_design]
set my_var [get_property dram_emb_xdc [get_cells -quiet -hier -filter {PRIMITIVE_SUBGROUP==LUTRAM || PRIMITIVE_SUBGROUP==dram || PRIMITIVE_SUBGROUP==uram || PRIMITIVE_SUBGROUP==BRAM}]]
current_instance
current_instance U0/rama_write_core_inst/rama_write_reorder_core_inst/rama_write_reorder_mem_inst/xpm_memory_sdpram_inst
set_property src_info {type:SCOPED_XDC file:2 line:55 export:INPUT save:NONE read:READ} [current_design]
set my_var [get_property dram_emb_xdc [get_cells -quiet -hier -filter {PRIMITIVE_SUBGROUP==LUTRAM || PRIMITIVE_SUBGROUP==dram || PRIMITIVE_SUBGROUP==uram || PRIMITIVE_SUBGROUP==BRAM}]]
