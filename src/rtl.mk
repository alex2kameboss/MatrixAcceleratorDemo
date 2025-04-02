SIM_DIR = ${PROJ_ROOT}/runs/sim
LOG_PATH = ${SIM_DIR}/logs
WORK_PATH = ${SIM_DIR}/work

VCS_DIR = ${PROJ_ROOT}/runs/vcs
VCS_LOG_PATH = ${VCS_DIR}/logs


LIB_CMD = -work ${WORK_PATH}
VSIM_OPT = ${LIB_CMD} -64 -quiet +permissive
VLOG_OPT = ${VSIM_OPT} -nologo -svinputport=compat -timescale=1ns/1ns

dirs:
	mkdir -p ${WORK_PATH}
	mkdir -p ${LOG_PATH}
	mkdir -p ${BUILD_DIR}

bender_vsim:
	bender script -D COMMON_CELLS_ASSERTS_OFF -t tech_cells_generic_include_tc_sram -t tech_cells_generic_include_tc_clk -t exclude_first_pass_decoder -t cv32a6_imac_sv0 -t demo_test -t rtl --vlog-arg="-suppress vlog-13528 -suppress vlog-13233 -svinputport=compat -timescale 1ns/1ns" vsim > ${SIM_DIR}/compile.tcl

lib: dirs
	vlib ${WORK_PATH}

vsim_dpi: lib
	vlog ${VSIM_OPT} -l ${LOG_PATH}/dpi.log ${PROJ_ROOT}/src/tests/dpi/elfloader.cc -ccflags "-I${PROJ_ROOT}/src/ips/ariane/verif/core-v-verif/vendor/riscv/riscv-isa-sim/ -I${PROJ_ROOT}/src/ips/ariane/verif/core-v-verif/lib/dpi_dasm/ -lfesvr -lriscv -lyaml-cpp -W -std=gnu++17"

vsim_build: lib vsim_dpi bender_vsim
	cd ${SIM_DIR} ; vsim ${VSIM_OPT} -l ${LOG_PATH}/build.log -c -do "source ${SIM_DIR}/compile.tcl; exit"

bender_vcs:
	bender script -D COMMON_CELLS_ASSERTS_OFF -t tech_cells_generic_include_tc_sram -t tech_cells_generic_include_tc_clk -t exclude_first_pass_decoder -t cv32a6_imac_sv0 -t demo_test -t rtl --vlog-arg="-svinputport=compat -override_timescale=1ns/1ns -work work" vcs > ${VCS_DIR}/compile.sh ; chmod +x ${VCS_DIR}/compile.sh

dpi_vcs:
	g++ -Wall -m64 -fPIC -I${PROJ_ROOT}/src/ips/ariane/verif/core-v-verif/vendor/riscv/riscv-isa-sim/ -I${PROJ_ROOT}/src/ips/ariane/verif/core-v-verif/lib/dpi_dasm/ -I$${VCS_HOME}/include -std=gnu++17 -shared -o ${VCS_DIR}/elfloader.so ${PROJ_ROOT}/src/tests/dpi/elfloader.cc

vcs_build: dpi_vcs bender_vcs
	cd ${VCS_DIR} ; ./compile.sh ; vcs -sverilog work.soc_tb -full64 elfloader.so -fgp -lca -j16 -O4

vcs_sim: vcs_build
	cd ${VCS_DIR} ; ./simv +PRELOAD=../build/app -fgp=num_threads:14

bender_vivado:
	bender script -D COMMON_CELLS_ASSERTS_OFF -t tech_cells_generic_include_tc_sram -t tech_cells_generic_include_tc_clk -t exclude_first_pass_decoder -t cv32a6_imac_sv0 -t rtl -t fpga -t xilinx vivado -t vcu128 > ${SIM_DIR}/../vivado.tcl
