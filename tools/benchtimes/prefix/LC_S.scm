;(define ###TIME_BEFORE### 0)
;(define ###TIME_AFTER###  0)
;
;(define (run-bench name count ok? run)
;  (let loop ((i count) (result '(undefined)))
;    (if (< 0 i)
;      (loop (- i 1) (run))
;      result)))
;

(define (run-benchmark name count ok? run-maker . args)
  (let ((run (apply run-maker args)))
    (run)))

;(define (run-benchmark name count ok? run-maker . args)
;  (let ((run (apply run-maker args)))
;    (set! ###TIME_BEFORE### (##gettime-ns))
;    (let ((result (run-bench name count ok? run)))
;      (set! ###TIME_AFTER### (##gettime-ns))
;      (let ((ms (/ (- ###TIME_AFTER### ###TIME_BEFORE###) 1000000)))
;        (print ms)
;        (println " ms real time")
;        (if (not (ok? result))
;          (begin
;            (display "*** wrong result ***")
;            (newline)
;            (display "*** got: ")
;            (write result)
;            (newline)))))))
