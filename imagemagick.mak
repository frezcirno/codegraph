.PHONY: default
default:
	./configure
	$(MAKE) -j $$(nproc)
	find ./MagickCore/.libs/ -name 'libMagickCore-*.so.*' -exec extract-bc {} -o imagemagick.bc \;

clean:
	$(MAKE) clean
	$(MAKE) distclean
