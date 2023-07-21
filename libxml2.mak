.PHONY: default
default:
	./autogen.sh
	$(MAKE) -j $$(nproc)
	extract-bc sapi/cli/php -o php-src.bc

clean:
	$(MAKE) clean
	$(MAKE) distclean
