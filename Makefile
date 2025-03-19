default: vsim_cli

WORK_DIR = ${PWD}/runs/sim
LOG_PATH = ${WORK_DIR}/logs
WORK_PATH = ${WORK_DIR}/work

LIB_CMD = -work ${WORK_PATH}
VSIM_OPT = ${LIB_CMD} -64 -quiet +permissive
VLOG_OPT = ${VSIM_OPT} -nologo -svinputport=compat -timescale=1ns/1ns

clean:
	rm -rf ${WORK_DIR}/*

bender:
	bender script -t cv32a6_imac_sv0 -t test vsim > ${WORK_DIR}/compile.tcl

dirs:
	mkdir -p ${WORK_PATH}
	mkdir -p ${LOG_PATH}

lib: dirs
	vlib ${WORK_PATH}

vsim_dpi: lib
	vlog ${VSIM_OPT} -l ${LOG_PATH}/dpi.log ${PWD}/src/tests/dpi/elfloader.cc -ccflags "-I${PWD}/src/ips/ariane/verif/core-v-verif/vendor/riscv/riscv-isa-sim/ -I${PWD}/src/ips/ariane/verif/core-v-verif/lib/dpi_dasm/ -lfesvr -lriscv -lyaml-cpp -W -std=gnu++17"

vsim_build: lib vsim_dpi bender
	cd ${WORK_DIR} ; vsim ${VSIM_OPT} -l ${LOG_PATH}/build.log -c -do "source ${WORK_DIR}/compile.tcl; exit"

vsim_gui: vsim_build vsim_dpi
	cd ${WORK_DIR} ; vsim ${VSIM_OPT} -l ${LOG_PATH}/sim.log -suppress vsim-12110 -suppress vsim-3009 -suppress vsim-3584 -suppress vsim-3389 soc_tb -novopt

vsim_cli: vsim_build vsim_dpi
	cd ${WORK_DIR} ; vsim -c ${VSIM_OPT} -l ${LOG_PATH}/sim.log -do "vsim -suppress vsim-12110 -suppress vsim-3009 -suppress vsim-3584 -suppress vsim-3389 soc_tb -novopt"
