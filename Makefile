LLVM_COMPILER=clang
CC=wllvm
CFLAGS=-O0

PROJECT_PATH=projects/$(PROJECT)
BTCODE_BASE=output/$(PROJECT)/bitcode
BTCODE_REV=$(BTCODE_BASE)/$(REVISION)
BTCODE_REV2=$(BTCODE_BASE)/$(REVISION2)
PROJECT_ENTRY_BASE=output/$(PROJECT)/$(ENTRY)
RGRAPH_REV=$(PROJECT_ENTRY_BASE)/$(REVISION)$(RGRAPH_SPEC_SUFFIX)
RGRAPH_REV2=$(PROJECT_ENTRY_BASE)/$(REVISION2)$(RGRAPH_SPEC_SUFFIX)
RGRAPH_REVDIFF=$(PROJECT_ENTRY_BASE)/$(REVISION)-$(REVISION2)$(RGRAPH_SPEC_SUFFIX)
PROJECT_MAK=$(shell realpath $(PROJECT).mak)
PRELEVEL ?= 3
POSTLEVEL ?= 3
SIBILING ?= 1

# "-x-x-x" if not PRELEVEL=3, POSTLEVEL=3, SIBILING=1
RGRAPH_SPEC_SUFFIX=$(shell if [ "$(PRELEVEL)" = "3" -a "$(POSTLEVEL)" = "3" -a "$(SIBILING)" = "1" ]; then echo ""; else echo "-$(PRELEVEL)-$(POSTLEVEL)-$(SIBILING)"; fi)

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
	opt --enable-new-pm=0 -load llvmpass/build/libllvmpass.so -refgraph $< >/dev/null 2>$@

$(RGRAPH_REV).dot: $(BTCODE_REV).csv csv2dot.py
	mkdir -p $(dir $@)
	python3 ./csv2dot.py $< $(ENTRY) >$@

$(RGRAPH_REV2).dot: $(BTCODE_REV2).csv csv2dot.py
	mkdir -p $(dir $@)
	python3 ./csv2dot.py $< $(ENTRY) >$@

$(RGRAPH_REVDIFF).dot: $(RGRAPH_REV).dot $(RGRAPH_REV2).dot | dotdiff.py
	mkdir -p $(dir $@)
	python3 ./dotdiff.py $^ >$@

%.png: %.dot
	timeout 30 dot -Tpng -Gdpi=300 -o $@ $<

.PHONY: llvmpass
llvmpass:
	$(MAKE) -C llvmpass

$(BTCODE_REV).bc: | test.ok
	v1=$$(git -C $(PROJECT_PATH) rev-list -n 1 HEAD); \
	v2=$$(git -C $(PROJECT_PATH) rev-list -n 1 $(REVISION)); \
	if [ "$$v1" != "$$v2" ]; then \
		$(MAKE) -C $(PROJECT_PATH) -f $(PROJECT_MAK) clean || true ; \
		git -C $(PROJECT_PATH) restore --staged . ; \
		git -C $(PROJECT_PATH) restore . ; \
		git -C $(PROJECT_PATH) clean -dfx ; \
		git -C $(PROJECT_PATH) checkout $(REVISION) ; \
	fi
	CC=$(CC) CFLAGS="$(CFLAGS)" LLVM_COMPILER=$(LLVM_COMPILER) $(MAKE) -C $(PROJECT_PATH) -f $(PROJECT_MAK)
	mkdir -p $(dir $@)
	mv $(PROJECT_PATH)/$(PROJECT).bc $(BTCODE_REV).bc

.PHONY: clean
clean:
	-$(MAKE) -C $(PROJECT_PATH) -f $(PROJECT_MAK) clean
	git -C $(PROJECT_PATH) restore --staged .
	git -C $(PROJECT_PATH) restore .
	git -C $(PROJECT_PATH) clean -dfx
	-rm $(BTCODE_REV).bc $(BTCODE_REV).ll $(BTCODE_REV).csv \
		$(BTCODE_REV2).bc $(BTCODE_REV2).ll $(BTCODE_REV2).csv

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

.PHONY: csv ll png diff bc bitcode
ll: $(BTCODE_REV).ll
csv: $(BTCODE_REV).csv
png: $(RGRAPH_REV).png
diff: $(RGRAPH_REVDIFF).png
bc bitcode: $(BTCODE_REV).bc
