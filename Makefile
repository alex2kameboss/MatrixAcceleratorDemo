default: hello_dummy_build vsim_cli

WORK_DIR = ${PWD}/runs/sim
LOG_PATH = ${WORK_DIR}/logs
WORK_PATH = ${WORK_DIR}/work

BUILD_DIR = ${PWD}/runs/build

LIB_CMD = -work ${WORK_PATH}
VSIM_OPT = ${LIB_CMD} -64 -quiet +permissive
VLOG_OPT = ${VSIM_OPT} -nologo -svinputport=compat -timescale=1ns/1ns

RISCV_GCC = ../RISC-V/install/bin/riscv32-unknown-elf-gcc
RISCV_CFLAGS = -lm -lgcc -march=rv32im -mabi=ilp32 -static -mcmodel=medany -Wall -fvisibility=hidden -nostartfiles -ffreestanding
RISCV_LD_FLAGS = -Tapps/common/link.ld
RISCV_GCC_INCLUDES = -Iapps/common/include
RISCV_MIN_C_SOURCES = apps/common/crt0.S apps/common/printf.c apps/common/serial.c

APP_ELF = ${PWD}/runs/build/app

VSIM_CMD = vsim soc_tb +PRELOAD=${APP_ELF} -voptargs=+acc

clean:
	rm -rf ${WORK_DIR}/* ${BUILD_DIR}

bender:
	bender script -D COMMON_CELLS_ASSERTS_OFF -t tech_cells_generic_include_tc_sram -t tech_cells_generic_include_tc_clk -t exclude_first_pass_decoder -t cv32a6_imac_sv0 -t demo_test -t rtl --vlog-arg="-suppress vlog-13528 -suppress vlog-13233 -svinputport=compat -timescale 1ns/1ns" vsim > ${WORK_DIR}/compile.tcl

dirs:
	mkdir -p ${WORK_PATH}
	mkdir -p ${LOG_PATH}
	mkdir -p ${BUILD_DIR}

lib: dirs
	vlib ${WORK_PATH}

hello_dummy_build: dirs
	${RISCV_GCC} ${RISCV_CFLAGS} ${RISCV_LD_FLAGS} ${RISCV_GCC_INCLUDES} apps/common/crt0.S apps/hello_world_dummy.c -o ${APP_ELF}

hello_printf_build: dirs
	${RISCV_GCC} ${RISCV_CFLAGS} ${RISCV_LD_FLAGS} ${RISCV_GCC_INCLUDES} ${RISCV_MIN_C_SOURCES} apps/hello_world_dummy.c -o ${APP_ELF}

vsim_dpi: lib
	vlog ${VSIM_OPT} -l ${LOG_PATH}/dpi.log ${PWD}/src/tests/dpi/elfloader.cc -ccflags "-I${PWD}/src/ips/ariane/verif/core-v-verif/vendor/riscv/riscv-isa-sim/ -I${PWD}/src/ips/ariane/verif/core-v-verif/lib/dpi_dasm/ -lfesvr -lriscv -lyaml-cpp -W -std=gnu++17"

vsim_build: lib vsim_dpi bender
	cd ${WORK_DIR} ; vsim ${VSIM_OPT} -l ${LOG_PATH}/build.log -c -do "source ${WORK_DIR}/compile.tcl; exit"

vsim_gui: vsim_build vsim_dpi
	cd ${WORK_DIR} ; vsim -l ${LOG_PATH}/sim.log -do "${VSIM_CMD}"

vsim_cli: vsim_build vsim_dpi
	cd ${WORK_DIR} ; vsim -c -l ${LOG_PATH}/sim.log -do "${VSIM_CMD}"
