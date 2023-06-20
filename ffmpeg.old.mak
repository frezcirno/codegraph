REV=n6.0

.PHONY: default
default: LLVMHello.so ffmpeg-$(REV).bc
	-opt -load ./LLVMHello.so -fcg ffmpeg-$(REV).bc -enable-new-pm=0 >/dev/null 2>ffmpeg-$(REV)_fcg.csv

*.ll: *.bc
	llvm-dis $<

.PHONY: disas
disas: ffmpeg-$(REV).ll

LLVMHello.so: fcg_pass.cpp CMakeLists.txt
	mkdir -p build
	cd build && cmake .. -DCMAKE_EXPORT_COMPILE_COMMANDS=1 && $(MAKE)
	mv build/compile_commands.json build/LLVMHello.so .

ffmpeg-$(REV).bc: ffmpeg_build-$(REV) ffmpeg_libs-$(REV)
	-cd ffmpeg && llvm-link -o ffmpeg.bc \
				fftools/*.o \
				libavdevice.bc libavfilter.bc libavformat.bc libavcodec.bc libswresample.bc # libavutil.bc libswscale.bc
	-cd ffmpeg && llvm-link -o ffmpeg.bc \
				*.o \
				libavdevice.bc libavfilter.bc libavformat.bc libavcodec.bc libswresample.bc # libavutil.bc libswscale.bc
	mv ffmpeg/ffmpeg.bc ffmpeg-$(REV).bc

.PHONY: ffmpeg_libs-$(REV)
ffmpeg_libs-$(REV): ffmpeg_build-$(REV)
	cd ffmpeg && llvm-link libavdevice/*.o -o libavdevice.bc
	cd ffmpeg && llvm-link libavfilter/*.o -o libavfilter.bc
	cd ffmpeg && llvm-link libavformat/*.o -o libavformat.bc
	cd ffmpeg && llvm-link libavcodec/*.o -o libavcodec.bc
	cd ffmpeg && llvm-link libswresample/*.o -o libswresample.bc
	cd ffmpeg && llvm-link libswscale/*.o -o libswscale.bc
	cd ffmpeg && llvm-link libavutil/*.o -o libavutil.bc

.PHONY: ffmpeg_build-$(REV)
ffmpeg_build-$(REV):
	cd ffmpeg ; \
		git checkout $(REV) && git clean -df
	cd ffmpeg ; \
		./configure --cc=clang --extra-cflags="-g" --optflags="-O0" --disable-doc --disable-stripping --disable-x86asm --disable-ffprobe --disable-ffplay --disable-ffserver || \
		./configure --cc=clang --extra-cflags="-g" --optflags="-O0" --disable-doc --disable-stripping --disable-x86asm --disable-ffprobe --disable-ffplay || \
		./configure --cc=clang --extra-cflags="-g" --optflags="-O0" --disable-doc --disable-stripping --disable-yasm --disable-ffprobe --disable-ffplay --disable-ffserver
	-cd ffmpeg ; \
		sed -i -e 's/^CFLAGS=/CFLAGS= -emit-llvm/g' config.mak ffbuild/config.mak
	-cd ffmpeg ; $(MAKE) -j16

.PHONY: clean
clean:
	# -rm -rf build
	# -rm -f LLVMHello.so compile_commands.json
	$(MAKE) -C ffmpeg clean
	-rm -f ffmpeg-$(REV).bc ffprobe-$(REV).bc ffplay-$(REV).bc \
			ffmpeg-$(REV).ll ffprobe-$(REV).ll ffplay-$(REV).ll \
			ffmpeg-$(REV)_fcg.csv ffprobe-$(REV)_fcg.csv ffplay-$(REV)_fcg.csv
