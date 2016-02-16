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
Obj builtin_equal (ref Obj env, Obj args) pure @safe nothrow {
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


private Obj builtin_fun(ref Obj env, Obj args) pure @safe nothrow {
	auto proc_args = car(args);
	auto proc_code = car(cdr(args));
	return (isSYM(proc_args) || isPAIR(proc_args))
		 ? mkproc(proc_args, proc_code)
		 : null;
}
private Obj builtin_isFUN(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = car(args);
	return isFUN(A) ? mksym("T") : null;
}
Obj builtin_if(ref Obj env, Obj args) pure @safe nothrow {
	auto T = mksym("T");
	auto cond = equal(eval(env, car(args)), T) ? T : null;
	auto next = cdr(args);
	if( cond !is null ) {
		return eval(env, car(next));
	}
	return eval(env, car(cdr(next)));
}


private Obj builtin_isPAIR(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return isPAIR(car(args)) ? mksym("T") : null;
}
private Obj builtin_isNIL(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return car(args) is null ? mksym("T") : null;
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
Obj builtin_setcar(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return setcar(car(args), car(cdr(args)));
}
Obj builtin_setcdr(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return setcdr(car(args), car(cdr(args)));
}


private Obj builtin_setenv(ref Obj env, Obj args) pure @safe nothrow {
	return env = car(evlis(env, args));
}
private Obj builtin_env(ref Obj env, Obj args) pure @safe nothrow {
	return env;
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
