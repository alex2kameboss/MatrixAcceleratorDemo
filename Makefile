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
	bender script -D COMMON_CELLS_ASSERTS_OFF -t tech_cells_generic_include_tc_sram -t tech_cells_generic_include_tc_clk -t exclude_first_pass_decoder -t cv32a6_imac_sv0 -t demo_test -t rtl --vlog-arg="-suppress vlog-13528 -suppress vlog-13233 -svinputport=compat -timescale 1ns/1ns" vsim > ${WORK_DIR}/compile.tcl

dirs:
	mkdir -p ${WORK_PATH}
	mkdir -p ${LOG_PATH}

lib: dirs
	vlib ${WORK_PATH}

hello_build:
	#../RISC-V/install/bin/riscv32-unknown-elf-gcc -mabi=ilp32 -mcmodel=medany -static -nostartfiles -lm -Wl,--gc-sections -ffunction-sections -fdata-sections -lgcc -march=rv32im -fno-common -fno-builtin-printf -Iapps/common/printf -Tapps/common/soc.ld apps/hello_world.c apps/common/printf/*.c -o runs/build/hello
	#../RISC-V/install/bin/riscv32-unknown-elf-gcc -O3 -ffast-math -mcmodel=medany -static -nostartfiles -lm -Wl,--gc-sections -ffunction-sections -fdata-sections -lgcc -march=rv32im -fno-common -fno-builtin-printf -Iapps/common/printf -Tsrc/ips/ariane/config/gen_from_riscv_config/cv32a60x/linker/link.ld apps/hello_world.c apps/common/printf/*.c -o runs/build/hello
	../RISC-V/install/bin/riscv32-unknown-elf-gcc -mcmodel=medany -march=rv32im -mabi=ilp32 -static -std=gnu99 -O3 -ffast-math -fno-common -fno-builtin-printf -nostartfiles -lm -lgcc -Tapps/common/soc.ld  -Iapps/common/printf apps/hello_world.c apps/common/printf/*.c -o runs/build/hello

vsim_dpi: lib
	vlog ${VSIM_OPT} -l ${LOG_PATH}/dpi.log ${PWD}/src/tests/dpi/elfloader.cc -ccflags "-I${PWD}/src/ips/ariane/verif/core-v-verif/vendor/riscv/riscv-isa-sim/ -I${PWD}/src/ips/ariane/verif/core-v-verif/lib/dpi_dasm/ -lfesvr -lriscv -lyaml-cpp -W -std=gnu++17"

vsim_build: lib vsim_dpi bender
	cd ${WORK_DIR} ; vsim ${VSIM_OPT} -l ${LOG_PATH}/build.log -c -do "source ${WORK_DIR}/compile.tcl; exit"

vsim_gui: vsim_build vsim_dpi
	cd ${WORK_DIR} ; vsim -l ${LOG_PATH}/sim.log -c "vsim soc_tb +PRELOAD=/home/alex/Isolde/MatrixAcceleratorDemo/runs/build/hello +UVM_NO_RELNOTES -voptargs=+acc"

vsim_cli: vsim_build vsim_dpi
	cd ${WORK_DIR} ; vsim -c -l ${LOG_PATH}/sim.log -do "vsim soc_tb +PRELOAD=/home/alex/Isolde/MatrixAcceleratorDemo/runs/build/hello +UVM_NO_RELNOTES -voptargs=+acc"
