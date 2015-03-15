DMD=ldmd2 -w
DMD=dmd
DMD_DEBUG=$(DMD) -g -gc -gs -debug -cov
DMD_RELEASE=$(DMD) -inline -O -release 

TARGETS=lisp lisp.test

all: lisp

lisp: lisp.d
	$(DMD_RELEASE) -of$@ $+
	strip $@

test: lisp.test
lisp.test: lisp.d
	$(DMD_DEBUG) -unittest -of$@ $+
	./$@ -h || cat lisp.lst  | grep -n 0000000

clean:
	rm -f $(TARGETS) *.o *.lst