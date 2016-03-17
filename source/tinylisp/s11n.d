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

module tinylisp.s11n;

private import tinylisp.core;
private import std.ascii: isWhite;


private bool skipwhite( string str, ref int offs ) pure @safe nothrow {
	while( offs < str.length ) {
		// Comments are considered whitespace, and should also be skipped
		if( str[offs] == ';' ) {
			offs++;
			while( offs < str.length && str[offs] != '\n' && str[offs] != '\r' ) offs++;			
		}
		if( ! isWhite(str[offs]) ) break;
		offs++;
	}
	return offs < str.length;
}

private bool isEndOfSymbolName( char ch ) pure @safe nothrow {
	return isWhite(ch) || ch == '(' || ch == ')' || ch == '\'' || ch == ';';
}

private Obj parseSymbol(ref Obj env, string str, ref int offs, ref bool ok) pure @safe nothrow {
	auto start = offs;
	while( offs < str.length && ! isEndOfSymbolName(str[offs]) ) {
		offs++;
	}
	if( (offs - start) <= 0 ) {
		ok = false;
		return null;
	}
	return mksym(str[start .. offs]);
}

private Obj parseQuoted(ref Obj env, string str, ref int offs, ref bool ok) pure @safe nothrow {
	auto X = parseAny(env, str, offs, ok);
	if( ! ok ) {
		return null;
	}
	return mkquote(X);
}

private Obj parseCons(ref Obj env, string str, ref int offs, ref bool ok) pure @safe nothrow {
	Obj X = cons();
	Obj Y = X;
	bool pair = false;
	bool first = true;
	while( true ) {
		if( ! skipwhite(str, offs) ) {
			ok = false;
			return null;
		}
		if( str[offs] == ')' ) {	// End of the cons/list
			if( pair ) {			// Parsing a pair, expecting another element, got ')'					
				ok = false;
				return null;
			}
			break;
		}
		auto A = parseAny(env, str, offs, ok);
		if( ! ok ) {
			return null;
		}
		if( ! skipwhite(str, offs) ) {
			ok = false;
			return null;
		}
		if( first ) {
			if( str[offs] == '.' ) {	// Parsing a pair
				offs++;
				pair = true;
			}
			Y.car = A;
			first = false;
		}
		else {
			if( pair ) {
				Y.cdr = A;
				break;
			}
			else {
				auto Z = cons(A);	// Extend list
				Y.cdr = Z;
				Y = Z;
			}
		}
	}
	if( ! skipwhite(str, offs) ) {
		ok = false;
		return null;
	}
	if( offs >= str.length || str[offs] != ')' ) { // List doesn't terminate...
		ok = false;
		return null;
	}
	offs++;
	return X;
}

private Obj parseAny(ref Obj env, string str, ref int offs, ref bool ok) pure @safe nothrow {
	if( ! skipwhite(str, offs) || str[offs] == ')' ) {
		ok = false;
		return null;
	}
	// Parse a pair or list
	if( str[offs] == '(' ) {
		offs++;
		return parseCons(env, str, offs, ok);
	}
	else if( str[offs] == '\'' ) { // Quoted object
		offs++;
		return parseQuoted(env, str, offs, ok);
	}
	return parseSymbol(env, str, offs, ok);
}

Obj parse(ref Obj env, string str) pure @safe nothrow {
	if( str.length < 1 ) return null;
	int offs = 0;
	bool ok = true;
	auto ret = parseAny(env, str, offs, ok);
	if( ok ) {
		return ret;
	}
	return null;
}

private string pairToSExpr (Obj O) pure @safe nothrow {
	string ret = "(";
	Obj X = O;
	auto first = true;
	while( isPAIR(X) ) {
		if( first ) {				
			first = false;
		}
		else {
			ret ~= " ";
		}
		auto val = X.car;
		if( val is null ) {
			ret ~= "NIL";
		}
		else {
			ret ~= val.sexpr;
		}
		X = X.cdr;
	}
	if( X !is null ) {
		ret ~= " . " ~ X.sexpr;
	}
	return ret ~ ")";
}

private string quoteToSExpr (Obj O) pure @safe nothrow {
	if( O.inside is null ) {
		return "'NIL";
	}
	return "'" ~ O.inside.sexpr;
}

private string funToSExpr (Obj_Fun O) pure @safe nothrow {
	auto args = O.args_spec ? O.args_spec.sexpr : "?";
	auto code = O.code ? O.code.sexpr : "NIL";
	return "(fun " ~ args ~ " " ~ code ~ ")";
}

private string closureToSExpr (Obj_Closure O) pure @safe nothrow {
	return "(closure " ~ O.bindings.sexpr ~ " " ~ O.inside.sexpr ~ ")";
}

private string builtinToSExpr(Obj_Builtin O) pure @safe nothrow {
	return "(fun " ~ (O.args_spec is null ? "?" : O.args_spec.sexpr) ~ " ...)";
}

@property string sexpr(Obj O) pure @safe nothrow {
	if( O.isPAIR ) return pairToSExpr(O);
	if( O.isSYM ) return O.name;
	if( O.isQUOTE ) return quoteToSExpr(O);
	if( O.isFUN ) return funToSExpr(cast(Obj_Fun)O);
	if( O.isBUILTIN ) return builtinToSExpr(cast(Obj_Builtin)O);
	if( O.isCLOSURE ) return closureToSExpr(cast(Obj_Closure)O);
	return "NIL";
}
