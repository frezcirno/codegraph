.PHONY: default clean
default:
	sed -e 's|HOSTCC	= clang|HOSTCC	= wllvm|g' \
		-e 's|HOSTCXX	= clang|HOSTCXX	= wllvm|g' \
		-e 's|CC		= clang|CC	= wllvm|g' \
		-e 's|HOSTCC	= $$(LLVM_PREFIX)clang$$(LLVM_SUFFIX)|HOSTCC	= wllvm|g' \
		-e 's|HOSTCXX	= $$(LLVM_PREFIX)clang++$$(LLVM_SUFFIX)|HOSTCXX	= wllvm|g' \
		-e 's|CC		= $$(LLVM_PREFIX)clang$$(LLVM_SUFFIX)|CC	= wllvm|g' \
		-i Makefile
	-patch -N -p1 < ../../1d489151e9f9d1647110277ff77282fe4d96d09b.patch
	$(MAKE) LLVM=1 defconfig
	sed -e 's|CONFIG_LD_ORPHAN_WARN_LEVEL="error"|CONFIG_LD_ORPHAN_WARN_LEVEL="warn"|g' \
	    -e 's|CONFIG_WERROR=y|CONFIG_WERROR=n|g' \
		-i .config
	$(MAKE) LLVM=1 vmlinux -j $$(nproc)
	extract-bc vmlinux -o linux.bc

clean:
	$(MAKE) clean
	$(MAKE) distclean
	$(MAKE) mrproper

