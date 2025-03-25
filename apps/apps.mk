RISCV_GCC = ${RISCV}/bin/riscv32-unknown-elf-gcc
RISCV_CFLAGS = -lm -lgcc -march=rv32im -mabi=ilp32 -static -mcmodel=medany -Wall -fvisibility=hidden -nostartfiles -ffreestanding
RISCV_LD_FLAGS = -Tapps/common/link.ld
RISCV_GCC_INCLUDES = -Iapps/common/include
RISCV_MIN_C_SOURCES = apps/common/crt0.S apps/common/printf.c apps/common/serial.c

BUILD_DIR = ${PROJ_ROOT}/runs/build
APP_ELF = ${BUILD_DIR}/app

hello_dummy_build: dirs
	${RISCV_GCC} ${RISCV_CFLAGS} ${RISCV_LD_FLAGS} ${RISCV_GCC_INCLUDES} apps/common/crt0.S apps/hello_world_dummy.c -o ${APP_ELF}

hello_printf_build: dirs
	${RISCV_GCC} ${RISCV_CFLAGS} ${RISCV_LD_FLAGS} ${RISCV_GCC_INCLUDES} ${RISCV_MIN_C_SOURCES} apps/hello_world_dummy.c -o ${APP_ELF}

ma_ld_st_test_build:
	${RISCV_GCC} ${RISCV_CFLAGS} ${RISCV_LD_FLAGS} ${RISCV_GCC_INCLUDES} ${RISCV_MIN_C_SOURCES} apps/matrix_accelerator/ld_st_test.c -o ${APP_ELF}
