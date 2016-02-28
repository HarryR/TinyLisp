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

module tinylisp.builtins;

private import tinylisp.core;
private import tinylisp.evaluator;

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

package Obj builtin_fun(ref Obj env, Obj args) pure @safe nothrow {
	auto proc_args = args.car;
	auto proc_code = args.cdr.car;
	return (proc_args.isSYM || proc_args.isPAIR)
		 ? mkproc(proc_args, proc_code)
		 : null;
}

package Obj builtin_if(ref Obj env, Obj args) pure @safe nothrow {
	auto cond = eval(env, args.car) !is null ? Obj.T : null;
	auto next = args.cdr;
	if( cond !is null ) {
		return eval(env, next.car);
	}
	return eval(env, next.cdr.car);
}

package Obj builtin_cons(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return cons(args.car, args.cdr.car);
}

package Obj builtin_setcar(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return args.car.car = args.cdr.car;
}

package Obj builtin_setcdr(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return args.car.cdr = args.cdr.car;
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

		cons("env!", "NEW-ENV",
			(ref env, args) =>
				env = evlis(env, args).car),

		cons("set!", ["SYM", "VAL"], &builtin_setb),
		cons("def!", ["SYM", "VAL"], &builtin_defb),
		cons("cdr!", ["X", "Y"], &builtin_setcdr),
		cons("car!", ["X", "Y"], &builtin_setcar),

		cons("nil?", ["X"], (ref env, args) =>
			evlis(env, args).car is null ? Obj.T : null),

		cons("cons?", ["X"], (ref env, args) =>
			evlis(env, args).car.isPAIR ? Obj.T : null),

		cons("fun?", ["X"], (ref env, args) {
			auto arg = evlis(env, args).car;
			return arg.isFUN || arg.isBUILTIN ? Obj.T : null;
		}),

		cons("builtin?", ["X"], (ref env, args) =>
			evlis(env, args).car.isBUILTIN ? Obj.T : null),

		cons("quote?", ["X"], (ref env, args) =>
			evlis(env, args).car.isQUOTE ? Obj.T : null),

		cons("sym?", ["X"], (ref env, args) =>
			evlis(env, args).car.isSYM ? Obj.T : null),

		cons("eq?", ["X", "Y"], &builtin_equal),

		cons("env", (ref env, args) => env),

		cons("if", ["X", "$TRUE", "$ELSE"], &builtin_if),
		cons("fun", ["$ARGS", "$CODE"], &builtin_fun),
		cons("begin", "EXPR", &builtin_begin),
		cons("cons", ["A", "B"], &builtin_cons),

		cons("quote", ["X"], (ref env, args) =>
			mkquote(evlis(env, args).car)),

		cons("car", ["X"], (ref env, args) =>
			evlis(env, args).car.car),

		cons("cdr", ["X"], (ref env, args) =>
			evlis(env, args).car.cdr),

		cons("list", "ARGS", (ref env, args) =>
			evlis(env, args)),
	);
	return env;
}
