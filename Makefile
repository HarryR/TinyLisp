DMD=ldmd2 -w
DMD=dmd
DMD_DEBUG=$(DMD) -g -gc -gs -debug -unittest
DMD_COV=$(DMD_DEBUG) -cov
DMD_RELEASE=$(DMD) -inline -O -release 

TARGETS=lisp lisp.test

.PHONY: test cov

all: $(TARGETS)

lisp: lisp.d
	$(DMD_RELEASE) -of$@ $+
	strip $@

cov: lisp.cov
lisp.cov: lisp.d
	$(DMD_COV) -of$@ $+
	./$@ -h || cat lisp.lst  | grep -n 0000000

test: lisp.test
lisp.test: lisp.d
	$(DMD_DEBUG) -of$@ $+
	./$@ -h

clean:
	rm -f $(TARGETS) *.o *.lst *.cov 
