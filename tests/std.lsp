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
> (list-end? (list 'A 'B))
= NIL

> (list-append! (list 'A 'B) 'C)
= (A B C)
> (list-append! (list 'A) 'B)
= (A B)

> (list-pop! (list 'A 'B))
= A
> (def! 'TEST (list 'A 'B 'C))
> (list-pop! TEST)
= A
> (list-pop! TEST)
= B
> TEST
= (C)
; Verify we can pop from the environment
> (car (env))
= (TEST C)
> (list-pop! (env))
= (TEST C)
> TEST
= NIL

> (list-push! (list 'B 'C) 'A)
= (A B C)

> (def! 'TEST (list 'A 'B 'C))
> (list-eject! TEST)
= C
> TEST
= (A B)

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

> (map (list 'A 'B 'DERP 'C 'DERP) (fun (X) (eq? X 'DERP)))
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

> (def! 'setup-lambda (fun (NIL) (begin (def! 'derp 'poop) (lambda (derp) (A) (begin (def! 'OLD derp) (set! 'derp A) (list OLD derp))))))
> (def! 'evil (setup-lambda))
> (evil 'A)
= (poop A)
> (evil 'B)
= (A B)

> (def! 'derpX (fun (ARG) (list 'X ARG)))
> (def! 'derpY (fun (ARG) (list 'Y ARG)))
> (def! 'derpZ (fun (ARG) (list 'Z ARG)))
> (derpZ (derpY (derpX 'A)))
= (Z (Y (X A)))
> (chain 'A derpX derpY derpZ)
= (Z (Y (X A)))

> (cond (T 'DERP))
= DERP