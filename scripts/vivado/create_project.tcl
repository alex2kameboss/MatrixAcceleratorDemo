# usage: vivado -mode batch -source scripts/create_project.tcl -nojournal -nolog -tclargs '-noGui'

# parameters
package require cmdline

set parameters {
    {path.arg       "."     "Set path where to create vivado project, default current dir"}
    {threads.arg    "16"    "Number of threads for synthesis, in range [1, 16]"}
    {prfLogP.arg    "1"     "Polymorphic memory log P parameter"}
    {prfLogQ.arg    "2"     "Polymorphic memory log Q parameter"}
    {useUram                "Use URAM for polymorphic memory"}
    {noGui                  "Do not open gui in the end, default off"}
}
set usage "- Script to simplify matrix accelerator design exploration"

puts $::argv

if {[catch {array set options [::cmdline::getoptions ::argv $parameters $usage]}]} {
    puts [::cmdline::usage $parameters $usage]
    exit
}

parray options

# project parameters
set PATH            $options(path)
set THREADS         $options(threads)
set PRF_LOG_P       $options(prfLogP)
set PRF_LOG_Q       $options(prfLogQ)
set USE_URAM        $options(useUram)

set PROJECT_NAME "run_[clock format [clock seconds] -format {%d-%m-%Y-%H%M%S}]"
set PROJECT_PATH "${PATH}/${PROJECT_NAME}"

exec mkdir -p ${PROJECT_PATH}

create_project ${PROJECT_NAME} ${PROJECT_PATH} -part xcvu37p-fsvh2892-2L-e
set_property board_part xilinx.com:vcu128:part0:1.0 [current_project]

source ${PATH}/vivado.tcl
puts [get_property verilog_define [current_fileset]]
set_property verilog_define [lappend {*}[get_property verilog_define [current_fileset]] "PRF_LOG_P=${PRF_LOG_P}"] [current_fileset]
puts [get_property verilog_define [current_fileset]]
set_property verilog_define [lappend {*}[get_property verilog_define [current_fileset]] "PRF_LOG_Q=${PRF_LOG_Q}"] [current_fileset]
puts [get_property verilog_define [current_fileset]]

if { ${USE_URAM} } {
    set_property verilog_define [lappend {*}[get_property verilog_define [current_fileset]] USE_ULTRA_RAM] [current_fileset]
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
update_compile_order -fileset sources_1
synth_design
launch_runs synth_1 -jobs $THREADS
wait_on_run synth_1
open_run synth_1

exec mkdir -p ${PROJECT_PATH}/reports/
report_utilization -hierarchical                                                                                    -file ${PROJECT_PATH}/reports/utilization.rpt
check_timing -verbose                                                                                               -file ${PROJECT_PATH}/reports/check_timing.rpt
report_timing_summary -delay_type max -max_paths 1                                                                  -file ${PROJECT_PATH}/reports/top_timing.rpt
report_timing_summary -delay_type max -max_paths 1 -cells [get_cells i_soc/i_core/i_matrix_accelerator/i_memory]    -file ${PROJECT_PATH}/reports/poly_mem_timing.rpt
report_timing_summary -delay_type max -max_paths 1 -cells [get_cells i_soc/i_core/i_matrix_accelerator]             -file ${PROJECT_PATH}/reports/matrix_acc_timing.rpt

exit