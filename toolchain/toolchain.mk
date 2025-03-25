TOOLCHAIN_DIR = ${PROJ_ROOT}/toolchain
RISCV = ${PROJ_ROOT}/toolchain/install

toolchain_dirs:
	mkdir -p ${RISCV}

clean_toolchain:
	rm -rf ${RISCV}
	cd ${TOOLCHAIN_DIR}/gcc ; \
		make clean

gcc: toolchain_dirs git_submodules
	cd ${TOOLCHAIN_DIR}/gcc ; \
		./configure --prefix=${RISCV} --disable-linux --with-arch=rv32imac ; \
		make -j$(nproc)