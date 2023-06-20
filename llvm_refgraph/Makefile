.PHONY: default
default: llvm_refgraph

.PHONY: llvm_refgraph
llvm_refgraph: build/librefgraph.so

build/librefgraph.so: refgraph.cpp
	mkdir -p build
	cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
	cp build/compile_commands.json ..
	make -C build

.PHONY: clean
clean:
	-rm -rf build
