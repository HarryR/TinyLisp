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

module lisp.evaluator;

private import lisp.core;
private import lisp.s11n;

private Obj prepareFunEnv(Obj env, Obj proc_args, Obj call_args ) pure @safe nothrow {
	Obj new_env = env;
	Obj tmp_env = env;
	if( proc_args.isSYM ) {
		if( proc_args.isVARSYM ) {
			new_env = mapadd(env, proc_args, call_args);
		}
		else {
			new_env = mapadd(env, proc_args, evlis(tmp_env, call_args));
		}
	}
	else {
		auto tmp = proc_args;
		while( tmp.isPAIR ) {
			auto key = tmp.car;
			auto val = call_args.car;
			if( key.isSYM ) {
				if( key.isVARSYM ) {
					new_env = mapadd(new_env, key, val);
				}
				else {
					new_env = mapadd(new_env, key, .eval(tmp_env, val));
				}
			}
			tmp = tmp.cdr;
			call_args = call_args.cdr;
		}
	}
	return new_env;
}

private Obj evaluateFun(ref Obj env, Obj_Fun obj, Obj args) pure @safe nothrow {
	if( obj.func !is null ) {
		return obj.func(env, args);
	}

	Obj new_env = prepareFunEnv(env, obj.proc_args, args);
	assert( new_env !is null );
	return eval(new_env, obj.proc_code);
}

private Obj evaluatePair( ref Obj env, Obj_Pair obj ) pure @safe nothrow {
	if( obj.A is null ) return null;
	auto arg = eval(env, obj.A);
	if( arg.isFUN ) {
		return evaluateFun(env, cast(Obj_Fun)arg, obj.B);
	}
	return null;
}

private Obj evaluateSymbol( ref Obj env, Obj_Sym obj ) pure @safe nothrow {
	return mapfind(env, obj).cdr;
}

Obj evlis(ref Obj env, Obj exps) pure @safe nothrow {
	if( exps is null ) return null;
	return cons(eval(env, exps.car), evlis(env, exps.cdr));
}

Obj eval (ref Obj env, Obj X)  pure @safe nothrow {
	if( X.isPAIR ) {
		return evaluatePair(env, cast(Obj_Pair)X);
	}
	else if( X.isSYM ) {
		return evaluateSymbol(env, cast(Obj_Sym)X);
	}
	else if( X.isQUOTE ) {
		return X.inside;
	}
	else if( X.isFUN ) {
		return X;
	}
	return null;
}

string eval (ref Obj env, string X) pure @safe nothrow {
	auto RES = eval(env, parse(env, X));
	if( RES is null ) {
		return "NIL";
	}
	return RES.sexpr;
}
