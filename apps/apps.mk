RISCV_GCC = ${RISCV}/bin/riscv32-unknown-elf-gcc
RISCV_CFLAGS = -lm -lgcc -march=rv32im_zicsr -mabi=ilp32 -static -mcmodel=medany -Wall -fvisibility=hidden -nostartfiles -ffreestanding
RISCV_LD_FLAGS = -Tapps/common/link.ld  -Wl,--print-memory-usage
RISCV_GCC_INCLUDES = -Iapps/common/include
RISCV_MIN_C_SOURCES = apps/common/crt0.S apps/common/printf.c apps/common/serial.c
GCC_ARGS ?= -DTEST_32

BUILD_DIR = ${PROJ_ROOT}/runs/build
APP_ELF = ${BUILD_DIR}/app

flash:
	${RISCV}/bin/riscv32-unknown-elf-objcopy -O binary ${APP_ELF} ${APP_ELF}.bin
	${RISCV}/bin/openocd -f apps/cfg/ma_sim_old.cfg -f apps/cfg/flash.tcl

app_dump:
	${RISCV}/bin/riscv32-unknown-elf-objdump -d ${APP_ELF} > ${BUILD_DIR}/dump.txt

hello_dummy_build: dirs
	${RISCV_GCC} ${RISCV_CFLAGS} ${RISCV_LD_FLAGS} ${RISCV_GCC_INCLUDES} apps/common/crt0.S apps/hello_world_dummy.c -o ${APP_ELF}

hello_printf_build: dirs
	${RISCV_GCC} ${RISCV_CFLAGS} ${RISCV_LD_FLAGS} ${RISCV_GCC_INCLUDES} ${RISCV_MIN_C_SOURCES} apps/hello_world_printf.c -o ${APP_ELF}

ma_ld_st_test_build:
	${RISCV_GCC} ${RISCV_CFLAGS} ${RISCV_LD_FLAGS} ${RISCV_GCC_INCLUDES} ${RISCV_MIN_C_SOURCES} apps/matrix_accelerator/ld_st_test.c -o ${APP_ELF}

ma_test_build:
	${RISCV_GCC} ${GCC_ARGS} -Wpointer-sign ${RISCV_CFLAGS} ${RISCV_LD_FLAGS} ${RISCV_GCC_INCLUDES} -Iapps/matrix_accelerator/include ${RISCV_MIN_C_SOURCES} apps/matrix_accelerator/ma_test.c -o ${APP_ELF}

generate_coe:
	cd ${BUILD_DIR} ; \
		${RISCV}/bin/riscv32-unknown-elf-objcopy -v --change-addresses -0x80000000 -O ihex app input_32.hex ; \
		srec_cat input_32.hex -Intel -output input.hex -Intel -Output_Block_Size 32 ; \
		tclsh ${PROJ_ROOT}/scripts/vivado/hex_to_coe.tcl