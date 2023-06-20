export CFLAGS="-O0"

.PHONY: default
default:
	$(MAKE) CC=wllvm -j
	-extract-bc src/redis-server -o redis.bc
	-extract-bc redis-server -o redis.bc

clean:
	$(MAKE) clean
	$(MAKE) distclean