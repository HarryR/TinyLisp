.load examples/std.lsp
> (zip (list 'A 'B) (list 'C 'D))
= ((A . C) (B . D))

> (any? . T)
= T
> (any? NIL T NIL)
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