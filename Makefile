LLVM_COMPILER=clang
CC=wllvm
# CFLAGS=-O0

ifeq ($(PROJECT),)
$(error PROJECT is not set)
endif
ifeq ($(REVISION),)
$(error REVISION is not set)
endif

PROJECT_SRC=projects/$(PROJECT)
PROJECT_OUTPUT=output/$(PROJECT)
PROJECT_ENTRY_OUTPUT=$(PROJECT_OUTPUT)/$(ENTRY)

BITCODE_OUTPUT=$(PROJECT_OUTPUT)/bitcode
BITCODE=$(BITCODE_OUTPUT)/$(REVISION)
BITCODE2=$(BITCODE_OUTPUT)/$(REVISION2)
ALL_BITCODE=$(BITCODE).bc $(BITCODE2).bc
ALL_BITCODE_CSV=$(BITCODE).csv $(BITCODE2).csv

RGRAPH1=$(PROJECT_ENTRY_OUTPUT)/$(REVISION)$(RGRAPH_SPEC_SUFFIX)
RGRAPH2=$(PROJECT_ENTRY_OUTPUT)/$(REVISION2)$(RGRAPH_SPEC_SUFFIX)
ALL_RGRAPH_DOTS=$(RGRAPH1).dot $(RGRAPH2).dot
RGRAPH_REVDIFF=$(PROJECT_ENTRY_OUTPUT)/$(REVISION)-$(REVISION2)$(RGRAPH_SPEC_SUFFIX)

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

$(ALL_BITCODE_CSV): %.csv: %.bc | llvmpass
	opt --enable-new-pm=0 -load llvmpass/build/libllvmpass.so -refgraph $< >/dev/null 2>$@

$(ALL_RGRAPH_DOTS): $(PROJECT_ENTRY_OUTPUT)/%$(RGRAPH_SPEC_SUFFIX).dot: $(BITCODE_OUTPUT)/%.csv csv2dot.py
	mkdir -p $(dir $@)
	python3 ./csv2dot.py $< $(ENTRY) >$@

$(RGRAPH_REVDIFF).dot: $(RGRAPH1).dot $(RGRAPH2).dot dotdiff.py
	mkdir -p $(dir $@)
	python3 ./dotdiff.py $^ >$@

%.png: %.dot
	timeout 30 dot -Tpng -Gdpi=300 -o $@ $<

.PHONY: llvmpass
llvmpass:
	$(MAKE) -C llvmpass

$(ALL_BITCODE): $(BITCODE_OUTPUT)/%.bc: | test.ok
	v1=$$(git -C $(PROJECT_SRC) rev-list -n 1 HEAD); \
	v2=$$(git -C $(PROJECT_SRC) rev-list -n 1 $*); \
	if [ "$$v1" != "$$v2" ]; then \
		$(MAKE) -C $(PROJECT_SRC) -f $(PROJECT_MAK) clean || true ; \
		git -C $(PROJECT_SRC) restore --staged . ; \
		git -C $(PROJECT_SRC) restore . ; \
		git -C $(PROJECT_SRC) clean -dfx ; \
		git -C $(PROJECT_SRC) checkout $* ; \
	fi
	CC=$(CC) CFLAGS="$(CFLAGS)" LLVM_COMPILER=$(LLVM_COMPILER) $(MAKE) -C $(PROJECT_SRC) -f $(PROJECT_MAK)
	mkdir -p $(dir $@)
	mv $(PROJECT_SRC)/$(PROJECT).bc $(BITCODE).bc

.PHONY: clean
clean:
	-$(MAKE) -C $(PROJECT_SRC) -f $(PROJECT_MAK) clean
	git -C $(PROJECT_SRC) restore --staged .
	git -C $(PROJECT_SRC) restore .
	git -C $(PROJECT_SRC) clean -dfx
	-rm $(BITCODE).bc $(BITCODE).ll $(BITCODE).csv

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
ll: $(BITCODE).ll
csv: $(BITCODE).csv
png: $(RGRAPH1).png
diff: $(RGRAPH_REVDIFF).png
bc bitcode: $(BITCODE).bc
