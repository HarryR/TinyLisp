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

module tinylisp.evaluator;

private import tinylisp.core;
private import tinylisp.s11n;

private Obj prepareFunEnv(Obj env, Obj args_spec, Obj call_args ) pure @safe nothrow {
	Obj new_env = env;
	Obj tmp_env = env;
	if( args_spec.isSYM ) {
		if( args_spec.isVARSYM ) {
			new_env = mapadd(env, args_spec, call_args);
		}
		else {
			new_env = mapadd(env, args_spec, evlis(tmp_env, call_args));
		}
	}
	else {
		auto tmp = args_spec;
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
	Obj new_env = prepareFunEnv(env, obj.args_spec, args);
	assert( new_env !is null );
	return eval(new_env, obj.code);
}

private Obj evaluateClosure(ref Obj env, Obj_Closure obj) pure @safe nothrow {
	Obj new_env = env;
	auto bindings = obj.bindings;
	while( bindings ) {
		new_env = cons(bindings.car, new_env);
		bindings = bindings.cdr;
	}
	assert( new_env !is null );
	return eval(new_env, obj.inside);
}

private Obj evaluatePair( ref Obj env, Obj_Pair obj ) pure @safe nothrow {
	if( obj.A is null ) return null;
	auto arg = eval(env, obj.A);
	if( arg.isFUN ) {
		return evaluateFun(env, cast(Obj_Fun)arg, obj.B);
	}
	else if( arg.isBUILTIN ) {
		return (cast(Obj_Builtin)arg)(env, obj.B);
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

Obj eval (ref Obj ENV, Obj X)  pure @safe nothrow {
	if( X.isPAIR ) {
		return evaluatePair(ENV, cast(Obj_Pair)X);
	}
	else if( X.isSYM ) {
		return evaluateSymbol(ENV, cast(Obj_Sym)X);
	}
	else if( X.isQUOTE ) {
		return X.inside;
	}
	else if( X.isFUN || X.isBUILTIN ) {
		return X;
	}
	else if( X.isCLOSURE ) {
		return evaluateClosure(ENV, cast(Obj_Closure)X);
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
