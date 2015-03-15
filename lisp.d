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

module lisp;

import std.stdio: File, stdin, write, writef;
import std.ascii: isWhite;
import std.getopt: getopt, GetOptException;
import std.outbuffer: OutBuffer;
import core.sys.posix.unistd: isatty;

private enum Type {
	SYM, CONS, FUN, QUOTE
}

class Obj {
	abstract Type type () const pure @safe nothrow;
	override string toString () pure @safe nothrow;	
	abstract Obj eval (ref Obj env) pure @safe nothrow;
}

private class Obj_Cons : Obj {
	Obj A;
	Obj B;
	this( Obj A, Obj B ) pure @safe nothrow {
		this.A = A;
		this.B = B;
	}
	override Type type () const pure @safe nothrow {
		return Type.CONS;
	}
	override string toString () pure @safe nothrow {
		string ret = "(";
		Obj X = this;
		auto first = true;
		while( isCONS(X) ) {
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
		if( isFUN(arg) )  {
			return (cast(Obj_Fun)arg)(env, B);
		}
		return null;
	}
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

public alias Logic_EnvArg = Obj function(ref Obj env, Obj args) pure @safe nothrow;
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
	private bool beginsWithDollar(Obj sym) pure @safe nothrow {
		return isSYM(sym)
			&& symname(sym) != null
			&& symname(sym).length > 0
			&& symname(sym)[0] == '$';
	}
	Obj opCall(ref Obj env, Obj args) pure @safe nothrow {
		if( func !is null ) {
			return this.func(env, args);
		}
		Obj new_env;
		if( isSYM(proc_args) ) {
			if( beginsWithDollar(proc_args) ) {
				new_env = mapadd(env, proc_args, args);
			}
			else {
				new_env = mapadd(env, proc_args, evlis(env, args));
			}
		}
		else {
			auto tmp = proc_args;
			new_env = env;
			while( isCONS(tmp) ) {
				auto key = car(tmp);
				auto val = car(args);
				if( isSYM(key) ) {
					if( beginsWithDollar(key) ) {
						new_env = mapadd(env, key, val);
					}
					else {
						new_env = mapadd(env, key, .eval(env, val));
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
	else if( isCONS(X) && isCONS(Y) ) {
		return equal(car(X), car(Y)) && equal(cdr(X), cdr(Y));
	}
	// Others are checked by their unique type only
	return X.type() == Y.type();
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
bool isCONS( const Obj O ) pure @safe nothrow {
	return istype(O, Type.CONS);
}
string symname( const Obj O ) pure @safe nothrow {
	return isSYM(O) ? (cast(const(Obj_Sym))O).name : null;
}
unittest {	
	assert( mksym("NIL") is null );
	assert( mksym(null) is null );
	assert( symname(null) is null );
	assert( isCONS(null) == false );
	assert( isFUN(null) == false );
	assert( isSYM(null) == false );
	Obj A = mksym("A");
	assert( isSYM(A) );
	assert( ! isCONS(A) );
	assert( symname(A) == symname(A) );
	assert( symname(A) !is null );
	assert( equal(A, A) );
}



/*
 * CONS related functions
 */
Obj cons(string name, Logic_EnvArg builtin, Obj args) pure @safe nothrow {
	return cons(mksym(name), mkfun(builtin, args));
}
Obj cons(Obj A = null, Obj B = null) pure @safe nothrow {
	return new Obj_Cons(A, B);
}
Obj mklist(Obj[] args ...) pure @safe nothrow {
	Obj ret = null;
	for( auto i = args.length; i != 0; i-- ) {
		ret = cons(args[i - 1], ret);		
	}
	return ret;
}
Obj car(Obj X) pure @safe nothrow {
	if( isCONS(X) ) return (cast(Obj_Cons)X).A;
	else if( isFUN(X) ) return (cast(Obj_Fun)X).proc_args;
	return null;
}
Obj setcar(Obj X, Obj Y) pure @safe nothrow {
	if( isCONS(X) ) return (cast(Obj_Cons)X).A = Y;
	return null;
}
Obj cdr(Obj X) pure @safe nothrow {
	if( isCONS(X) ) return (cast(Obj_Cons)X).B;
	else if( isFUN(X) ) {
		auto O = (cast(Obj_Fun)X);
		return O.func is null ? O.proc_code : X;
	}
	return null;
}
Obj setcdr(Obj X, Obj Y) pure @safe nothrow {
	if( isCONS(X) ) return (cast(Obj_Cons)X).B = Y;
	return null;
}
unittest {
	assert( cdr(null) is null );
	assert( car(null) is null );
	assert( setcar(null, null) is null );
	assert( setcdr(null, null) is null );

	auto A = mksym("A");
	auto B = mksym("B");

	auto X = cons(A, A);
	assert( isCONS(X) );
	assert( equal(car(X), cdr(X)) );

	auto Y = setcdr(X, B);
	assert( isCONS(Y) );
	assert( equal(car(X), car(Y)) );
	assert( isSYM(cdr(X)) && isSYM(cdr(Y)) );
	assert( equal(cdr(X), cdr(Y)) );
	assert( equal(cdr(Y), B) );

	auto Z = setcar(X, B);
	assert( isCONS(Z) );
	assert( equal(car(X), B) );
	assert( equal(car(Y), B) );
	assert( equal(car(Z), B) );
}



/*
 * Associative list functions
 */
Obj mapfind (Obj X, Obj Y) pure @safe nothrow {
	while( isCONS(X) ) {
		auto entry = car(X);
		if( isCONS(entry) ) {
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
Obj mapdel (Obj X, Obj Y) pure @safe nothrow {
	Obj original = X;
	Obj prev = null;	
	while( isCONS(X) ) {
		auto entry = car(X);
		if( isCONS(entry) ) {
			if( equal(car(entry), Y) ) {
				if( prev is null ) {
					original = cdr(X);
				}
				else {
					setcdr(prev, cdr(X));
				}
				break;
			}
		}
		prev = X;
		X = cdr(X);
	}
	return original;	
}
Obj mapdel (Obj X, string name) pure @safe nothrow {
	return mapdel(X, mksym(name));
}
Obj mapadd (Obj X, Obj key, Obj val) pure @safe nothrow {
	return cons(cons(key, val), X);
}
unittest {
	auto A = mksym("A");
	auto B = mksym("B");
	auto x1 = mapadd(null, A, B);
	assert( isCONS(x1) );
	assert( isCONS(car(x1)) );
	assert( isSYM(car(car(x1))) );
	assert( isSYM(cdr(car(x1))) );
	assert( cdr(x1) is null );

	assert( mapfind(x1, B) is null );
	auto xe = mapfind(x1, A);
	assert( isCONS(xe) );
	assert( equal(car(xe), A) );

	auto x2 = mapdel(x1, A);
	assert( x2 is null );
	assert( mapfind(x2, A) is null );
}



/*
 * Builtin functions available in the base Lisp environment
 */
private Obj builtin_equal (ref Obj env, Obj args) pure @safe nothrow {
	Obj prev = null;
	bool first = true;
	bool compared = false;
	while( isCONS(args) ) {
		auto A = eval(env,car(args));
		if( A is null ) {
			return null;
		}
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
	assert( evalstr(env, "(eq 'T 'T)") == "T" );
	assert( evalstr(env, "(eq T T)") == "T" );

	// Null can never be equal to anything
	assert( evalstr(env, "(eq nil nil)") == "NIL" );
	assert( evalstr(env, "(eq A A)") == "NIL" );
	assert( null is builtin_equal(env, null) );
	assert( null is builtin_equal(env, cons()) );
	assert( null is builtin_equal(env, cons(null, cons())) );

	auto A = mksym("A");
	// Without quoting the symbols they'll be resolved
	assert( null is builtin_equal(env, A) );
	assert( null is builtin_equal(env, mklist(A)) );
	assert( null !is builtin_equal(env, mklist(mkquote(A), mkquote(A))) );
	assert( evalstr(env, "(eq 'A 'A)") == "T" );
	assert( evalstr(env, "(eq 'A A)") == "NIL" );

	auto B = mksym("B");
	assert( null is builtin_equal(env, mklist(mkquote(A), mkquote(B))) );
	assert( null !is builtin_equal(env, mklist(mkquote(B), mkquote(B))) );

	// Equality with three symbols
	assert( null !is builtin_equal(env, mklist(mkquote(A), mkquote(A), mkquote(A))) );
	assert( null is builtin_equal(env, cons(null, cons(null, cons()))) );
	assert( null is builtin_equal(env, mklist(A, A, null)) );
	assert( null is builtin_equal(env, mklist(B, A, A)) );
	assert( evalstr(env, "(eq 'A 'A 'A)") == "T" );
	assert( evalstr(env, "(eq 'A 'B 'A)") == "NIL" );
	assert( evalstr(env, "(eq null nil null)") == "NIL" );
}

Obj builtin_quote(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return mkquote(car(args));
}
Obj builtin_isQUOTE(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = car(args);
	return isQUOTE(A) ? mksym("T") : null;
}
Obj builtin_isSYM(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = car(args);
	return isSYM(A) ? mksym("T") : null;
}
unittest {
	auto env = mkenv();
	assert( evalstr(env, "(quote? (quote))") == "T" );
	assert( evalstr(env, "(quote? (quote 1))") == "T" );
	assert( evalstr(env, "(sym? 'X)") == "T" );
	assert( evalstr(env, "(quote? 'X)") == "NIL" );
	assert( evalstr(env, "(sym? ''X)") == "NIL" );
	assert( evalstr(env, "(quote? ''X)") == "T" );
	assert( evalstr(env, "(quote? '''X)") == "T" );
	assert( evalstr(env, "(quote? 1)") == "NIL" );
	assert( evalstr(env, "(quote 1") == "'NIL" );
	assert( evalstr(env, "(quote '1") == "'1" );
}

Obj builtin_fun(ref Obj env, Obj args) pure @safe nothrow {
	auto proc_args = car(args);
	auto proc_code = car(cdr(args));
	return (isSYM(proc_args) || isCONS(proc_args))
		 ? new Obj_Fun(proc_args, proc_code)
		 : null;
}
Obj builtin_isFUN(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = car(args);
	return isFUN(A) ? mksym("T") : null;
}
Obj builtin_if(ref Obj env, Obj args) pure @safe nothrow {
	auto cond = eval(env, car(args));
	auto next = cdr(args);
	if( cond !is null ) {
		return eval(env, car(next));
	}
	return eval(env, car(cdr(next)));
}
unittest {
	auto env = mkenv();
	assert( evalstr(env, "(fun? if") == "T" );
	assert( evalstr(env, "(fun? X") == "NIL" );
	assert( evalstr(env, "(fun? (fun x x)") == "T" );
	assert( evalstr(env, "(if T T NIL)") == "T" );
	assert( evalstr(env, "(if NIL T NIL)") == "NIL" );
	assert( evalstr(env, "(if T NIL T)") == "NIL" );
	assert( evalstr(env, "(if (fun? if) NIL T)") == "NIL" );
	assert( evalstr(env, "(if (fun? if) '1 '2)") == "1" );
	assert( evalstr(env, "(if (fun? X) '1 '2)") == "2" );
}

Obj builtin_cons(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = car(args);
	auto B = car(cdr(args));
	return cons(A, B);
}
Obj builtin_isCONS(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	auto A = car(args);
	return isCONS(A) ? mksym("T") : null;
}
Obj builtin_car(ref Obj env, Obj args) pure @safe nothrow {
	args = evlis(env, args);
	return car(car(args));
}
Obj builtin_cdr(ref Obj env, Obj args) pure @safe nothrow {
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
Obj builtin_setenv(ref Obj env, Obj args) pure @safe nothrow {
	return env = car(evlis(env, args));
}
Obj builtin_env(ref Obj env, Obj args) pure @safe nothrow {
	return env;
}
Obj builtin_setb(ref Obj env, Obj args) pure @safe nothrow {
	auto key = eval(env, car(args));
	auto val = eval(env, car(cdr(args)));
	if( key !is null && isSYM(key) ) {
		auto entry = mapfind(env, key);
		if( entry is null ) {
			env = mapadd(env, key, val);		
		}
		else {
			setcdr(entry, val);
		}
		return val;
	}
	return null;
}
Obj builtin_defb(ref Obj env, Obj args) pure @safe nothrow {
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

	auto A = cons(mksym("X"), mksym("Y"));	
	builtin_setcdr(env, mklist(mkquote(A), mksym("T")));
	assert( equal(cdr(A), mksym("T")) );
	assert( equal(car(A), mksym("X")) );
	builtin_setcar(env, mklist(mkquote(A), mksym("T")));
	assert( equal(car(A), mksym("T")) );

	evalstr(env, "(def! 'A (cons 'X 'Y))");
	assert( evalstr(env, "(cons? A)") == "T" );
	assert( evalstr(env, "(car A)") == "X" );
	assert( evalstr(env, "(cdr A)") == "Y" );
	evalstr(env, "(cdr! A T)");
	assert( evalstr(env, "(cdr A)") == "T" );
	evalstr(env, "(car! A T)");
	assert( evalstr(env, "(car A)") == "T" );

	assert( env !is null );
	assert( evalstr(env, "(env!)") == "NIL" );
	assert( env is null );
}
Obj builtin_begin(ref Obj env, Obj args) pure @safe nothrow {
	while( isCONS(args) ) {
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
	assert( evalstr(env, "(begin T)") == "T" );
	assert( evalstr(env, "(begin T NIL)") == "NIL" );
	assert( evalstr(env, "(begin X)") == "NIL" );
	assert( evalstr(env, "(begin NIL (eq T T))") == "T" );
	assert( evalstr(env, "(begin T (eq NIL NIL))") == "NIL" );
}



Obj mkenv () pure @safe nothrow {
	auto T = mksym("T");
	auto env = mklist(
		cons("env!", &builtin_setenv, mksym("NEW-ENV")),
		cons("set!", &builtin_setb, mklist(mksym("SYM"), mksym("VAL"))),
		cons("def!", &builtin_defb, mklist(mksym("SYM"), mksym("VAL"))),
		cons("cdr!", &builtin_setcdr, mklist(mksym("X"), mksym("Y"))),
		cons("car!", &builtin_setcar, mklist(mksym("X"), mksym("Y"))),

		cons("fun?", &builtin_isFUN, mklist(mksym("X"))),
		cons("quote?", &builtin_isQUOTE, mklist(mksym("X"))),
		cons("cons?", &builtin_isCONS, mklist(mksym("X"))),
		cons("sym?", &builtin_isSYM, mklist(mksym("X"))),
		cons("eq", &builtin_equal, mklist(mksym("X"), mksym("Y"))),

		cons("env", &builtin_env, null),
		cons("if", &builtin_if, mklist(mksym("X"), mksym("$TRUE"), mksym("$ELSE"))),
		cons("fun", &builtin_fun, mklist(mksym("$ARGS"), mksym("$CODE"))),
		cons("begin", &builtin_begin, mksym("EXPR")),
		cons("cons", &builtin_cons, mklist(mksym("A"), mksym("B"))),
		cons("quote", &builtin_quote, mklist(mksym("X"))),
		cons("car", &builtin_car, mklist(mksym("X"))),
		cons("cdr", &builtin_cdr, mklist(mksym("X"))),

		cons(T, T)
	);
	return env;
}
unittest {
	auto env = mkenv();
	assert( isCONS(mapfind(env, "env")) );
	assert( isCONS(mapfind(env, "cdr")) );
	assert( isSYM(car(mapfind(env, "eq"))) );
	assert( isFUN(cdr(mapfind(env, "eq"))) );
	assert( null is mapfind(env, "diwehfewi") );	
}



private bool iswhite( char ch ) pure @safe nothrow {
	return ch == '\t' || ch == ' ' || ch == '\r' || ch == '\n';
}
private bool isparen( char ch ) pure @safe nothrow {
	return ch == '(' || ch == ')' || ch == '\'';
}
private string parseToken (string str, ref int offs) pure @safe nothrow {
	while( offs < str.length && isWhite(str[offs]) ) {
		offs += 1;
	}
	if( offs >= str.length ) {
		return null;
	}

	auto start = offs;
	if( isparen(str[offs]) ) {
		offs += 1;
		return [str[offs - 1]];
	}

	// Read chars until next whitespace or parenthesis
	while( offs < str.length ) {
		if( iswhite(str[offs]) || isparen(str[offs]) ) {
			break;
		}
		offs += 1;
	}

	if( 0 == (offs - start) ) {
		return null;
	}
	return str[start .. offs];
}
private Obj parseList (ref Obj env, string str, ref int offs) pure @safe nothrow {
	auto original = offs;
	auto token = parseToken(str, offs);		
	if( token is null ) {
		return null;
	}
	if( token == ")" ) {
		return null;
	}
	if( token == "." ) {
		return parseObj(env, str, offs);
	}
	offs = original;
	auto obj = parseObj(env, str, offs);
	return cons(obj, parseList(env, str, offs));
}
private Obj parseObj (ref Obj env, string str, ref int offs) pure @safe nothrow {
	auto token = parseToken(str, offs);
	if( token is null || token == ")" ) {
		return null;
	}
	else if( token == "(" ) {
		return parseList(env, str, offs);
	}
	else if( token == "\'" ) {
		return mkquote(parseObj(env, str, offs));
	}	
	return mksym(token);
}
Obj parse (ref Obj env, string str) pure @safe nothrow {
	int offs = 0;
	if( str.length < 1 )
		return null;
	return parseObj(env, str, offs);
}



/**
 * Evaluate each item in the list individually
 */
Obj evlis(ref Obj env, Obj exps) pure @safe nothrow {
	if( exps is null ) return null;
	return cons(eval(env, car(exps)),
				evlis(env, cdr(exps)));
}
Obj eval (ref Obj env, Obj X)  pure @safe nothrow {
	if( X !is null ) {
		return X.eval(env);
	}
	return null;
}
string evalstr (ref Obj env, string X) pure @safe nothrow {
	auto res = eval(env, parse(env, X));
	if( res is null ) {
		return "NIL";
	}
	return res.toString();
}



private void repl (ref Obj env ) {
	string line;
	while( true ) {
		write("> ");
		if( (line = stdin.readln()) is null ) {
			break;
		}
		write("= ", evalstr(env, line), "\n");	
	}
}
private string readWholeFile (string filename) {
	auto buf = new OutBuffer();
	auto file = File(filename, "rb");
	return readWholeStream(file);
}
private string readWholeStream (File file) {
	auto buf = new OutBuffer();
	if( file.size != ulong.max ) {
		// XXX: this would cause segfault if size unknown
		// e.g. echo '' | ./lisp
		buf.reserve(file.size());
	}
	foreach( chunk; file.byChunk(1024*10) ) {
		buf.write(chunk);
	}
	return buf.toString();
}
private int main (string[] args) {
	auto env = mkenv();
	auto show_version = false;
	try {		
		try {
			getopt(args, "h|v|?", &show_version);
		}
		catch ( GetOptException ex ) {
			write("Error: ", ex.msg, "\n");
			show_version = true;
		}
	}
	catch( Exception ex ) {
		show_version = true;
	}
	if( show_version ) {
   		write("Usage: lisp [file ...]\n\n");
   		return 1;
	}
	// Silently evaluate any files given on the commandline
	auto files = args[1 .. args.length];
	if( files.length > 0 ) {
		foreach( string filename; files ) {
			string contents;
			try {
				contents = readWholeFile(filename);
			}
			catch( Exception ex ) {
				write("Error: ", ex.msg, "\n");
				return 1;
			}
			if( contents !is null && contents.length ) {
				auto obj = parse(env, contents);
				if( obj !is null ) {
					eval(env, obj);
				}
			}
		}
	}
	// Start a REPL if user is on a terminal
	if( isatty(stdin.fileno()) ) {
		repl(env);
		return 0;
	}
	// Otherwise evaluate the content of stdin
	auto content = readWholeStream(stdin);
	if( content !is null && content.length ) {
		write(evalstr(env, content), "\n");
	}
	return 0;
}