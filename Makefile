default: sim hello_dummy_build

PROJ_ROOT = $(PWD)

include toolchain/toolchain.mk
include src/rtl.mk
include apps/apps.mk

LOG_FILE ?= sim.log
VSIM_CMD = vsim soc_tb +PRELOAD=${APP_ELF} -suppress vsim-8315

clean:
	rm -rf ${SIM_DIR}/* ${BUILD_DIR}

git_submodules:
	git submodule init 
	git submodule update

vsim_gui: vsim_build
	cd ${SIM_DIR} ; vsim -l ${LOG_PATH}/sim.log -do "${VSIM_CMD} -voptargs=+acc"

vsim_cli: vsim_build
	cd ${SIM_DIR} ; vsim -c -l ${LOG_PATH}/sim.log -do "${VSIM_CMD} -voptargs=+acc"

sim: vsim_build
	cd ${SIM_DIR} ; vsim -c -l ${LOG_PATH}/${LOG_FILE} -do "${VSIM_CMD} ; run -a"
