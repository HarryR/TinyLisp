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
			(cons? (cdr LIST))
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


	(def! 'all:list? (fun (LIST)
		(if (cons? LIST)
			(begin
				(def! 'ITEM (car LIST))
				(if (cons? ITEM)
					; Item is another list...
					(if (all:list? ITEM)
						; ITEM (a list) contains only T values..
						(if (list-end? LIST)
							T
							(all:list? (cdr LIST))
						)
					)
					; Otherwise item is a value
					(if (eq? ITEM T)
						; Item is T ... move to next item
						(if (list-end? LIST)
							T
							(all:list? (cdr LIST))
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
		(all:list? LIST)
	))
)