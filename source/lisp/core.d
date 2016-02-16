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

module lisp.core;

private enum Type {
	SYM, PAIR, FUN, QUOTE
}

class Obj {
	abstract Type type () const pure @safe nothrow;
	override string toString () pure @safe nothrow;	
	abstract Obj eval (ref Obj env) pure @safe nothrow;
}

private class Obj_Pair : Obj {
	Obj A;
	Obj B;
	this( Obj A, Obj B ) pure @safe nothrow {
		this.A = A;
		this.B = B;
	}
	override Type type () const pure @safe nothrow {
		return Type.PAIR;
	}
	override string toString () pure @safe nothrow {
		string ret = "(";
		Obj X = this;
		auto first = true;
		while( isPAIR(X) ) {
			if( first ) {				
				first = false;
			}
			else {
				ret ~= " ";
			}
			auto val = car(X);
			if( val is null ) {
				ret ~= "NIL";
			}
			else {
				ret ~= val.toString();
			}
			X = cdr(X);
		}
		if( X !is null ) {
			ret ~= " . " ~ X.toString();
		}
		return ret ~ ")";
	}

	override Obj eval (ref Obj env) pure @safe nothrow {
		if( A is null ) return null;
		auto arg = A.eval(env);
		if( isFUN(arg) ) {
			return (cast(Obj_Fun)arg)(env, B);
		}
		return null;
	}
}
unittest {
	assert( mklist(mksym("A")).toString() == "(A)" );
	assert( cons(mksym("A"), null).toString() == "(A)" );
	assert( mklist(mksym("A"), null).toString() == "(A NIL)" );
	assert( mklist(mksym("A"), mklist(mksym("B"))).toString() == "(A (B))" );
	assert( mklist(mksym("A"), mkquote(mklist(mksym("B")))).toString() == "(A '(B))" );
	assert( mklist(mksym("A"), mksym("B"), mksym("C")).toString() == "(A B C)" );
	assert( mklist(null).toString() == "(NIL)" );

	auto env = mkenv();
	assert( cons(mksym("A"), null).eval(env) is null );

	assert( eval(env, "(car (fun X Y))") == "X" );
	assert( eval(env, "(cdr (fun X Y))") == "Y" );
	assert( eval(env, "(cdr if)") == eval(env, "if") );
}

private class Obj_Sym : Obj {
	string name;
	this( string name ) pure @safe nothrow {
		this.name = name;
	}
	override Type type () const pure @safe nothrow {
		return Type.SYM;
	}
	override string toString () pure @safe nothrow {
		return name;
	}
	override Obj eval (ref Obj env) pure @safe nothrow {
		return cdr(mapfind(env, this));
	}
}

private class Obj_Quote : Obj {
	Obj inside;
	this(Obj inside) pure @safe nothrow {
		this.inside = inside;
	}
	override Type type () const pure @safe nothrow {
		return Type.QUOTE;
	}
	override Obj eval (ref Obj env) pure @safe nothrow {
		return this.inside;
	}
	override string toString () pure @safe nothrow {
		if( inside is null ) {
			return "'NIL";
		}
		return "'" ~ inside.toString();
	}
}

public alias Obj function(ref Obj env, Obj args) pure @safe nothrow Logic_EnvArg;
private class Obj_Fun : Obj {
	Obj proc_code;
	Obj proc_args;
	Logic_EnvArg func;
	this( Logic_EnvArg builtin, Obj args) pure @safe nothrow {
		this.func = builtin;
		this.proc_code = null;
		this.proc_args = args;
	}
	this( Obj args, Obj code) pure @safe nothrow {
		this.func = null;
		this.proc_code = code;
		this.proc_args = args;
	}
	override Type type () const pure nothrow @safe {
		return Type.FUN;
	}
	override Obj eval (ref Obj env) pure @safe nothrow {
		return this;
	}
	Obj opCall(ref Obj env, Obj args) pure @safe nothrow {
		if( func !is null ) {
			return this.func(env, args);
		}
		Obj new_env = env;
		Obj tmp_env = env;
		if( isSYM(proc_args) ) {
			if( isVARSYM(proc_args) ) {
				new_env = mapadd(env, proc_args, args);
			}
			else {
				new_env = mapadd(env, proc_args, evlis(tmp_env, args));
			}
		}
		else {
			auto tmp = proc_args;
			while( isPAIR(tmp) ) {
				auto key = car(tmp);
				auto val = car(args);
				if( isSYM(key) ) {
					if( isVARSYM(key) ) {
						new_env = mapadd(new_env, key, val);
					}
					else {
						new_env = mapadd(new_env, key, .eval(tmp_env, val));
					}
				}
				tmp = cdr(tmp);
				args = cdr(args);
			}
		}
		assert( new_env !is null );
		return .eval(new_env, proc_code);
	}
	override string toString () pure @safe nothrow {
		auto args = proc_args ? proc_args.toString() : "?";
		if( func !is null ) {
			return "(fun " ~ args ~ " ...)";
		}
		auto code = proc_code ? proc_code.toString() : "NIL";
		return "(fun " ~ args ~ " " ~ code ~ ")";
	}
}
unittest {
	auto testfun = mkfun(&builtin_if, mksym("X"));
	assert( mkfun(null, mksym("X")).toString() == "(fun X NIL)" );
	assert( testfun.toString() == "(fun X ...)" );

	auto env = mkenv();
	assert( equal(testfun.eval(env), testfun) );
	assert( eval(env, "(def! 'X1 (fun X X))") == "(fun X X)" );
	assert( eval(env, "(X1)") == "NIL" );
	assert( eval(env, "(X1 'Y)") == "(Y)" );
	assert( eval(env, "(X1 'Y 'Z)") == "(Y Z)" );
	assert( eval(env, "(X1 Y Z)") == "(NIL NIL)" );

	assert( eval(env, "(def! 'X2 (fun $X $X))") == "(fun $X $X)" );
	assert( eval(env, "(X2)") == "NIL" );
	assert( eval(env, "(X2 'Y)") == "('Y)" );
	assert( eval(env, "(X2 'Y 'Z)") == "('Y 'Z)" );
	assert( eval(env, "(X2 Y Z)") == "(Y Z)" );

	assert( eval(env, "(def! 'X3 (fun (A B) B))") == "(fun (A B) B)" );
	assert( eval(env, "(X3)") == "NIL" );
	assert( eval(env, "(X3 'Y)") == "NIL" );
	assert( eval(env, "(X3 'Y 'Z)") == "Z" );
	assert( eval(env, "(X3 Y Z)") == "NIL" );

	assert( eval(env, "(def! 'X4 (fun (A $B) $B))") == "(fun (A $B) $B)" );
	assert( eval(env, "(X4)") == "NIL" );
	assert( eval(env, "(X4 'Y)") == "NIL" );
	assert( eval(env, "(X4 'Y 'Z)") == "'Z" );
	assert( eval(env, "(X4 Y Z)") == "Z" );

	assert( eval(env, "(fun 'X X)") == "NIL" );
	assert( eval(env, "((fun ($A . $B) $A) C B D)") == "C" );
	assert( eval(env, "((fun ($A) $A) 'A)") == "'A" );
	assert( eval(env, "((fun ($B $A) $A) 'A 'B)") == "'B" );
}


/**
 * Equal can compare types, symbols and cons structures
 */
bool equal (Obj X, Obj Y) pure @safe nothrow {
	if( X is null && Y is null ) {
		return true;
	}
	else if( X is null || Y is null ) {
		return false;
	}
	else if( isSYM(X) && isSYM(Y) ) {
		return symname(X) == symname(Y);
	}
	else if( isPAIR(X) && isPAIR(Y) ) {
		return equal(car(X), car(Y)) && equal(cdr(X), cdr(Y));
	}
	else if( isQUOTE(X) && isQUOTE(Y) ) {
		return equal((cast(Obj_Quote)X).inside, (cast(Obj_Quote)Y).inside);
	}
	else if( isFUN(X) && isFUN(Y) ) {
		auto funX = cast(Obj_Fun)X;
		auto funY = cast(Obj_Fun)Y;
		return equal(funX.proc_code, funY.proc_code)
			&& equal(funX.proc_args, funY.proc_args)
			&& funX.func is funY.func;
	}
	return false; // Will never reach here!
}
unittest {
	assert( equal(null, null) );

	auto A = mksym("A");
	assert( ! equal(null, A) );
	assert( ! equal(A, null) );
	assert( equal(A, A) );
	assert( isSYM(A) );
	assert( symname(A) == "A" );
	assert( symname(A) == symname(A) );

	auto X = mksym("X");
	assert( ! equal(A, X) );
	assert( ! equal(X, null) );
	assert( ! equal(null, X) );
	assert( equal(X, X) );
	
	auto B = mksym("B");
	assert( ! equal(A, B) );
	assert( ! equal(B, A) );
	assert( equal(A, A) );
	assert( equal(B, B) );

	assert( equal(cons(A, A), cons(A, A)) );
	assert( equal(cons(null, A), cons(null, A)) );
	assert( equal(cons(), cons()) );
	assert( equal(cons(A), cons(A)) );

	assert( ! equal(cons(A, cons(A, A)), cons(A)) );
	assert( equal(cons(A, cons(A, A)), cons(A, cons(A, A))) );
	assert( ! equal(cons(A, cons(A, B)), cons(A, cons(A, A))) );
	assert( ! equal(cons(A, cons(A, B)), cons(A)) );

	assert( ! equal(cons(A), cons(A, A)) );
	assert( ! equal(cons(A, B), cons(null, A)) );
	assert( ! equal(cons(A), cons()) );
	assert( ! equal(cons(B), cons(A)) );
}



/*
 * Symbol related functions
 */
Obj mkquote(Obj args) pure @safe nothrow {
	return new Obj_Quote(args);
}
Obj mksym (string name) pure @safe nothrow {
	if( name is null || name == "NIL" ) return null;
	return new Obj_Sym(name);
}
Obj mkfun (Logic_EnvArg func, Obj args) pure @safe nothrow {
	return new Obj_Fun(func, args);
}
Obj mkfun (Obj args, Obj code) pure @safe nothrow {
	return new Obj_Fun(args, code);
}
private bool istype( const Obj O, const(Type) T ) pure @safe nothrow {
	return O !is null && O.type() == T;
}
bool isFUN( Obj O ) pure @safe nothrow {
	return istype(O, Type.FUN);
}
bool isSYM( const Obj O ) pure @safe nothrow {
	return istype(O, Type.SYM);
}
bool isQUOTE( const Obj O ) pure @safe nothrow {
	return istype(O, Type.QUOTE);
}
bool isPAIR( const Obj O ) pure @safe nothrow {
	return istype(O, Type.PAIR);
}
string symname( const Obj O ) pure @safe nothrow {
	return isSYM(O) ? (cast(const(Obj_Sym))O).name : null;
}
bool isVARSYM( const Obj O ) pure @safe nothrow {
	auto name = symname(O);
	if( name ) {
		return name !is null && name.length > 0 && name[0] == '$';
	}
	return false;
}
unittest {	
	assert( mksym("NIL") is null );
	assert( mksym(null) is null );
	assert( symname(null) is null );
	assert( isPAIR(null) == false );
	assert( isFUN(null) == false );
	assert( isSYM(null) == false );
	Obj A = mksym("A");
	assert( isSYM(A) );
	assert( ! isPAIR(A) );
	assert( symname(A) == symname(A) );
	assert( symname(A) == "A" );
	assert( symname(A) !is null );
	assert( equal(A, A) );
	assert( isVARSYM(mksym("$DERP")) );
	assert( ! isVARSYM(mksym("derp")) );
	assert( ! isVARSYM(mkquote(mksym("$derp"))) );
}



/*
 * CONS related functions
 */
Obj cons(string name, Logic_EnvArg builtin, Obj args) pure @safe nothrow {
	return cons(mksym(name), mkfun(builtin, args));
}
Obj cons(Obj A = null, Obj B = null) pure @safe nothrow {
	return new Obj_Pair(A, B);
}
Obj mklist(Obj[] args ...) pure @safe nothrow {
	Obj ret = null;
	for( auto i = args.length; i != 0; i-- ) {
		ret = cons(args[i - 1], ret);		
	}
	return ret;
}
Obj car(Obj X) pure @safe nothrow {
	if( isPAIR(X) ) return (cast(Obj_Pair)X).A;
	else if( isFUN(X) ) return (cast(Obj_Fun)X).proc_args;
	return null;
}
Obj setcar(Obj X, Obj Y) pure @safe nothrow {
	Obj old = car(X);
	if( isPAIR(X) ) (cast(Obj_Pair)X).A = Y;
	return old;
}
Obj cdr(Obj X) pure @safe nothrow {
	if( isPAIR(X) ) return (cast(Obj_Pair)X).B;
	else if( isFUN(X) ) {
		auto O = (cast(Obj_Fun)X);
		return O.func is null ? O.proc_code : X;
	}
	return null;
}
Obj setcdr(Obj X, Obj Y) pure @safe nothrow {
	Obj old = cdr(X);
	if( isPAIR(X) ) (cast(Obj_Pair)X).B = Y;
	return old;
}
unittest {
	assert( cdr(null) is null );
	assert( car(null) is null );
	assert( setcar(null, null) is null );
	assert( setcdr(null, null) is null );

	auto A = mksym("A");
	auto B = mksym("B");

	auto X = cons(A, A);
	assert( isPAIR(X) );
	assert( equal(car(X), cdr(X)) );

	auto Y = setcdr(X, B);
	assert( isSYM(Y) );
	assert( equal(Y, A) );
	assert( equal(cdr(X), B) );
	assert( equal(car(X), A) );

	auto Z = setcar(X, B);
	assert( isSYM(Z) );
	assert( equal(Z, A) );
	assert( equal(cdr(X), B) );
	assert( equal(car(X), B) );
}



/*
 * Associative list functions
 */
Obj mapfind (Obj X, Obj Y) pure @safe nothrow {
	while( isPAIR(X) ) {
		auto entry = car(X);
		if( isPAIR(entry) ) {
			if( equal(car(entry), Y) ) {
				return entry;
			}
		}
		X = cdr(X);
	}
	return null;	
}
Obj mapfind (Obj X, string Y) pure @safe nothrow {
	return mapfind(X, mksym(Y));
}
Obj mapadd (Obj X, Obj key, Obj val) pure @safe nothrow {
	return cons(cons(key, val), X);
}
unittest {
	auto A = mksym("A");
	auto B = mksym("B");
	auto x1 = mapadd(null, A, B);
	assert( isPAIR(x1) );
	assert( isPAIR(car(x1)) );
	assert( isSYM(car(car(x1))) );
	assert( isSYM(cdr(car(x1))) );
	assert( cdr(x1) is null );

	assert( mapfind(x1, B) is null );
	auto xe = mapfind(x1, A);
	assert( isPAIR(xe) );
	assert( equal(car(xe), A) );
}




Obj evlis(ref Obj env, Obj exps) pure @safe nothrow {
	if( exps is null ) return null;
	return cons(eval(env, car(exps)), evlis(env, cdr(exps)));
}
Obj eval (ref Obj env, Obj X)  pure @safe nothrow {
	if( X !is null ) {
		return X.eval(env);
	}
	return null;
}


