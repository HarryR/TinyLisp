module lisp.utils;

private import core = lisp.core;
private import lisp.s11n;


string eval (ref core.Obj env, string X) pure @safe nothrow {
	auto res = core.eval(env, parse(env, X));
	if( res is null ) {
		return "NIL";
	}
	return res.toString();
}