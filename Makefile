export LLVM_COMPILER=clang

.PHONY: default
default:
	@echo "Usage: make [PROJECT=ffmpeg|qemu|php-src|redis] [REVISION=HEAD|<commit>] [bc|bitcode|png|clean]"

.PHONY: test
test:
	@echo '#include<stdio.h>\nint main() { printf("Hello World!"); return 0; }' >test.c
	wllvm test.c -o test
	-rm test.c test .test.o .test.o.bc

%.ll: %.bc
	llvm-dis $<

.PHONY: ll
ll: $(PROJECT)-$(REVISION).ll

%.csv: %.bc llvm_refgraph
	opt --enable-new-pm=0 -load llvm_refgraph/build/LLVMrefgraph.so -refgraph $< >/dev/null 2>$@

.PHONY: csv
csv: $(PROJECT)-$(REVISION).csv

$(PROJECT)-$(REVISION)-$(ENTRY).dot: $(PROJECT)-$(REVISION).csv csv2dot.py
	python3 ./csv2dot.py $< $(ENTRY) >$@

#.PHONY: dot
#dot: $(PROJECT)-$(REVISION)-$(ENTRY).dot

%.png: %.dot
	dot -Tpng -Gdpi=300 -o $@ $<

.PHONY: png
png: $(PROJECT)-$(REVISION)-$(ENTRY).png

.PHONY: llvm_refgraph
llvm_refgraph:
	$(MAKE) -C llvm_refgraph

$(PROJECT)-$(REVISION).bc: | test
ifneq ($(shell git -C $(PROJECT) rev-list -n 1 HEAD),$(shell git -C $(PROJECT) rev-list -n 1 $(REVISION)))
	-$(MAKE) -C $(PROJECT) -f ../$(PROJECT).mak clean
	-git -C $(PROJECT) clean -dfx
	git -C $(PROJECT) checkout $(REVISION)
endif
	$(MAKE) -C $(PROJECT) -f ../$(PROJECT).mak
	mv $(PROJECT)/$(PROJECT).bc $(PROJECT)-$(REVISION).bc

.PHONY: bc bitcode
bc bitcode: $(PROJECT)-$(REVISION).bc

.PHONY: clean
clean:
	-$(MAKE) -C llvm_refgraph clean
	-rm -f *.bc *.ll *.csv *.dot *.png
	-$(MAKE) -C ffmpeg -f ../ffmpeg.mak clean
	-$(MAKE) -C qemu -f ../qemu.mak clean
	-$(MAKE) -C php-src -f ../php-src.mak clean
	-$(MAKE) -C redis -f ../redis.mak clean
