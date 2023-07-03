.PHONY: default clean
default:
	./configure --cc=wllvm --extra-cflags="-fheinous-gnu-extensions" \
		$(shell ./configure --help | grep "disable compiler optimization" | awk '{print $$1}') \
		$(shell ./configure --help | grep vulkan | awk '{print $$1}')
	$(MAKE) -j $$(nproc)
	[ -f ffmpeg_g ] && extract-bc ffmpeg_g -o ffmpeg.bc || extract-bc avconv -o ffmpeg.bc

clean:
	$(MAKE) clean
