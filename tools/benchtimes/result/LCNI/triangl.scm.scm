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

(define BENCH_IN_FILE_PATH "/home/bapt/Bureau/these/lazy-comp/tools/benchtimes/bench/")
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

;;; TRIANGL -- Board game benchmark.
 
(define *board*
  (list->vector '(1 1 1 1 1 0 1 1 1 1 1 1 1 1 1 1)))

(define *sequence*
  (list->vector '(0 0 0 0 0 0 0 0 0 0 0 0 0 0)))

(define *a*
  (list->vector '(1 2 4 3 5 6 1 3 6 2 5 4 11 12
                  13 7 8 4 4 7 11 8 12 13 6 10
                  15 9 14 13 13 14 15 9 10
                  6 6)))

(define *b*
  (list->vector '(2 4 7 5 8 9 3 6 10 5 9 8
                  12 13 14 8 9 5 2 4 7 5 8
                  9 3 6 10 5 9 8 12 13 14
                  8 9 5 5)))

(define *c*
  (list->vector '(4 7 11 8 12 13 6 10 15 9 14 13
                  13 14 15 9 10 6 1 2 4 3 5 6 1
                  3 6 2 5 4 11 12 13 7 8 4 4)))

(define *answer* '())
 
(define (attempt i depth)
  (cond ((= depth 14)
         (set! *answer*
               (cons (cdr (vector->list *sequence*)) *answer*))
         #t)
        ((and (= 1 (vector-ref *board* (vector-ref *a* i)))
              (= 1 (vector-ref *board* (vector-ref *b* i)))
              (= 0 (vector-ref *board* (vector-ref *c* i))))
         (vector-set! *board* (vector-ref *a* i) 0)
         (vector-set! *board* (vector-ref *b* i) 0)
         (vector-set! *board* (vector-ref *c* i) 1)
         (vector-set! *sequence* depth i)
         (do ((j 0 (+ j 1))
              (depth (+ depth 1)))
             ((or (= j 36) (attempt j depth)) #f))
         (vector-set! *board* (vector-ref *a* i) 1)
         (vector-set! *board* (vector-ref *b* i) 1)
         (vector-set! *board* (vector-ref *c* i) 0) #f)
        (else #f)))
 
(define (test i depth)
  (set! *answer* '())
  (attempt i depth)
  (car *answer*))
 
(define (main . args)
  (run-benchmark
    "triangl"
    triangl-iters
    (lambda (result) (equal? result '(22 34 31 15 7 1 20 17 25 6 5 13 32)))
    (lambda (i depth) (lambda () (test i depth)))
    22
    1))

(main)
