.PHONY: default
default:
	sed -i 's|git://git.qemu-project.org|git@gitlab.com:qemu-project|g' .gitmodules .git/config
	-git submodule update --init --recursive
	./configure --cc=wllvm
	$(MAKE) -j $$(nproc)
	extract-bc build/qemu-system-x86_64 -o qemu.bc

clean:
	$(MAKE) clean