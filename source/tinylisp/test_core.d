module tinylisp.test_core;

import tinylisp;

unittest {
	assert( mklist(mksym("A")).sexpr == "(A)" );
	assert( cons(mksym("A"), null).sexpr == "(A)" );
	assert( mklist(mksym("A"), null).sexpr == "(A NIL)" );
	assert( mklist(mksym("A"), mklist(mksym("B"))).sexpr == "(A (B))" );
	assert( mklist(mksym("A"), mkquote(mklist(mksym("B")))).sexpr == "(A '(B))" );
	assert( mklist(mksym("A"), mksym("B"), mksym("C")).sexpr == "(A B C)" );
	assert( mklist(null).sexpr == "(NIL)" );

	auto env = mkenv();
	assert( eval(env, cons(mksym("A"), null)) is null );

	assert( eval(env, "(car (fun X Y))") == "X" );
	assert( eval(env, "(cdr (fun X Y))") == "Y" );
	assert( eval(env, "(cdr if)") == eval(env, "if") );
}

unittest {
	auto testfun = mkfun(&builtin_if, mksym("X"));
	assert( mkproc(mksym("X"), null).sexpr == "(fun X NIL)" );
	assert( testfun.sexpr == "(fun X ...)" );

	auto env = mkenv();
	assert( equal(eval(env, testfun), testfun) );
	assert( eval(env, "(def! 'X1 (fun X X))") == "((X1 . (fun X X)))" );
	assert( eval(env, "(X1)") == "NIL" );
	assert( eval(env, "(X1 'Y)") == "(Y)" );
	assert( eval(env, "(X1 'Y 'Z)") == "(Y Z)" );
	assert( eval(env, "(X1 Y Z)") == "(NIL NIL)" );

	assert( eval(env, "(def! 'X2 (fun $X $X))") == "((X2 . (fun $X $X)))" );
	assert( eval(env, "(X2)") == "NIL" );
	assert( eval(env, "(X2 'Y)") == "('Y)" );
	assert( eval(env, "(X2 'Y 'Z)") == "('Y 'Z)" );
	assert( eval(env, "(X2 Y Z)") == "(Y Z)" );

	assert( eval(env, "(def! 'X3 (fun (A B) B))") == "((X3 . (fun (A B) B)))" );
	assert( eval(env, "(X3)") == "NIL" );
	assert( eval(env, "(X3 'Y)") == "NIL" );
	assert( eval(env, "(X3 'Y 'Z)") == "Z" );
	assert( eval(env, "(X3 Y Z)") == "NIL" );

	assert( eval(env, "(def! 'X4 (fun (A $B) $B))") == "((X4 . (fun (A $B) $B)))" );
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
	assert( name(A) == "A" );
	assert( name(A) == name(A) );

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
	assert( name(null) is null );
	assert( isPAIR(null) == false );
	assert( isFUN(null) == false );
	assert( isSYM(null) == false );
	Obj A = mksym("A");
	assert( isSYM(A) );
	assert( ! isPAIR(A) );
	assert( name(A) == name(A) );
	assert( name(A) == "A" );
	assert( name(A) !is null );
	assert( equal(A, A) );
	assert( isVARSYM(mksym("$DERP")) );
	assert( ! isVARSYM(mksym("derp")) );
	assert( ! isVARSYM(mkquote(mksym("$derp"))) );
}


unittest {
	assert( cdr(null) is null );
	assert( car(null) is null );
	Obj empty = null;
	assert( empty.car is null );
	assert( empty.cdr is null );

	auto A = mksym("A");
	auto B = mksym("B");

	auto X = cons(A, A);
	assert( isPAIR(X) );
	assert( equal(car(X), cdr(X)) );

	auto Y = (X.cdr = B);
	assert( isSYM(Y) );
	assert( equal(Y, A) );
	assert( equal(cdr(X), B) );
	assert( equal(car(X), A) );

	auto Z = (X.car = B);
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

