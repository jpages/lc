
(letrec ((a #f)
         (b #f)
         (c #f)
         (d #f)
         (e #f)
         (f #f)
         (g #f)
         (h #f)
         (i #f)
         (j #f)

         (bar (lambda () #f))
         (foo (lambda () #f))
         (baz (lambda () (if 1000 (begin (foo) (bar)) #f))))
 (baz))