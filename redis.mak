.PHONY: default
default:
	$(MAKE) -j $$(nproc)
	[ -f redis-server ] && extract-bc redis-server -o redis.bc || extract-bc src/redis-server -o redis.bc

clean:
	$(MAKE) clean
	$(MAKE) distclean