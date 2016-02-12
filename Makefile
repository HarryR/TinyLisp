DMD=ldmd2 -w
DMD=dmd
DMD_DEBUG=$(DMD) -g -gc -gs -debug -unittest
DMD_COV=$(DMD_DEBUG) -cov
DMD_RELEASE=$(DMD) -inline -O -release 

TARGETS=lisp lisp.test
MAIN_SRC=lisp.d main.d

.PHONY: test cov

all: $(TARGETS)

lisp: $(MAIN_SRC)
	$(DMD_RELEASE) -of$@ $+
	strip $@

lisp.cov: $(MAIN_SRC)
	$(DMD_COV) -of$@ $+

.PHONY: cov
cov: lisp.cov
	./lisp.cov -t tests/std.lsp && cat lisp.lst  | grep -n 0000000

lisp.test: $(MAIN_SRC)
	$(DMD_DEBUG) -of$@ $(MAIN_SRC)

.PHONY: test
test: lisp.test
	./lisp.test -t tests/std.lsp

clean:
	rm -f $(TARGETS) *.o *.lst *.cov 
