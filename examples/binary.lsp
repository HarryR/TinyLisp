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

	(def! 'not
		(fun (A)
			(if (eq? A 1) 0
				(if (eq? A 0) 1)
			)
		)
	)

	(def! 'or
		(fun (X Y)
			(if (eq? X 1) 1
				(if (eq? Y 1) 1 0)
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
)