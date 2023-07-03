.PHONY: default
default:
	-sed -i "s|qw/glob/|qw/:glob/|g" Configure test/build.info
	CC="wllvm -O0" ./config -d
	$(MAKE) -j $$(nproc)
	extract-bc ./apps/openssl -o openssl.bc

clean:
	$(MAKE) clean
	$(MAKE) distclean
