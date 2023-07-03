.PHONY: default
default:
	./buildconf --force
	# if failed, install bison-2.5, or bison-2.7
	# if failed, install libxml2-v2.8.0
	# before bison-2.7 workaround: sed -i "s|_IO_ftrylockfile|_IO_EOF_SEEN|g" lib/fseterr.c
	# before bison-2.5 workaround: sed -i 's|_GL_WARN_ON_USE (gets, "gets is a security hole - use fgets instead");|// _GL_WARN_ON_USE (gets, "gets is a security hole - use fgets instead");|g' lib/stdio.h
	./configure
	$(MAKE) -j $$(nproc)
	extract-bc sapi/cli/php -o php-src.bc

clean:
	$(MAKE) clean
	$(MAKE) distclean
	rm configure
