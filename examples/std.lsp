(begin
	; Combine elements from two lists into a single list of pairs
	;
	; 	> (zip (list 'A 'B) (list 'C 'D))
	;	= ((A . C) (B . D))
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


	; Determine if any of the arguments evaluate to T (True)
	; Returns T if any are T, or NIL if none are
	;
	;	> (any? . T)
	;	= T
	;
	;	> (any? NIL T NIL)
	;	= T
	;
	(def! 'any-list? (fun (LIST)
		(if (cons? LIST)
			(if (cons? (car LIST))
				; Item is another list...
				(if (any-list? (car LIST)) T)
				; Otherwise item is a value
				(if (eq? (car LIST) T)
					T
					(if (list-end? LIST)
						NIL
						(any-list? (cdr LIST))
					)
				)
			)
		)
	))
	(def! 'any? (fun LIST (begin
		(any-list? LIST)
	)))


	; Is this the last element of a list?
	(def! 'list-end? (fun (LIST)
		(if (cons? LIST)
			(eq? (cdr LIST) NIL)
			T
		)
	))


	; Append ITEM to the end of LIST
	(def! 'list-append! (fun (LIST ITEM CARRY)
		(if (cons? LIST) (begin
			(set! 'CARRY (if (nil? CARRY) LIST CARRY))
			(if (list-end? LIST)
				(begin
					(cdr! LIST (cons ITEM NIL))
					CARRY
				)
				(list-append! (cdr LIST) ITEM CARRY)
			)
		))
	))


	; Pop the first item off the list and return it
	(def! 'list-pop! (fun (LIST)
		(if (cons? LIST) (begin
			(def! 'ITEM (car LIST))
			(def! 'NEXT-ITEM (car (cdr LIST)))
			(def! 'NEXT-TAIL (cdr (cdr LIST)))
			(car! LIST NEXT-ITEM)
			(cdr! LIST NEXT-TAIL)
			ITEM
		))
	))


	; Push an item onto the head of the list
	; Returning the new head of the list
	(def! 'list-push! (fun (LIST ITEM)
		(if (cons? LIST) (begin
			(def! 'NEXT-ITEM (car LIST))
			(def! 'NEXT-TAIL (cdr LIST))
			(car! LIST ITEM)
			(cdr! LIST (cons NEXT-ITEM NEXT-TAIL))
			LIST
		))
	))


	; Remove the last item from he list and return it
	(def! 'list-eject! (fun (LIST PREV)
		(if (cons? LIST)
			(if (list-end? LIST)
				(begin
					(cdr! PREV NIL)
					(car LIST)
				)
				(begin
					(set! PREV (if (nil? PREV) LIST PREV))
					(list-eject! (cdr LIST) LIST)
				)
			)
		)
	))


	; Is the value not T?
	;
	;	> (not-T? NIL)
	;	= T
	;
	;	> (not-T? (cons 'A 'B))
	;	= T
	;
	;   > (not-T? T)
	;	= NIL
	;
	(def! 'not-T? (fun (VALUE)
		(if (eq? VALUE T)
			NIL
			T
		)
	))


	; Is the value anything other than NIL?
	;
	;	> (not-NIL? NIL)
	;	= NIL
	;
	;	> (not-NIL? T)
	;	= T
	;
	;	> (not-NIL? 'DERP)
	;	= T
	;
	(def! 'not-NIL? (fun (VALUE)
		(if (eq? VALUE NIL)
			NIL
			T
		)
	))


	; Is the value NIL?
	;
	;	> (nil? NIL)
	;	= T
	;
	;	> (nil? 'DERP)
	;	= NIL
	;
	(def! 'nil? (fun (VALUE)
		(eq? VALUE NIL)
	))


	(def! 't? (fun (VALUE)
		(eq? VALUE T)
	))


	; Return NIL of any of the arguments are not T, or lists of T (recursively)
	;
	;	> (all? T T)
	;	= T
	;
	;	> (all? T NIL T)
	;	= NIL
	;
	(def! 'all-list? (fun (LIST)
		(if (cons? LIST)
			(begin
				(def! 'ITEM (car LIST))
				(if (cons? ITEM)
					; Item is another list...
					(if (all-list? ITEM)
						; ITEM (a list) contains only T values..
						(if (list-end? LIST)
							T
							(all-list? (cdr LIST))
						)
					)
					; Otherwise item is a value
					(if (eq? ITEM T)
						; Item is T ... move to next item
						(if (list-end? LIST)
							T
							(all-list? (cdr LIST))
						)
					)
				)
			)
		)
	))
	(def! 'all? (fun LIST
		(all-list? LIST)
	))


	; Use a function to filter a list
	; Pass each item of the list to the function
	; Return a list containing only items where the function returns T
	;
	;	> (filter (fun (X) (eq? X 'DERP)) (list 'A 'B 'DERP 'C 'DERP))
	;	= (DERP DERP)
	;
	;	> (filter (fun (X) T) (list 'A 'B 'C))
	;	= (A B C)
	;
	(def! 'filter (fun (FUN LIST)
		(if (cons? LIST)
			(if (FUN (car LIST))
				(cons (car LIST) (filter FUN (cdr LIST)))
				(filter FUN (cdr LIST))
			)
		)
	))


	; Applies a function to a list
	; Returns a list containing the results
	;
	;	> (map (fun (X) (eq? X 'DERP)) (list 'A 'B 'DERP 'C 'DERP))
	;	= (NIL NIL T NIL T)
	;
	(def! 'map (fun (FUN LIST)
		(if (cons? LIST)
			(cons (FUN (car LIST)) (map FUN (cdr LIST)))
		)
	))


	; Fold the list into the function
	; Reducing it to a single output value
	;
	;	> (reduce (fun (A B) (if (eq? (if A T) (if B T)) A)) T (list T T T))
	;	= T
	;
	(def! 'reduce (fun (FUN ARG LIST)
		(if (cons? LIST)
			(reduce FUN (FUN ARG (car LIST)) (cdr LIST))
			ARG
		)
	))


	; Get the second VALUE from a list
	;
	;	> (list-2nd (list 'A 'B))
	;	= B
	;
	(def! 'list-2nd (fun (LIST)
		(car (cdr LIST))
	))


	; Get the third VALUE from a list
	;
	;	> (list-3rd (list 'A 'B 'C))
	;	= C
	;
	(def! 'list-3rd (fun (LIST)
		(car (cdr (cdr LIST)))
	))


	; Connect the end of the list to the beginning of the list
	;
	;	> (cycle (list 'A 'B))
	;	= ... infinite recursion while printing result
	;
	;	> (list-3rd (cycle (list 'A 'B)))
	;	= A
	;
	;	> (list-2nd (cycle (list 'A 'B)))
	;	= B
	;
	(def! 'cycle (fun (LIST HEAD)
		(if (cons? LIST) (begin
			(if (nil? HEAD) (set! 'HEAD LIST))
			(if (list-end? LIST)
				(begin
					(cdr! LIST HEAD)
					HEAD
				)
				(cycle (cdr LIST) HEAD)
			)
		))
	))


	; Return the list in reverse order
	;
	;	> (reverse (list 'A 'B 'C))
	;	= (C B A)
	;
	(def! 'reverse (fun (LIST CARRY)
		(if (cons? LIST)
			(if (list-end? LIST)
				(cons (car LIST) CARRY)
				(reverse (cdr LIST) (cons (car LIST) CARRY))
			)
		)
	))


	; Create a function with captured environment
	;
	;	> (lambda (CAP1 CAP2) (ARG1) (list CAP1 CAP2 ARG1))
	;
	(def! 'lambda (fun ($CAPTURE $ARGS $CODE)
		(eval (list fun $ARGS
			(eval (list closure $CAPTURE $CODE))
		))
	))

	(def! 'chain-list (fun (ARG FUNS)
		(if (list-end? FUNS)
			(eval (list (car FUNS) 'ARG))
			(chain-list
				(eval (list (car FUNS) 'ARG))
				(cdr FUNS)))
	))

	; Allows for tacit/chain programming
	;
	;	> (chain arg fun1 fun2 fun3)
	;
	;  is equivalent to:
	;
	;   (fun3 (fun2 (fun1 arg)))
	;
	(def! 'chain (fun ARGS
		(chain-list (car ARGS) (cdr ARGS))
	))


	; Apply arguments to a function
	;
	;	> (apply sym? (list 'T))
	;	= T
	;
	(def! 'apply (fun (FUN ARGS)
		(eval (cons FUN ARGS))
	))


	; The value returned by COND is computed as follows:
	;
	;  if condition1 is true (not NIL), then return result1;
	;  else if condition2 is true then return result2;
	;  else if ...;
	;
	(def! 'cond (fun $CLAUSES
		(begin
			(def! 'CLAUSE (car $CLAUSES))
			(if (eval (car CLAUSE))
				(eval (car (cdr CLAUSE)))
				(if (list-end? $CLAUSES)
					NIL
					(apply cond (cdr $CLAUSES))
				)
			)
		)
	))
)
