
(pp 0)
(pp -0)
(pp -000)
(pp 12345)
(pp -12345)
(pp (* (+ 5 2) (- 5 1)))

(pp #t)
(pp #f)
(pp (not (not (not (<= 10 10)))))

(pp '())

(pp (lambda (x) (* x x)))

(pp (cons 10 20))
(pp (cons 10 (cons 20 '())))
(pp (cons 99 (cons #f (cons '() '()))))

(pp '(1 #f 3))
(pp '(1 () (#f 4) 5 #t))
(pp '(1 #f (3 4) ()))

;0
;0
;0
;12345
;-12345
;28
;#t
;#f
;#f
;()
;#<procedure>
;(10 . 20)
;(10 20)
;(99 #f ())
;(1 #f 3)
;(1 () (#f 4) 5 #t)
;(1 #f (3 4) ())