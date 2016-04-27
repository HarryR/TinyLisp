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

module tinylisp.core;

private enum Type {
	SYM, PAIR, FUN, QUOTE, BUILTIN, CLOSURE
}

class Obj {
	@property abstract Type type () const pure @safe nothrow;
	@property static Obj T () pure @trusted nothrow {
		static immutable Obj T = mksym("T");
		return cast(Obj)T;
	}
	abstract bool equals(Obj O) pure @safe nothrow;
}


package class Obj_Pair : Obj {
	Obj A;
	Obj B;
	this( Obj A, Obj B ) pure @safe nothrow {
		this.A = A;
		this.B = B;
	}
	override Type type () const pure @safe nothrow {
		return Type.PAIR;
	}
	override bool equals(Obj O) pure @safe nothrow {
		assert(O !is null && O.type() == type());
		auto other = cast(Obj_Pair)O;
		return equal(A, other.car) && equal(B, other.cdr);
	}
}


package class Obj_Sym : Obj {
	string name;
	this( string name ) pure @safe nothrow {
		this.name = name;
	}
	override Type type () const pure @safe nothrow {
		return Type.SYM;
	}
	override bool equals(Obj O) pure @safe nothrow {
		assert(O !is null && O.type() == type());
		Obj_Sym other = cast(Obj_Sym)O;
		return name == other.name;
	}
}

package class Obj_Quote : Obj {
	Obj inside;
	this(Obj inside) pure @safe nothrow {
		this.inside = inside;
	}
	override Type type () const pure @safe nothrow {
		return Type.QUOTE;
	}
	override bool equals(Obj O) pure @safe nothrow {
		assert(O !is null && O.type() == type());
		Obj_Quote other = cast(Obj_Quote)O;
		return equal(inside, other.inside);
	}
}

/++
 + Allows for variables to be bound into a scope which can
 + be passed around, when a closure is evaluated its bindings
 + are added to the environment, then it's inside is evaluated.
 +
 +    (closure (X Y) (fun (Z) (list X Y Z)))
 +/
package class Obj_Closure : Obj_Quote {
	Obj bindings;
	this( Obj bindings, Obj inside ) pure @safe nothrow {
		super(inside);
		this.bindings = bindings;
	}
	override Type type () const pure nothrow @safe {
		return Type.CLOSURE;
	}
	override bool equals(Obj O) pure @safe nothrow {
		assert(O !is null && O.type() == type());
		Obj_Closure other = cast(Obj_Closure)O;
		return equal(bindings, other.bindings) && equal(inside, other.inside);
	}
}

@property inside(Obj O) pure @safe nothrow {
	if( O.isQUOTE || O.isCLOSURE ) return (cast(Obj_Quote)O).inside;
	return null;
}

public alias Obj function(ref Obj env, Obj args) pure @safe nothrow Builtin;
package abstract class Obj_HasArgs : Obj {
	Obj args_spec;
}

package abstract class Obj_Builtin : Obj_HasArgs {
	override Type type () const pure nothrow @safe {
		return Type.BUILTIN;
	}
	abstract Obj opCall(ref Obj env, Obj args) pure @safe nothrow;
	@property abstract protected uint builtin_typeid() const pure @safe nothrow;
}

package class Obj_BuiltinFun : Obj_Builtin {
	Builtin func;
	this( Builtin builtin, Obj args_spec) pure @safe nothrow {
		this.func = builtin;
		this.args_spec = args_spec;
	}
	override Obj opCall(ref Obj env, Obj args) pure @safe nothrow {
		return this.func(env, args);
	}
	override uint builtin_typeid() const pure @safe nothrow {
		return 1;
	}
	override bool equals(Obj O) pure @safe nothrow {		
		return (cast(Obj_BuiltinFun)O).builtin_typeid == builtin_typeid
			&& (cast(Obj_BuiltinFun)O).func == this.func;
	}
}

package class Obj_Fun : Obj_HasArgs {
	Obj code;
	this( Obj args_spec, Obj code) pure @safe nothrow {
		this.code = code;
		this.args_spec = args_spec;
	}
	override Type type () const pure nothrow @safe {
		return Type.FUN;
	}
	override bool equals(Obj O) pure @safe nothrow {
		assert( O !is null && O.type() == type() );
		auto funY = cast(Obj_Fun)O;
		// Order matters, comparison of code could be expensive
		return equal(args_spec, funY.args_spec)
			&& equal(code, funY.code);
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
	else if( X.type() == Y.type() ) {
		return X.equals(Y);
	}
	return false;
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
Obj mkclosure (Obj bindings, Obj inside) pure @safe nothrow {
	return new Obj_Closure(bindings, inside);
}
Obj mkfun (Builtin func, Obj args) pure @safe nothrow {
	return new Obj_BuiltinFun(func, args);
}
Obj mkproc (Obj args, Obj code) pure @safe nothrow {
	return new Obj_Fun(args, code);
}
private bool istype( const Obj O, const(Type) T ) pure @safe nothrow {
	return O !is null && O.type == T;
}
@property bool isFUN( const Obj O ) pure @safe nothrow {
	return istype(O, Type.FUN);
}
@property bool isBUILTIN( const Obj O ) pure @safe nothrow {
	return istype(O, Type.BUILTIN);
}
@property bool isSYM( const Obj O ) pure @safe nothrow {
	return istype(O, Type.SYM);
}
@property bool isQUOTE( const Obj O ) pure @safe nothrow {
	return istype(O, Type.QUOTE);
}
@property bool isCLOSURE( const Obj O ) pure @safe nothrow {
	return istype(O, Type.CLOSURE);
}
@property bool isPAIR( const Obj O ) pure @safe nothrow {
	return istype(O, Type.PAIR);
}
@property string name( const Obj O ) pure @safe nothrow {
	return isSYM(O) ? (cast(const(Obj_Sym))O).name : null;
}
@property bool isVARSYM( const Obj O ) pure @safe nothrow {
	auto name = O.name;
	if( name ) {
		return name !is null && name.length > 0 && name[0] == '$';
	}
	return false;
}



/*
 * CONS related functions
 */
Obj cons(string name, Builtin builtin) pure @safe nothrow {
	return cons(mksym(name), mkfun(builtin, null));
}

Obj cons(string name, string arg, Builtin builtin) pure @safe nothrow {
	return cons(mksym(name), mkfun(builtin, mksym(arg)));
}

Obj cons(string name, string[] args_list, Builtin builtin) pure @safe nothrow {
	return cons(mksym(name), mkfun(builtin, symlist(args_list)));
}

Obj cons(Obj A = null, Obj B = null) pure @safe nothrow {
	return new Obj_Pair(A, B);
}

Obj symlist(string[] args ...) pure @safe nothrow {
	Obj ret = null;
	for( auto i = args.length; i != 0; i-- ) {
		ret = cons(mksym(args[i - 1]), ret);		
	}
	return ret;
}
Obj mklist(Obj[] args ...) pure @safe nothrow {
	Obj ret = null;
	for( auto i = args.length; i != 0; i-- ) {
		ret = cons(args[i - 1], ret);		
	}
	return ret;
}
@property Obj car(Obj X) pure @safe nothrow {
	if( X.isPAIR ) return (cast(Obj_Pair)X).A;
	else if( X.isFUN || X.isBUILTIN ) return (cast(Obj_HasArgs)X).args_spec;
	else if( X.isCLOSURE ) return (cast(Obj_Closure)X).bindings;
	return null;
}
@property Obj car(Obj X, Obj Y) pure @safe nothrow {
	Obj old = X.car;
	if( X.isPAIR ) (cast(Obj_Pair)X).A = Y;
	else if( X.isFUN ) (cast(Obj_Fun)X).args_spec = Y;
	else if( X.isCLOSURE ) (cast(Obj_Closure)X).bindings = Y;
	return old;
}
@property Obj cdr(Obj X) pure @safe nothrow {
	if( X.isPAIR ) return (cast(Obj_Pair)X).B;
	else if( X.isFUN ) return (cast(Obj_Fun)X).code;
	else if( X.isBUILTIN ) return X;
	else if( X.isCLOSURE ) return (cast(Obj_Closure)X).inside;
	return null;
}
@property Obj cdr(Obj X, Obj Y) pure @safe nothrow {
	Obj old = X.cdr;
	if( X.isPAIR ) (cast(Obj_Pair)X).B = Y;
	else if( X.isFUN ) (cast(Obj_Fun)X).code = Y;
	else if( X.isCLOSURE ) (cast(Obj_Closure)X).inside = Y;
	return old;
}


/*
 * Associative list functions
 */
Obj mapfind (Obj X, Obj Y) pure @safe nothrow {
	while( X.isPAIR ) {
		auto Z = X.car;
		if( Z.isPAIR && Z.car.equal(Y) ) {
			return Z;
		}
		X = X.cdr;
	}
	return null;	
}
Obj mapfind (Obj X, string Y) pure @safe nothrow {
	return mapfind(X, mksym(Y));
}
Obj mapadd (Obj X, Obj key, Obj val) pure @safe nothrow {
	return cons(cons(key, val), X);
}
