LLVM_COMPILER=clang
CC=wllvm
CFLAGS=-O0

PROJECT_PATH=projects/$(PROJECT)
PROJECT_BTCODE_BASE=output/$(PROJECT)/bitcode/$(REVISION)
PROJECT_RGRAPH_BASE=output/$(PROJECT)/$(ENTRY)/$(REVISION)
PROJECT_MAK=$(shell realpath $(PROJECT).mak)

.PHONY: default
default:
	@echo "Usage: make [PROJECT=ffmpeg|qemu|php-src|redis|linux] [REVISION=HEAD|<commit>] [bc|bitcode|png|clean]"

test.ok:
	@echo '#include<stdio.h>\nint main() { printf("Hello World!"); return 0; }' >test.c
	wllvm test.c -o test.ok
	-rm test.c .test.o .test.o.bc

%.ll: %.bc
	llvm-dis $<

%.csv: %.bc | llvmpass
	opt --enable-new-pm=0 -load llvmpass/build/libllvmpass.so -llvmpass $< >/dev/null 2>$@

$(PROJECT_RGRAPH_BASE).dot: $(PROJECT_BTCODE_BASE).csv csv2dot.py
	mkdir -p $(dir $@)
	python3 ./csv2dot.py $< $(ENTRY) >$@

%.png: %.dot
	timeout 30 dot -Tpng -Gdpi=300 -o $@ $<

.PHONY: llvmpass
llvmpass:
	$(MAKE) -C llvmpass

$(PROJECT_BTCODE_BASE).bc: | test.ok
	v1=$$(git -C $(PROJECT_PATH) rev-list -n 1 HEAD); \
	v2=$$(git -C $(PROJECT_PATH) rev-list -n 1 $(REVISION)); \
	if [ "$$v1" != "$$v2" ]; then \
		$(MAKE) -C $(PROJECT_PATH) -f $(PROJECT_MAK) clean || true ; \
		git -C $(PROJECT_PATH) clean -dfx ; \
		git -C $(PROJECT_PATH) restore . ; \
		git -C $(PROJECT_PATH) checkout $(REVISION) ; \
	fi
	CC=$(CC) CFLAGS="$(CFLAGS)" LLVM_COMPILER=$(LLVM_COMPILER) $(MAKE) -C $(PROJECT_PATH) -f $(PROJECT_MAK)
	mkdir -p $(dir $@)
	mv $(PROJECT_PATH)/$(PROJECT).bc $(PROJECT_BTCODE_BASE).bc

.PHONY: clean
clean:
	-$(MAKE) -C $(PROJECT_PATH) -f $(PROJECT_MAK) clean
	git -C $(PROJECT_PATH) clean -dfx
	git -C $(PROJECT_PATH) restore .

.PHONY: clean_all
clean_all:
	-rm -f test.ok
	-$(MAKE) -C llvmpass clean
	-$(MAKE) -C projects/ffmpeg -f ../../ffmpeg.mak clean
	-$(MAKE) -C projects/qemu -f ../../qemu.mak clean
	-$(MAKE) -C projects/php-src -f ../../php-src.mak clean
	-$(MAKE) -C projects/redis -f ../../redis.mak clean
	-$(MAKE) -C projects/imagemagick -f ../../imagemagick.mak clean
	-$(MAKE) -C projects/linux -f ../../linux.mak clean
	-$(MAKE) -C projects/openssl -f ../../openssl.mak clean

.PHONY: csv ll dot png bc bitcode
ll: $(PROJECT_BTCODE_BASE).ll
csv: $(PROJECT_BTCODE_BASE).csv
dot: $(PROJECT_RGRAPH_BASE).dot
png: $(PROJECT_RGRAPH_BASE).png
bc bitcode: $(PROJECT_BTCODE_BASE).bc
