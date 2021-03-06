;;; FIBFP -- Computes fib(35) using floating point

(define (fibfp n)
  (if (FLOAT< n 2.)
    n
    (FLOAT+ (fibfp (FLOAT- n 1.))
            (fibfp (FLOAT- n 2.)))))

(let ((result (fibfp 35.)))
  (println (= result 9227465.)))

;#t
