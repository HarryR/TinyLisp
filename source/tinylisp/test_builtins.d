module tinylisp.test_builtins;

import tinylisp;

unittest {
	Obj env = mkenv();
	assert( eval(env, "(eq? 'T 'T)") == "T" );
	assert( eval(env, "(eq? T T)") == "T" );

	// Null can never be equal to anything
	assert( eval(env, "(eq? nil nil)") == "T" );
	assert( eval(env, "(eq? A A)") == "T" );
	assert( null is builtin_equal(env, null) );
	assert( null is builtin_equal(env, cons()) );
	assert( null !is builtin_equal(env, cons(null, cons())) );

	auto A = mksym("A");
	// Without quoting the symbols they'll be resolved
	assert( null is builtin_equal(env, A) );
	assert( null is builtin_equal(env, mklist(A)) );
	assert( null !is builtin_equal(env, mklist(mkquote(A), mkquote(A))) );
	assert( eval(env, "(eq? 'A 'A)") == "T" );
	assert( eval(env, "(eq? 'A A)") == "NIL" );

	auto B = mksym("B");
	assert( null is builtin_equal(env, mklist(mkquote(A), mkquote(B))) );
	assert( null !is builtin_equal(env, mklist(mkquote(B), mkquote(B))) );

	// Equality with three symbols
	assert( eval(env, "(eq? 'A 'A 'A)") == "T" );
	assert( eval(env, "(eq? 'A 'B 'A)") == "NIL" );
	assert( eval(env, "(eq? null nil null)") == "T" );

	// Equality with quoted types
	assert( eval(env, "(eq? ''A ''A)") == "T" );
	assert( eval(env, "(eq? ''A ''B)") == "NIL" );
	assert( eval(env, "(eq? (quote (cons A)) (quote (cons A)))") == "T" );
	assert( eval(env, "(eq? (quote (cons 'A)) (quote (cons NIL)))") == "NIL" );
}

unittest {
	auto env = mkenv();
	assert( eval(env, "(quote? (quote))") == "T" );
	assert( eval(env, "(quote? (quote 1))") == "T" );
	assert( eval(env, "(sym? 'X)") == "T" );
	assert( eval(env, "(quote? 'X)") == "NIL" );
	assert( eval(env, "(sym? ''X)") == "NIL" );
	assert( eval(env, "(quote? ''X)") == "T" );
	assert( eval(env, "(quote? '''X)") == "T" );
	assert( eval(env, "(quote? 1)") == "NIL" );
	assert( eval(env, "(quote 1)") == "'NIL" );
	assert( eval(env, "(quote '1)") == "'1" );
}

unittest {
	auto env = mkenv();
	assert( eval(env, "(fun? if)") == "T" );
	assert( eval(env, "(fun? X)") == "NIL" );
	assert( eval(env, "(fun? (fun x x))") == "T" );
	assert( eval(env, "(if T T NIL)") == "T" );
	assert( eval(env, "(if NIL T NIL)") == "NIL" );
	assert( eval(env, "(if T NIL T)") == "NIL" );
	assert( eval(env, "(if (fun? if) NIL T)") == "NIL" );
	assert( eval(env, "(if (fun? if) '1 '2)") == "1" );
	assert( eval(env, "(if (fun? X) '1 '2)") == "2" );
	assert( eval(env, "(if T (begin (def! 'X 'Z) X))") == "Z" );
}

unittest {
	auto env = mkenv();
	assert( eval(env, "(nil?)") == "T" );
	assert( eval(env, "(nil? T)") == "NIL" );
	assert( eval(env, "(nil? NIL)") == "T" );

	assert( eval(env, "(cons? (cons 'A 'B))") == "T" );
	assert( eval(env, "(cons? T)") == "NIL" );
	assert( eval(env, "(cons?)") == "NIL" );
}

unittest {
	auto env = mkenv();
	auto A = cons(mksym("X"), mksym("Y"));
	builtin_setcdr(env, mklist(mkquote(A), mksym("T")));
	assert( equal(cdr(A), mksym("T")) );
	assert( equal(car(A), mksym("X")) );
	builtin_setcar(env, mklist(mkquote(A), mksym("T")));
	assert( equal(car(A), mksym("T")) );

	eval(env, "(def! 'A (cons 'X 'Y))");
	assert( eval(env, "(cons? A)") == "T" );
	assert( eval(env, "(car A)") == "X" );
	assert( eval(env, "(cdr A)") == "Y" );
	eval(env, "(cdr! A T)");
	assert( eval(env, "(cdr A)") == "T" );
	eval(env, "(car! A T)");
	assert( eval(env, "(car A)") == "T" );
}

unittest {
	auto env = mkenv();
	assert( eval(env, "(env)") != "NIL" );
	assert( eval(env, "(cons? (env))") == "T" );

	assert( env !is null );
	assert( eval(env, "(env!)") == "NIL" );
	assert( env is null );
}

unittest {
	auto env = mkenv();
	assert( eval(env, "(def!)") == "NIL" );
	assert( eval(env, "(set!)") == "NIL" );
	assert( eval(env, "(set! 'Z T)") == "NIL" );

	assert( eval(env, "(def! 'X T)") == "T" );
	assert( eval(env, "X") == "T" );
	assert( eval(env, "(cdr (car (env)))") == "T" );
	// New variable shadows previous
	assert( eval(env, "(def! 'X NIL)") == "NIL" );
	assert( eval(env, "X") == "NIL" );
	assert( eval(env, "(cdr (car (env)))") == "NIL" );
	assert( eval(env, "(cdr (car (cdr (env))))") == "T" );
	// Ensure that set! overwrites variable
	assert( eval(env, "(set! 'X 'Y)") == "NIL" );
	assert( eval(env, "(cdr (car (env)))") == "Y" );
	assert( eval(env, "(cdr (car (cdr (env))))") == "T" );
	assert( eval(env, "(set! 'X 'Y)") == "Y" );
	assert( eval(env, "(cdr (car (cdr (env))))") == "T" );
}

unittest {
	auto env = mkenv();
	assert( eval(env, "(begin T)") == "T" );
	assert( eval(env, "(begin T NIL)") == "NIL" );
	assert( eval(env, "(begin X)") == "NIL" );
	assert( eval(env, "(begin NIL (eq? T T))") == "T" );
	assert( eval(env, "(begin X (eq? NIL NIL))") == "T" );
	assert( eval(env, "(begin)") == "NIL" );
}

unittest {
	auto env = mkenv();
	assert( isPAIR(mapfind(env, "env")) );
	assert( isPAIR(mapfind(env, "cdr")) );
	assert( isSYM(car(mapfind(env, "eq?"))) );
	assert( isFUN(cdr(mapfind(env, "eq?"))) );
	assert( eval(env, "env") == "(fun ? ...)" );
	assert( null is mapfind(env, "diwehfewi") );
}