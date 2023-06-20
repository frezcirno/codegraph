.PHONY: default clean
default:
	./configure --cc=wllvm
	$(MAKE) -j
	-[ -f ffmpeg_g ] && extract-bc ffmpeg_g -o ffmpeg.bc
	-[ -f avconv ] && extract-bc avconv -o ffmpeg.bc

clean:
	$(MAKE) clean
