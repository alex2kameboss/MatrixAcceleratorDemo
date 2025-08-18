TOOLCHAIN_DIR = ${PROJ_ROOT}/toolchain
RISCV = ${PROJ_ROOT}/toolchain/install

toolchain_dirs:
	mkdir -p ${RISCV}

clean_toolchain:
	rm -rf ${RISCV}
	cd ${TOOLCHAIN_DIR}/gcc ; \
		make clean
	rm -rf toolchain/openocd

gcc: toolchain_dirs git_submodules
	cd ${TOOLCHAIN_DIR}/gcc ; \
		./configure --prefix=${RISCV} --disable-linux --with-arch=rv32imac_zicsr ; \
		make -j$(nproc)

openocd:
	git clone https://github.com/riscv-collab/riscv-openocd.git toolchain/openocd
	cd toolchain/openocd ; \
		git checkout af3a034b57279d2a400d87e7508c9a92254ec165 ; \
		git apply ../openocd.patch ; \
		./bootstrap ; \
		./configure --prefix=${RISCV} --disable-werror --disable-wextra --enable-remote-bitbang --enable-ftdi ; \
		make -j$(nproc) ; \
		make install