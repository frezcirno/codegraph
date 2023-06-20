.PHONY: default
default:
	git submodule update --init --recursive
	./configure --cc=wllvm
	$(MAKE) -j $(nproc)
	extract-bc build/qemu-system-x86_64 -o qemu.bc

clean:
	$(MAKE) clean