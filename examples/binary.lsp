(begin
	(def! '0 '0)
	(def! '1 '1)

	(def! 'binary?
		(fun (A)
			(if (eq? A 1) T
				(if (eq? A 0) T)
			)
		)
	)

	(def! 'binary
		(fun (A)
			(if (binary? A) A 0)
		)
	)

	(def! 'not
		(fun (A)
			(if (eq? A 1) 0
				(if (eq? A 0) 1)
			)
		)
	)

	(def! 'or
		(fun (X Y)
			(if (eq?
					(cons (binary? X) (binary? Y))
					'(T . T)
				)
				(if (eq? X 1) 1
					(if (eq? Y 1) 1 0)
				)
			)
		)
	)

	(def! 'nor (fun (X Y) (not (or X Y))))

	(def! 'and
		(fun (X Y)
			(nor (not X) (not Y))
		)
	)

	(def! 'nand (fun (X Y) (not (and X Y))))

	(def! 'xor
		(fun (X Y)
			(nor (and X Y) (nor X Y))
		)
	)

	(def! 'xnor (fun (X Y) (not (xor X Y))))

	(def! 'imply
		(fun (R I)
			(or (not R) I)
		)
	)

	(def! 'aio
		(fun (A B C D)
			(nor (and A B) (and C D))
		)
	)

	(def! 'oai
		(fun (A B C D)
			(nand (or A B) (or C D))
		)
	)

	(def! 'half-adder
		(fun (A B)
			(cons (xor A B) (and A B))
		)
	)

	(def! 'full-adder
		(fun (A B C) (begin
			(set! 'C (binary C))
			(def! 'X (half-adder A B))
			(def! 'Y (half-adder C (car X)))
			(cons
				(car Y)
				(or (cdr X) (cdr Y))
			)
		))
	)

	(def! 'adder
		(fun (LIST-A LIST-B C) (begin
			(def! 'INPUT-A (car LIST-A))
			(def! 'INPUT-B (car LIST-B))
			(if (or
					(not (binary (if (eq? INPUT-A NIL) 1)))
					(not (binary (if (eq? INPUT-B NIL) 1)))
				)
				(begin
					(set! 'C (binary C))
					(def! 'X (full-adder (binary INPUT-A) (binary INPUT-B) C))
					(def! 'NEXT-A (cdr LIST-A))
					(def! 'NEXT-B (cdr LIST-B))
					(def! 'CONTINUE
						(if (if (cons? NEXT-A) T (cons? NEXT-B)) T (eq? (cdr X) 1))
					)
					(cons
						(car X)
						(if CONTINUE
							(adder NEXT-A NEXT-B (cdr X))
						)
					)
				)
			)
		))
	)
)