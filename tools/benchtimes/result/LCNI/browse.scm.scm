(define ###TIME_BEFORE### 0)
(define ###TIME_AFTER###  0)

(define (run-bench name count ok? run)
  (let loop ((i count) (result '(undefined)))
    (if (< 0 i)
      (loop (- i 1) (run))
      result)))

(define (run-benchmark name count ok? run-maker . args)
  (let ((run (apply run-maker args)))
    (set! ###TIME_BEFORE### ($$sys-clock-gettime-ns))
    (let ((result (run-bench name count ok? run)))
      (set! ###TIME_AFTER### ($$sys-clock-gettime-ns))
      (let ((ms (/ (- ###TIME_AFTER### ###TIME_BEFORE###) 1000000)))
        (print ms)
        (println " ms real time")
        (if (not (ok? result))
          (begin
            (display "*** wrong result ***")
            (newline)
            (display "*** got: ")
            (write result)
            (newline)))))))

; Gabriel benchmarks
(define boyer-iters        20)
(define browse-iters      600)
(define cpstak-iters     1000)
(define ctak-iters        100)
(define dderiv-iters  2000000)
(define deriv-iters   2000000)
(define destruc-iters     500)
(define diviter-iters 1000000)
(define divrec-iters  1000000)
(define puzzle-iters      100)
(define tak-iters        2000)
(define takl-iters        300)
(define trav1-iters       100)
(define trav2-iters        20)
(define triangl-iters      10)

; Kernighan and Van Wyk benchmarks
(define ack-iters          10)
(define array1-iters        1)
(define cat-iters           1)
(define string-iters       10)
(define sum1-iters         10)
(define sumloop-iters      10)
(define tail-iters          1)
(define wc-iters            1)

; C benchmarks
(define fft-iters        2000)
(define fib-iters           5)
(define fibfp-iters         2)
(define mbrot-iters       100)
(define nucleic-iters       5)
(define pnpoly-iters   100000)
(define sum-iters       20000)
(define sumfp-iters     20000)
(define tfib-iters         20)

; Other benchmarks
(define conform-iters      40)
(define dynamic-iters      20)
(define earley-iters      200)
(define fibc-iters        500)
(define graphs-iters      300)
(define lattice-iters       1)
(define matrix-iters      400)
(define maze-iters       4000)
(define mazefun-iters    1000)
(define nqueens-iters    2000)
(define paraffins-iters  1000)
(define peval-iters       200)
(define pi-iters            2)
(define primes-iters   100000)
(define ray-iters           5)
(define scheme-iters    20000)
(define simplex-iters  100000)
(define slatex-iters       20)
(define perm9-iters        10)
(define nboyer-iters      100)
(define sboyer-iters      100)
(define gcbench-iters       1)
(define compiler-iters    300)

;;; BROWSE -- Benchmark to create and browse through
;;; an AI-like data base of units.

(define (lookup key table)
  (let loop ((x table))
    (if (null? x)
      #f
      (let ((pair (car x)))
        (if (eq? (car pair) key)
          pair
          (loop (cdr x)))))))

(define properties '())

(define (get key1 key2)
  (let ((x (lookup key1 properties)))
    (if x
      (let ((y (lookup key2 (cdr x))))
        (if y
          (cdr y)
          #f))
      #f)))

(define (put key1 key2 val)
  (let ((x (lookup key1 properties)))
    (if x
      (let ((y (lookup key2 (cdr x))))
        (if y
          (set-cdr! y val)
          (set-cdr! x (cons (cons key2 val) (cdr x)))))
      (set! properties
        (cons (list key1 (cons key2 val)) properties)))))

(define *current-gensym* 0)

(define (generate-symbol)
  (set! *current-gensym* (+ *current-gensym* 1))
  (string->symbol (number->string *current-gensym*)))

(define (append-to-tail! x y)
  (if (null? x)
      y
      (do ((a x b)
           (b (cdr x) (cdr b)))
          ((null? b)
           (set-cdr! a y)
           x))))

(define (tree-copy x)
  (if (not (pair? x))
      x
      (cons (tree-copy (car x))
            (tree-copy (cdr x)))))

;;; n is # of symbols
;;; m is maximum amount of stuff on the plist
;;; npats is the number of basic patterns on the unit
;;; ipats is the instantiated copies of the patterns

(define *rand* 21)

(define (init n m npats ipats)
  (let ((ipats (tree-copy ipats)))
    (do ((p ipats (cdr p)))
        ((null? (cdr p)) (set-cdr! p ipats)))
    (do ((n n (- n 1))
         (i m (cond ((zero? i) m)
                    (else (- i 1))))
         (name (generate-symbol) (generate-symbol))
         (a '()))
        ((= n 0) a)
        (set! a (cons name a))
        (do ((i i (- i 1)))
            ((zero? i))
            (put name (generate-symbol) #f))
        (put name
             'pattern
             (do ((i npats (- i 1))
                  (ipats ipats (cdr ipats))
                  (a '()))
                 ((zero? i) a)
                 (set! a (cons (car ipats) a))))
        (do ((j (- m i) (- j 1)))
            ((zero? j))
            (put name (generate-symbol) #f)))))

(define (browse-random)
  (set! *rand* (remainder (* *rand* 17) 251))
  *rand*)

(define (randomize l)
  (do ((a '()))
      ((null? l) a)
      (let ((n (remainder (browse-random) (length l))))
        (cond ((zero? n)
               (set! a (cons (car l) a))
               (set! l (cdr l))
               l)
              (else
               (do ((n n (- n 1))
                    (x l (cdr x)))
                   ((= n 1)
                    (set! a (cons (cadr x) a))
                    (set-cdr! x (cddr x))
                    x)))))))

(define (my-match pat dat alist)
  (cond ((null? pat)
         (null? dat))
        ((null? dat) '())
        ((or (eq? (car pat) '?)
             (eq? (car pat)
                  (car dat)))
         (my-match (cdr pat) (cdr dat) alist))
        ((eq? (car pat) '*)
         (or (my-match (cdr pat) dat alist)
             (my-match (cdr pat) (cdr dat) alist)
             (my-match pat (cdr dat) alist)))
        (else (cond ((not (pair? (car pat)))
                     (cond ((eq? (string-ref (symbol->string (car pat)) 0)
                                 #\?)
                            (let ((val (assq (car pat) alist)))
                              (cond (val (my-match (cons (cdr val)
                                                      (cdr pat))
                                                dat alist))
                                    (else (my-match (cdr pat)
                                                 (cdr dat)
                                                 (cons (cons (car pat)
                                                             (car dat))
                                                       alist))))))
                           ((eq? (string-ref (symbol->string (car pat)) 0)
                                 #\*)
                            (let ((val (assq (car pat) alist)))
                              (cond (val (my-match (append (cdr val)
                                                        (cdr pat))
                                                dat alist))
                                    (else
                                     (do ((l '()
                                             (append-to-tail!
                                               l
                                               (cons (if (null? d)
                                                         '()
                                                         (car d))
                                                     '())))
                                          (e (cons '() dat) (cdr e))
                                          (d dat (if (null? d) '() (cdr d))))
                                         ((or (null? e)
                                              (my-match (cdr pat)
                                                       d
                                                       (cons
                                                        (cons (car pat) l)
                                                        alist)))
                                          (if (null? e) #f #t)))))))
                           (else #f))) ;;;; fix suggested by Manuel Serrano (cond did not have an else clause); this changes the run time quite a bit
                    (else (and
                           (pair? (car dat))
                           (my-match (car pat)
                                  (car dat) alist)
                           (my-match (cdr pat)
                                  (cdr dat) alist)))))))

(define database
   (randomize
    (init 100 10 4 '((a a a b b b b a a a a a b b a a a)
                     (a a b b b b a a
                                    (a a)(b b))
                     (a a a b (b a) b a b a)))))

(define (browse pats)
  (investigate
    database
    pats))

(define (investigate units pats)
  (do ((units units (cdr units)))
      ((null? units))
      (do ((pats pats (cdr pats)))
          ((null? pats))
          (do ((p (get (car units) 'pattern)
                  (cdr p)))
              ((null? p))
              (my-match (car pats) (car p) '())))))

(define (main . args)
  (run-benchmark
    "browse"
    browse-iters
    (lambda (result) #t)
    (lambda (pats) (lambda () (browse pats)))
    '((*a ?b *b ?b a *a a *b *a)
      (*a *b *b *a (*a) (*b))
      (? ? * (b a) * ? ?))))

(main)
