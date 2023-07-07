.PHONY: default clean
default:
	sed -e "s|-O3|-O0|g" \
		-e "s|-O1|-O0|g" \
		-e "s|-Os|-O0|g" \
		-i configure
	./configure --cc=wllvm --extra-cflags="-fheinous-gnu-extensions" \
		$(shell ./configure --help | grep "disable compiler optimization" | awk '{print $$1}') \
		$(shell ./configure --help | grep "disable stripping" | awk '{print $$1}') \
		$(shell ./configure --help | grep "vulkan" | awk '{print $$1}')
	$(MAKE) -j $$(nproc)
	[ -f ffmpeg_g ] && extract-bc ffmpeg_g -o ffmpeg.bc || extract-bc avconv -o ffmpeg.bc

clean:
	$(MAKE) clean
