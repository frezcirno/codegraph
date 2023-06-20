.PHONY: default
default:
	./buildconf --force
	CC=wllvm ./configure
	$(MAKE) -j
	extract-bc sapi/cli/php -o php-src.bc

clean:
	$(MAKE) clean
	$(MAKE) distclean
	rm configure
