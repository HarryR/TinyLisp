/* A minimal Lisp interpreter
   Copyright 2004 Andru Luvisi
   Copyright 2015 Harry Roberts

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License , or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, write to the Free Software
   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
 */

module lisp.builtins;

private import lisp.core;

/*
 * Builtin functions available in the base Lisp environment
 */
private Obj builtin_equal (ref Obj env, Obj args) pure @safe nothrow {
	Obj prev = null;
	bool first = true;
	bool compared = false;
	while( isPAIR(args) ) {
		auto A = eval(env,car(args));
		if( first ) {
			first = false;
		}
		else {
			if( ! equal(prev, A) ) {
				return null;
			}
			compared = true;	
		}
		prev = A;
		args = cdr(args);
	}
	return compared ? mksym("T") : null;
}
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

private Obj builtin_quote(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return mkquote(car(args));
}
private Obj builtin_isQUOTE(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = car(args);
	return isQUOTE(A) ? mksym("T") : null;
}
private Obj builtin_isSYM(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = car(args);
	return isSYM(A) ? mksym("T") : null;
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

private Obj builtin_fun(ref Obj env, Obj args) pure @safe nothrow {
	auto proc_args = car(args);
	auto proc_code = car(cdr(args));
	return (isSYM(proc_args) || isPAIR(proc_args))
		 ? mkfun(proc_args, proc_code)
		 : null;
}
private Obj builtin_isFUN(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = car(args);
	return isFUN(A) ? mksym("T") : null;
}
private Obj builtin_if(ref Obj env, Obj args) pure @safe nothrow {
	auto T = mksym("T");
	auto cond = equal(eval(env, car(args)), T) ? T : null;
	auto next = cdr(args);
	if( cond !is null ) {
		return eval(env, car(next));
	}
	return eval(env, car(cdr(next)));
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

private Obj builtin_isPAIR(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return isPAIR(car(args)) ? mksym("T") : null;
}
private Obj builtin_isNIL(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return car(args) is null ? mksym("T") : null;
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

private Obj builtin_cons(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = car(args);
	auto B = car(cdr(args));
	return cons(A, B);
}
private Obj builtin_car(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return car(car(args));
}
private Obj builtin_cdr(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return cdr(car(args));
}
private Obj builtin_setcar(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return setcar(car(args), car(cdr(args)));
}
private Obj builtin_setcdr(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return setcdr(car(args), car(cdr(args)));
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

private Obj builtin_setenv(ref Obj env, Obj args) pure @safe nothrow {
	return env = car(evlis(env, args));
}
private Obj builtin_env(ref Obj env, Obj args) pure @safe nothrow {
	return env;
}
unittest {
	auto env = mkenv();
	assert( eval(env, "(env)") != "NIL" );
	assert( eval(env, "(cons? (env))") == "T" );

	assert( env !is null );
	assert( eval(env, "(env!)") == "NIL" );
	assert( env is null );
}
private Obj builtin_setb(ref Obj env, Obj args) pure @safe nothrow {
	auto key = eval(env, car(args));
	auto val = eval(env, car(cdr(args)));
	if( key !is null && isSYM(key) ) {
		auto entry = mapfind(env, key);
		Obj old = null;
		if( entry is null ) {
			env = mapadd(env, key, val);
		}
		else {
			old = cdr(entry);
			setcdr(entry, val);
		}
		return old;
	}
	return null;
}
private Obj builtin_defb(ref Obj env, Obj args) pure @safe nothrow {
	auto key = eval(env, car(args));
	auto val = eval(env, car(cdr(args)));
	if( key !is null && isSYM(key) ) {
		env = mapadd(env, key, val);
		return val;
	}
	return null;
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

private Obj builtin_begin(ref Obj env, Obj args) pure @safe nothrow {
	while( isPAIR(args) ) {
		auto exp = car(args);
		auto next = cdr(args);
		if( next is null ) {
			return eval(env, exp);
		}
		eval(env, exp);
		args = next;
	}
	return null;
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

Obj mkenv () pure @safe nothrow {
	auto T = mksym("T");
	auto env = mklist(
		cons(T, T),

		cons("env!", &builtin_setenv, mksym("NEW-ENV")),
		cons("set!", &builtin_setb, mklist(mksym("SYM"), mksym("VAL"))),
		cons("def!", &builtin_defb, mklist(mksym("SYM"), mksym("VAL"))),
		cons("cdr!", &builtin_setcdr, mklist(mksym("X"), mksym("Y"))),
		cons("car!", &builtin_setcar, mklist(mksym("X"), mksym("Y"))),

		cons("fun?", &builtin_isFUN, mklist(mksym("X"))),
		cons("quote?", &builtin_isQUOTE, mklist(mksym("X"))),
		cons("cons?", &builtin_isPAIR, mklist(mksym("X"))),
		cons("nil?", &builtin_isNIL, mklist(mksym("X"))),
		cons("sym?", &builtin_isSYM, mklist(mksym("X"))),
		cons("eq?", &builtin_equal, mklist(mksym("X"), mksym("Y"))),

		cons("env", &builtin_env, null),
		cons("if", &builtin_if, mklist(mksym("X"), mksym("$TRUE"), mksym("$ELSE"))),
		cons("fun", &builtin_fun, mklist(mksym("$ARGS"), mksym("$CODE"))),
		cons("begin", &builtin_begin, mksym("EXPR")),
		cons("cons", &builtin_cons, mklist(mksym("A"), mksym("B"))),
		cons("quote", &builtin_quote, mklist(mksym("X"))),
		cons("car", &builtin_car, mklist(mksym("X"))),
		cons("cdr", &builtin_cdr, mklist(mksym("X"))),
		cons("list", &evlis, mksym("ARGS")),
	);
	return env;
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