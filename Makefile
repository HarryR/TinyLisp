all: test

.PHONY: build test clean

build:
	dub build

test: build
	./tinylisp-repl -t tests/std.lsp
	dub test

clean:
	dub clean
