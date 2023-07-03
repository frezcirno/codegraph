.PHONY: default
default: llvmpass

.PHONY: llvmpass
llvmpass: build/libllvmpass.so

build/libllvmpass.so: llvmpass.cpp
	mkdir -p build
	cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
	cp build/compile_commands.json .
	make -C build

.PHONY: clean
clean:
	-rm -rf build compile_commands.json
