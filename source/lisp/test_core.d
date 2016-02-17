module lisp.test_core;

import lisp;

unittest {
	assert( mklist(mksym("A")).toString() == "(A)" );
	assert( cons(mksym("A"), null).toString() == "(A)" );
	assert( mklist(mksym("A"), null).toString() == "(A NIL)" );
	assert( mklist(mksym("A"), mklist(mksym("B"))).toString() == "(A (B))" );
	assert( mklist(mksym("A"), mkquote(mklist(mksym("B")))).toString() == "(A '(B))" );
	assert( mklist(mksym("A"), mksym("B"), mksym("C")).toString() == "(A B C)" );
	assert( mklist(null).toString() == "(NIL)" );

	auto env = mkenv();
	assert( cons(mksym("A"), null).eval(env) is null );

	assert( eval(env, "(car (fun X Y))") == "X" );
	assert( eval(env, "(cdr (fun X Y))") == "Y" );
	assert( eval(env, "(cdr if)") == eval(env, "if") );
}

unittest {
	auto testfun = mkfun(&builtin_if, mksym("X"));
	assert( mkproc(mksym("X"), null).toString() == "(fun X NIL)" );
	assert( testfun.toString() == "(fun X ...)" );

	auto env = mkenv();
	assert( equal(testfun.eval(env), testfun) );
	assert( eval(env, "(def! 'X1 (fun X X))") == "(fun X X)" );
	assert( eval(env, "(X1)") == "NIL" );
	assert( eval(env, "(X1 'Y)") == "(Y)" );
	assert( eval(env, "(X1 'Y 'Z)") == "(Y Z)" );
	assert( eval(env, "(X1 Y Z)") == "(NIL NIL)" );

	assert( eval(env, "(def! 'X2 (fun $X $X))") == "(fun $X $X)" );
	assert( eval(env, "(X2)") == "NIL" );
	assert( eval(env, "(X2 'Y)") == "('Y)" );
	assert( eval(env, "(X2 'Y 'Z)") == "('Y 'Z)" );
	assert( eval(env, "(X2 Y Z)") == "(Y Z)" );

	assert( eval(env, "(def! 'X3 (fun (A B) B))") == "(fun (A B) B)" );
	assert( eval(env, "(X3)") == "NIL" );
	assert( eval(env, "(X3 'Y)") == "NIL" );
	assert( eval(env, "(X3 'Y 'Z)") == "Z" );
	assert( eval(env, "(X3 Y Z)") == "NIL" );

	assert( eval(env, "(def! 'X4 (fun (A $B) $B))") == "(fun (A $B) $B)" );
	assert( eval(env, "(X4)") == "NIL" );
	assert( eval(env, "(X4 'Y)") == "NIL" );
	assert( eval(env, "(X4 'Y 'Z)") == "'Z" );
	assert( eval(env, "(X4 Y Z)") == "Z" );

	assert( eval(env, "(fun 'X X)") == "NIL" );
	assert( eval(env, "((fun ($A . $B) $A) C B D)") == "C" );
	assert( eval(env, "((fun ($A) $A) 'A)") == "'A" );
	assert( eval(env, "((fun ($B $A) $A) 'A 'B)") == "'B" );
}

unittest {
	assert( equal(null, null) );

	auto A = mksym("A");
	assert( ! equal(null, A) );
	assert( ! equal(A, null) );
	assert( equal(A, A) );
	assert( isSYM(A) );
	assert( symname(A) == "A" );
	assert( symname(A) == symname(A) );

	auto X = mksym("X");
	assert( ! equal(A, X) );
	assert( ! equal(X, null) );
	assert( ! equal(null, X) );
	assert( equal(X, X) );
	
	auto B = mksym("B");
	assert( ! equal(A, B) );
	assert( ! equal(B, A) );
	assert( equal(A, A) );
	assert( equal(B, B) );

	assert( equal(cons(A, A), cons(A, A)) );
	assert( equal(cons(null, A), cons(null, A)) );
	assert( equal(cons(), cons()) );
	assert( equal(cons(A), cons(A)) );

	assert( ! equal(cons(A, cons(A, A)), cons(A)) );
	assert( equal(cons(A, cons(A, A)), cons(A, cons(A, A))) );
	assert( ! equal(cons(A, cons(A, B)), cons(A, cons(A, A))) );
	assert( ! equal(cons(A, cons(A, B)), cons(A)) );

	assert( ! equal(cons(A), cons(A, A)) );
	assert( ! equal(cons(A, B), cons(null, A)) );
	assert( ! equal(cons(A), cons()) );
	assert( ! equal(cons(B), cons(A)) );
}

unittest {	
	assert( mksym("NIL") is null );
	assert( mksym(null) is null );
	assert( symname(null) is null );
	assert( isPAIR(null) == false );
	assert( isFUN(null) == false );
	assert( isSYM(null) == false );
	Obj A = mksym("A");
	assert( isSYM(A) );
	assert( ! isPAIR(A) );
	assert( symname(A) == symname(A) );
	assert( symname(A) == "A" );
	assert( symname(A) !is null );
	assert( equal(A, A) );
	assert( isVARSYM(mksym("$DERP")) );
	assert( ! isVARSYM(mksym("derp")) );
	assert( ! isVARSYM(mkquote(mksym("$derp"))) );
}


unittest {
	assert( cdr(null) is null );
	assert( car(null) is null );
	assert( setcar(null, null) is null );
	assert( setcdr(null, null) is null );

	auto A = mksym("A");
	auto B = mksym("B");

	auto X = cons(A, A);
	assert( isPAIR(X) );
	assert( equal(car(X), cdr(X)) );

	auto Y = setcdr(X, B);
	assert( isSYM(Y) );
	assert( equal(Y, A) );
	assert( equal(cdr(X), B) );
	assert( equal(car(X), A) );

	auto Z = setcar(X, B);
	assert( isSYM(Z) );
	assert( equal(Z, A) );
	assert( equal(cdr(X), B) );
	assert( equal(car(X), B) );
}


unittest {
	auto A = mksym("A");
	auto B = mksym("B");
	auto x1 = mapadd(null, A, B);
	assert( isPAIR(x1) );
	assert( isPAIR(car(x1)) );
	assert( isSYM(car(car(x1))) );
	assert( isSYM(cdr(car(x1))) );
	assert( cdr(x1) is null );

	assert( mapfind(x1, B) is null );
	auto xe = mapfind(x1, A);
	assert( isPAIR(xe) );
	assert( equal(car(xe), A) );
}

