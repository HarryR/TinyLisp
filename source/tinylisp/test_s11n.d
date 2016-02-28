module tinylisp.test_s11n;

import tinylisp;

unittest {
	auto env = mkenv();

	// Invalid forms
	assert( parse(env, null) is null );
	assert( parse(env, "") is null );
	assert( parse(env, "NIL") is null );
	assert( parse(env, "'") is null );
	assert( parse(env, "(") is null );
	assert( parse(env, ")") is null );
	assert( parse(env, "(X (Y)") is null );

	auto X = mksym("X");
	auto Y = mksym("Y");
	auto Z = mksym("Z");
	assert( equal(parse(env, "()"), cons()) );
	assert( equal(parse(env, "X"), mksym("X")) );
	assert( equal(parse(env, "'X"), mkquote(mksym("X"))) );
	assert( equal(parse(env, "(X)"), cons(mksym("X"))) );
	assert( equal(parse(env, "('X)"), cons(mkquote(mksym("X")))) );
	assert( equal(parse(env, "'('X)"), mkquote(cons(mkquote(mksym("X"))))) );
	assert( equal(parse(env, "'(X)"), mkquote(cons(mksym("X")))) );
	assert( equal(parse(env, "(X Y)"), mklist(X, Y)) );
	assert( equal(parse(env, "(X Y Z)"), mklist(X, Y, Z)) );
	assert( equal(parse(env, "(X . Y)"), cons(X, Y)) );

	auto xypair = cons(X, Y);
	assert( equal(parse(env, "((X . Y) (X . Y))"), mklist(xypair, xypair)) );
	assert( equal(parse(env, "((X . Y) . (X . Y))"), cons(xypair, xypair)) );
	assert( equal(parse(env, "('(X . Y) . (X . Y))"), cons(mkquote(xypair), xypair)) );
	assert( equal(parse(env, "((X . Y) (X . Y) Z)"), mklist(xypair, xypair, Z)) );
	assert( equal(parse(env, "((X . Y) '(X . Y) Z)"), mklist(xypair, mkquote(xypair), Z)) );
	assert( equal(parse(env, "(Z (X . Y))"), mklist(Z, xypair)) );
}