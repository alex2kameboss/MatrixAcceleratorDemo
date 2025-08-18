# usage: vivado -mode batch -source scripts/create_project.tcl -nojournal -nolog -tclargs '-noGui'

# parameters
package require cmdline

set parameters {
    {path.arg       "."         "Set path where to create vivado project, default current dir"}
    {name.arg       "unknown"   "Set vivado project name"}
    {threads.arg    "16"        "Number of threads for synthesis, in range [1, 16]"}
    {prfLogP.arg    "1"         "Polymorphic memory log P parameter"}
    {prfLogQ.arg    "2"         "Polymorphic memory log Q parameter"}
    {useUram                    "Use URAM for polymorphic memory"}
    {noGui                      "Do not open gui in the end, default off"}
}
set usage "- Script to simplify matrix accelerator design exploration"

puts $::argv

if {[catch {array set options [::cmdline::getoptions ::argv $parameters $usage]}]} {
    puts [::cmdline::usage $parameters $usage]
    exit
}

parray options

# project parameters
set PROJECT_NAME    $options(name)
set PROJECT_PATH    $options(path)
set THREADS         $options(threads)
set PRF_LOG_P       $options(prfLogP)
set PRF_LOG_Q       $options(prfLogQ)
set USE_URAM        $options(useUram)

create_project ${PROJECT_NAME} ${PROJECT_PATH} -part xcvu37p-fsvh2892-2L-e
set_property board_part xilinx.com:vcu128:part0:1.0 [current_project]

source ${PROJECT_PATH}/vivado.tcl
puts [get_property verilog_define [current_fileset]]
set_property verilog_define [concat [get_property verilog_define [current_fileset]] "PRF_LOG_P=${PRF_LOG_P}"] [current_fileset]
puts [get_property verilog_define [current_fileset]]
set_property verilog_define [concat [get_property verilog_define [current_fileset]] "PRF_LOG_Q=${PRF_LOG_Q}"] [current_fileset]
puts [get_property verilog_define [current_fileset]]

if { ${USE_URAM} } {
    set_property verilog_define [concat [get_property verilog_define [current_fileset]] USE_ULTRA_RAM] [current_fileset]
    puts [get_property verilog_define [current_fileset]]
}

# add missing files
add_files "
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/BramPort.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/AsyncDpRam.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/SyncSpRamBeNx64.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/AxiToAxiLitePc.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/AxiBramLogger.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/BramLogger.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/SyncSpRamBeNx32.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/SyncSpRam.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/SyncTpRam.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/BramDwc.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/SyncDpRam.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/SyncDpRam_ind_r_w.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/TdpBramArray.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/AsyncThreePortRam.sv 
    $ROOT/src/ips/ariane/vendor/pulp-platform/fpga-support/rtl/SyncThreePortRam.sv 
"

# add sdc
add_files -fileset constrs_1 -norecurse $ROOT/src/sdc/vivado_demo.sdc

# create ips
source $ROOT/scripts/vivado/hbm.tcl
source $ROOT/scripts/vivado/pll.tcl
source $ROOT/scripts/vivado/uart.tcl

# set top
set_property top top [current_fileset]
reorder_files -auto -disable_unused

# generate ips
generate_target all [get_ips]
synth_ip [get_ips]

# synthesis
set_property strategy Flow_RuntimeOptimized [get_runs synth_1]
update_compile_order -fileset sources_1
launch_runs synth_1 -jobs $THREADS
wait_on_run synth_1
open_run synth_1

set REPORTS_DIR             ${PROJECT_PATH}/reports
set SYNTHESIS_REPORTS_DIR   ${REPORTS_DIR}/synthesis/

exec mkdir -p ${SYNTHESIS_REPORTS_DIR}
report_utilization -hierarchical                                                                                    -file ${SYNTHESIS_REPORTS_DIR}/utilization.rpt
check_timing -verbose                                                                                               -file ${SYNTHESIS_REPORTS_DIR}/check_timing.rpt
report_timing_summary -delay_type max -max_paths 1                                                                  -file ${SYNTHESIS_REPORTS_DIR}/top_timing.rpt
report_timing_summary -delay_type max -max_paths 1 -cells [get_cells i_soc/i_core/i_matrix_accelerator/i_memory]    -file ${SYNTHESIS_REPORTS_DIR}/poly_mem_timing.rpt
report_timing_summary -delay_type max -max_paths 1 -cells [get_cells i_soc/i_core/i_matrix_accelerator]             -file ${SYNTHESIS_REPORTS_DIR}/matrix_acc_timing.rpt
report_ram_utilization -csv ${SYNTHESIS_REPORTS_DIR}/ram_util.csv                                                   -file ${SYNTHESIS_REPORTS_DIR}/ram_util.rpt

write_checkpoint ${PROJECT_PATH}/synth -force


set_property AUTO_INCREMENTAL_CHECKPOINT 1 [get_runs impl_1]
set_property strategy Flow_RuntimeOptimized [get_runs impl_1]
set_property -name {STEPS.PHYS_OPT_DESIGN.ARGS.MORE OPTIONS} -value -hold_fix -objects [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]

launch_runs impl_1 -jobs $THREADS
wait_on_run impl_1
open_run impl_1

set IMPL_REPORTS_DIR   ${REPORTS_DIR}/implementation/

exec mkdir -p ${IMPL_REPORTS_DIR}
report_utilization -hierarchical                                                                                    -file ${IMPL_REPORTS_DIR}/utilization.rpt
check_timing -verbose                                                                                               -file ${IMPL_REPORTS_DIR}/check_timing.rpt
report_timing_summary -delay_type max -max_paths 1                                                                  -file ${IMPL_REPORTS_DIR}/top_timing.rpt
report_timing_summary -delay_type max -max_paths 1 -cells [get_cells i_soc/i_core/i_matrix_accelerator/i_memory]    -file ${IMPL_REPORTS_DIR}/poly_mem_timing.rpt
report_timing_summary -delay_type max -max_paths 1 -cells [get_cells i_soc/i_core/i_matrix_accelerator]             -file ${IMPL_REPORTS_DIR}/matrix_acc_timing.rpt
report_ram_utilization -csv ${IMPL_REPORTS_DIR}/ram_util.csv                                                        -file ${IMPL_REPORTS_DIR}/ram_util.rpt

write_checkpoint ${PROJECT_PATH}/impl -force

set_property IS_ENABLED 0 [get_drc_checks {LUTLP-1}]
write_bitstream -force ${PROJECT_PATH}/${PROJECT_NAME}.bit

exit
