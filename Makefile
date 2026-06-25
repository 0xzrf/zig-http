.PHONY: build_and_run
BIN_OUT = ./zig-out/bin/zig-http

build_and_run:
	zig build && $(BIN_OUT)
