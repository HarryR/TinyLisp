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

cov: lisp.cov
lisp.cov: $(MAIN_SRC)
	$(DMD_COV) -of$@ $+
	echo '(adder (list 0 1 0 1 1) (list 0 1))' | ./$@ examples/binary.lsp && cat lisp.lst  | grep -n 0000000

test: lisp.test
lisp.test: $(MAIN_SRC)
	$(DMD_DEBUG) -of$@ $+
	./$@ -h

clean:
	rm -f $(TARGETS) *.o *.lst *.cov 
