all: test

.PHONY: build test clean

build:
	dub build

test: build
	dub test
	./tinylisp -t tests/std.lsp

clean:
	dub clean