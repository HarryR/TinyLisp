module lisp.utils;

private import core = lisp.core;
private import lisp.s11n;


string eval (ref core.Obj env, string X) pure @safe nothrow {
	auto RES = core.eval(env, parse(env, X));
	if( RES is null ) {
		return "NIL";
	}
	return RES.sexpr;
}