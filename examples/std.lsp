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
	(def! 'any? (fun LIST (begin
		(if (cons? LIST)
			; Recursively check if any elements are T
			(if (car LIST)
				T
				(if (cons any (cdr LIST)) T)
			)
			; Otherwise an immediate value test
			(if LIST T)
		)
	)))


	; Is this the last element of a list?
	(def! 'list-end? (fun (LIST)
		(if (cons? LIST)
			(eq? (cdr LIST) NIL)
			T
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
			T
			NIL
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


	; Return NIL of any of the arguments are not T, or lists of T (recursively)
	;
	;	> (all? T T)
	;	= T
	;
	;	> (all? T NIL T)
	;	= NIL
	;
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
)
