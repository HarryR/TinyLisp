# TinyLISP 

[![Build Status](https://drone.io/github.com/HarryR/TinyLisp/status.png)](https://drone.io/github.com/HarryR/TinyLisp/latest)

The `Tiny` Lisp 1.5 inspired interpreter is written around 1000 lines of Digital Mars D and supports a minimal but consistent suite of built-in functions which should be familiar to Lisp and Scheme users, however a major distinction is that this Lisp variant doesn't have integers, strings or useful data types, it only has symbols and expressions. The six data types supported are: `SYM`, `PAIR`, `FUN`, `BUILTIN`, `QUOTE` and `NIL`.

Consider this programming Lisp, in ultra-hard difficulty, a Lisp-flavoured dynamic assembly language for symbolic logic. The basic constructs and method of evaluation should be compared to metaprogramming, the runtime provides a way of constructing, organising and operating on symbols to compute the desired results, but lacks the complex data types necessary to make life easy.

    With sweat, blood, tears and logic, anything is possible in TinyLISP™

## Features

  * Garbage collection
  * Lazy evaluation
  * Familiar LISP syntax
  * UTF-8 in symbols
  * Memory safe interpreter

The interpreter can operate in two modes: REPL and batch, it also accepts a list of files on the command line which will be silently evaluated and can be used to prepare the environment or load libraries of functions etc.

Batch mode reads one expression from `stdin` and prints the evaluation result to `stdout`.

```
$ echo '(eq? T T)' | ./lisp
T
```

REPL mode provides an interactive shell environment to evaluate commands one at a time, it facilitates exploratory programming and debugging.

```
$ ./lisp
> (eq? T T)
= T
> ...
```

The small number of built-in functions are easily remembered, for reference they are:

  * `(env)` - Get environment
  * `(env! NEW-ENV)` - Set environment
  * `(if (X $THEN $ELSE) ...)` - Conditional
  * `(fun ($ARGS $CODE) ...)` - Create function
  * `(eval (EXPR) ...)` - Evaluate a constructed expression
  * `(begin EXPR ...)` - Evaluate many, return last
  * `(eq? (A B) ...)` - Are `A` and `B` equal?
  * `(cons (A B) ...)` - Create pair
  * `(quote (X) ...)` - Encapsulate / escape the value
  * `(car (X) ...)` - Get `A` record from pair
  * `(cdr (X) ...)` - Get `B` record from pair
  * `(car! (X Y) ...)` - Set `A` record of pair `X` to `Y`
  * `(cdr! (X Y) ...)` - Set `B` record of pair `X` to `Y`
  * `(set! (SYM VAL) ...)` - Overwrite or add symbol to env
  * `(def! (SYM VAL) ...)` - Add symbol to env
  * `(fun? (X) ...)` - Is `X` a function or builtin?
  * `(builtin? (X) ...)` - Is `X` a native builtin function?
  * `(closure ($CAPTURE INSIDE))` - Capture variables into a scope
  * `(closure? (X) ...)` - Is `X` a closure?
  * `(sym? (X) ...)` - Is `X` a symbol?
  * `(quote? (X) ...)` - Is `X` quote encapsulated?
  * `(cons? (X) ...)` - Is `X` a pair? - constructed with (cons ...)
  * `(nil? (X) ...)` - Is `X` a `NIL` value? (null/void etc.)
  * `(list ARGS ...)` - Return ARGS after evaluation, as a list

### Bugs & TODO?

[SafeD](http://dlang.org/safed.html) is enforced throughout the interpreter to prevent bugs, combined with graceful failure when functions are passed `null` values, thorough unit testing and good code coverage it means that the only time the interpreter should crash if the runtime behavior causes a call chain which exceeds the process stack limit.

 * `(cdr! (car (env)) (env))` = segfault during `Obj.toString()` and `equal()` because recursive references aren't taken into consideration.
 * Useful standard library or libraries
 * Closures
 * Quasiquote, slicing, e.g. backtick, comma and `,@` operators 
 * More interesting examples
 * Ad-hoc evaluation (interpret data as code, like `eval`)
 * Useful syntax and parsing errors

## Syntax Conventions

 * Comments begin with a semicolon (;) and continue until the end of the line
 * Symbol names should be `UPPERCASE`
 * Function names should be `lowercase`
 * Functions which modify the environment or their parameters should be suffixed with an `!` exclamation mark.
 * Functions which return either `T` or `NIL` should be suffixed with a `?` question mark.
 * Pairs are constructed using the `.` dot, e.g. `(X . Y)`
 * Lists are created by default unless the `.` dot is used, e.g. `(X Y Z)` is equivalent to `(X . (Y . (Z . NIL)))`


## Examples

```lisp
; Combine elements from two lists into a single list of pairs
;
;   > (zip (list 'A 'B) (list 'C 'D))
;   = ((A . C) (B . D))
;
(def! 'zip (fun (LIST-A LIST-B) (begin
  (def! 'CAN-ZIP (if (cons? LIST-A) (cons? LIST-B)))
  (if CAN-ZIP (begin
    (cons
      (cons (car LIST-A) (car LIST-B))
      (zip (cdr LIST-A) (cdr LIST-B))
    )
  ))
)))
```

## Builtin Functions

#### `(env)`

Returns the environment object, an associative list of pairs containing the key and value. The initial environment is populated with the interpreters built-in functions and the `T` symbol.

```
> (env)
= ((env! . (fun X ...)) (set! . (fun (SYM VAL) ...)) ... (T . T))
```

#### `(if (X $THEN $ELSE) ...)`

The `if` function uses both immediate and lazy evaluation to check if the first argument is non-`NIL` and then evaluates and returns either then `$THEN` or `$ELSE` expressions.

```
> T
= T
> (if T 'YAY 'NAY)
= YAY
```

```
> X
= NIL
> (if X 'YAY 'NAY)
= NAY
```

#### `(fun ($ARGS $CODE) ...)`

Creates a function which will have its own scope when evaluated, control over argument evaluation is expressed in the arguments list, arguments can be evaluated or passed verbatim and be expanded into variables or accessible as a list.

  * `$ARGS` - Verbatim, variable length
  * `ARGS` - Evaluated, variable length
  * `(A B)` - Expanded, both A and B evaluated
  * `($A B)` - Expanded, only B is evaluated

```
> (set! derp (fun $ARGS $ARGS))
= (fun $ARGS $ARGS)
> (derp)
= NIL
> (derp 1 2 3)
= (1 2 3)
```

Whereas if the arguments are evaluated by omitting the dollar symbol then symbols must be quoted to pass them to the function.

```
> (set! derp (fun ARGS ARGS))
= (fun ARGS ARGS)
> (derp)
= NIL
> (derp 1 '2 3)
= (NIL 2 NIL)
```

#### `(begin EXPR ...)`

Evaluates a list of expressions and returns the result of the last expression.

```
> (begin T)
= T
> (begin NIL T)
= T
```

#### `(cons (A B) ...)`

Creates a pair with the first and second argument, arguments are evaluated when calling.

```
> (cons)
= (NIL)
> (cons 'A)
= (A)
> (cons 'A 'B)
= (A . B)
```

#### `(quote (X) ...)`

The argument is evaluated and then converted to a quoted expression which will pass through an evaluation stage.

#### `(car (X) ...)`

Returns the A record of a pair. If `X` is a function it will return the arguments object. Combined with `(cdr)` this allows for introspection, manipulation and refection at the function level

```
> (car (cons 'X 'Y))
= X
> (car if)
= (X $TRUE $ELSE)
```

#### `(cdr (X) ...)`

Returns the B record of a pair. If `X` is a function it will return the code object if it's a user defined function, for native built-in functions the same function will be returned.

```
> (cdr (cons 'X 'Y))
= Y
> (cdr if)
= (fun (X $TRUE $ELSE) ...)
> (cdr (fun X Y))
= Y
```

#### `(env! NEW-ENV)`

Change the environment of the scope to a new value, the environment is an associative list of symbols and their values, the interpreter uses the environment to resolve symbols to their values.

```
> (env)
= (... (T . T))
> (env! (cons (cons 'X 'Y) (env)))
= ((X . Y) ... (T . T))
```

If the environment is overwritten with `NIL` or otherwise doesn't follow the necessary pair list convention then it will be impossible to evaluate further expressions as internal symbol resolution will be broken.

#### `(set! (SYM VAL) ...)`

Change the value a variable in the environment, if the variable doesn't exist it is created.

```
> (env)
= (... (T . T))
> (set! 'X T)
= T
> X
= T
> (env)
= ((X . T) ... (T . T))
> (set! 'X 'Y)
= Y
> X
= Y
> (env)
= ((X . Y) ... (T . T))
```

While the `set!` function is builtin it is possible to implement it as a user defined function as the environment can be modified by the `env` and `env!` functions.

#### `(def! (SYM VAL) ...)`

Define a new symbol by adding it to the environment, a new pair will always be added to the environment, use `set!` to overwrite an existing symbol.

```
> (env)
= (... (T . T))
> (def! 'X T)
= T
> (env)
= ((X . T) ... (T . T))
> (def! 'X T)
= T
> (env)
= ((X . T) (X . T) ... (T . T))
> X
> T
```

#### `(cdr! (X Y) ...)`

Change the B record of the pair `X` to the new value in `Y`, returns the old value.

#### `(car! (X Y) ...)`

Change the B record of a the pair `X` to the new value in `Y`, returns the old value.

#### `(fun? (X) ...)`

Is `X` a function or builtin which can be used in the left hand side of an expression?

```
> (fun? if)
= T
> (fun? (fun X))
= T
```

#### `(builtin? (X) ...)`

Is `X` a native builtin function.

```
> (builtin? if)
= T
> (builtin? (fun X))
= NIL
```


#### `(closure? (X) ...)`

Is `X` a native closure scope?

#### `(eval (EXPR) ...)`

Evaluate the expression in the current environment

```
> (eval (list cons T T))
= (T . T)
```

#### `(sym? (X) ...)`

Is `X` a symbol:

```
> (sym? X)
= NIL
> (sym? 'X)
= T
```

#### `(quote? (X) ...)`

Is `X` a quoted expression?

```
> (quote? (quote))
= T
> (quote? X)
= NIL
> (quote? 'X)
= NIL
> (quote? ''X)
= T
```

#### `(cons? (X) ...)`

Return `T` if `X` is a pair.

```
> (cons? (cons))
= T
```

#### `(nil? (X) ...)`

Return `T` if `X` is `NIL`.

```
> (nil? (cons))
= NIL
> (nil? NIL)
= T
```

#### `(eq? (A B) ...)`

The quality function compares `A` to `B` and returns `T` if they are the same, or `NIL` if they're not. It supports equality operations on all types, including pairs and built-in functions. Comparing pairs is recursive and the contents of each element of the pair are compared, self referential pairs or looped graph structures will go into an infinite loop when checking for quality. Comparing two functions is exactly the same as comparing two pairs as the function is represented by its arguments and code.

```
> (eq? T NIL)
= NIL
> (eq? NIL NIL)
= T
> (eq? T NIL)
= NIL
> (eq? eq eq)
= T
> (eq? eq if)
= NIL
> (eq? (quote (cons 'A)) (quote (cons 'A)))
= T
> (eq? (quote (cons 'A)) (quote (cons 'B)))
= NIL
```


## License

Based on the Simple Lisp Interpreter in C by Andru Luvisi - http://www.sonoma.edu/users/l/luvisi/

```
A minimal Lisp interpreter
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
```