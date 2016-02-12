.load examples/std.lsp

> (zip (list 'A 'B) (list 'C 'D))
= ((A . C) (B . D))

> (any? T)
= T
> (any? NIL T NIL)
= T
> (any? NIL)
= NIL
> (any? T T)
= T
> (any? T NIL)
= T
> (any? NIL T)
= T

> (list-end?)
= T

> (not-T? NIL)
= T
> (not-T? (cons 'A 'B))
= T
> (not-T? T)
= NIL

> (not-NIL? NIL)
= NIL
> (not-NIL? T)
= T
> (not-NIL? 'DERP)
= T

> (nil? NIL)
= T
> (nil? 'DERP)
= NIL

> (all? T T)
= T
> (all? T NIL T)
= NIL

> (map (fun (X) (eq? X 'DERP)) (list 'A 'B 'DERP 'C 'DERP))
= (NIL NIL T NIL T)

> (reduce (fun (A B) (if (eq? (if A T) (if B T)) A)) T (list T T T))
= T

> (list-2nd (list 'A 'B))
= B

> (list-3rd (list 'A 'B 'C))
= C

> (list-3rd (cycle (list 'A 'B)))
= A
> (list-2nd (cycle (list 'A 'B)))
= B

> (reverse (list 'A 'B 'C))
= (C B A)
> (reverse (list 'A))
= (A)