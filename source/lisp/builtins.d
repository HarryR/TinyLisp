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
package Obj builtin_equal (ref Obj env, Obj args) pure @safe nothrow {
	Obj prev = null;
	bool first = true;
	bool compared = false;
	while( args.isPAIR ) {
		auto A = eval(env, args.car);
		if( first ) {
			first = false;
		}
		else {
			if( ! prev.equal(A) ) {
				return null;
			}
			compared = true;	
		}
		prev = A;
		args = args.cdr;
	}
	return compared ? Obj.T : null;
}


package Obj builtin_quote(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return mkquote(args.car);
}
package Obj builtin_isQUOTE(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = args.car;
	return A.isQUOTE ? Obj.T : null;
}
package Obj builtin_isSYM(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = args.car;
	return A.isSYM ? Obj.T : null;
}


package Obj builtin_fun(ref Obj env, Obj args) pure @safe nothrow {
	auto proc_args = args.car;
	auto proc_code = args.cdr.car;
	return (proc_args.isSYM || proc_args.isPAIR)
		 ? mkproc(proc_args, proc_code)
		 : null;
}
package Obj builtin_isFUN(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = args.car;
	return A.isFUN ? Obj.T : null;
}
package Obj builtin_if(ref Obj env, Obj args) pure @safe nothrow {
	auto cond = equal(eval(env, args.car), Obj.T) ? Obj.T : null;
	auto next = args.cdr;
	if( cond !is null ) {
		return eval(env, next.car);
	}
	return eval(env, next.cdr.car);
}


package Obj builtin_isPAIR(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return args.car.isPAIR ? Obj.T : null;
}
package Obj builtin_isNIL(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return args.car is null ? Obj.T : null;
}


package Obj builtin_cons(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = args.car;
	auto B = args.cdr.car;
	return cons(A, B);
}
package Obj builtin_car(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return args.car.car;
}
package Obj builtin_cdr(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return args.car.cdr;
}
package Obj builtin_setcar(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return args.car.car = args.cdr.car;
}
package Obj builtin_setcdr(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return args.car.cdr = args.cdr.car;
}


package Obj builtin_setenv(ref Obj env, Obj args) pure @safe nothrow {
	return env = evlis(env, args).car;
}
package Obj builtin_env(ref Obj env, Obj args) pure @safe nothrow {
	return env;
}

package Obj builtin_setb(ref Obj env, Obj args) pure @safe nothrow {
	auto key = eval(env, args.car);
	auto val = eval(env, args.cdr.car);
	if( key !is null && key.isSYM ) {
		auto entry = mapfind(env, key);
		Obj old = null;
		if( entry is null ) {
			env = mapadd(env, key, val);
		}
		else {
			old = entry.cdr;
			entry.cdr = val;
		}
		return old;
	}
	return null;
}
package Obj builtin_defb(ref Obj env, Obj args) pure @safe nothrow {
	auto key = eval(env, args.car);
	auto val = eval(env, args.cdr.car);
	if( key !is null && key.isSYM ) {
		env = mapadd(env, key, val);
		return val;
	}
	return null;
}


package Obj builtin_begin(ref Obj env, Obj args) pure @safe nothrow {
	while( args.isPAIR ) {
		auto exp = args.car;
		auto next = args.cdr;
		if( next is null ) {
			return eval(env, exp);
		}
		eval(env, exp);
		args = next;
	}
	return null;
}


Obj mkenv () pure @safe nothrow {
	auto env = mklist(
		cons(Obj.T, Obj.T),

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
