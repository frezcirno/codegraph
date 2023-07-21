.PHONY: default clean
default:
	sed -e 's|^HOSTCC.*=.*$$|HOSTCC = wllvm|g' \
		-e 's|^HOSTCXX.*=.*$$|HOSTCXX = wllvm|g' \
		-e 's|^CC.*=.*$$|CC = wllvm|g' \
		-i Makefile
	# -sed -e 's|-maccumulate-outgoing-args||g' \
	# 	-i arch/x86/Makefile_32
	# -sed -e 's|-maccumulate-outgoing-args||g' \
	# 	-i arch/x86/Makefile_64
	-patch -N -t -p1 < ../../1d489151e9f9d1647110277ff77282fe4d96d09b.patch -o /dev/null -r /dev/null
	-patch -N -t -p1 < ../../dfbd199a7cfe3e3cd8531e1353cdbd7175bfbc5e.patch -o /dev/null -r /dev/null
	# -patch -N -t -p1 < ../../22636f8c9511245cb3c8412039f1dd95afb3aa59.patch -o /dev/null -r /dev/null
	-grep 'char \*stpcpy(char' lib/string.c || \
		patch -N -t -p1 < ../../5934637641c863cc2c1765a0d01c5b6f53ecc4fc.patch -o /dev/null -r /dev/null
	$(MAKE) LLVM=1 defconfig
	sed -e 's|CONFIG_LD_ORPHAN_WARN_LEVEL="error"|CONFIG_LD_ORPHAN_WARN_LEVEL="warn"|g' \
	    -e 's|CONFIG_WERROR=y|CONFIG_WERROR=n|g' \
	    -e 's|CONFIG_JUMP_LABEL=.*|CONFIG_JUMP_LABEL=n|g' \
		-i .config
	KCFLAGS=" -fno-pie -no-integrated-as" $(MAKE) LLVM=1 V=1 vmlinux -j $$(nproc)
	extract-bc vmlinux -o linux.bc

clean:
	$(MAKE) clean
	$(MAKE) distclean
	$(MAKE) mrproper

