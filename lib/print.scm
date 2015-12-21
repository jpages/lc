;;---------------------------------------------------------------------------
;;
;;  Copyright (c) 2015, Baptiste Saleil. All rights reserved.
;;
;;  Redistribution and use in source and binary forms, with or without
;;  modification, are permitted provided that the following conditions are
;;  met:
;;   1. Redistributions of source code must retain the above copyright
;;      notice, this list of conditions and the following disclaimer.
;;   2. Redistributions in binary form must reproduce the above copyright
;;      notice, this list of conditions and the following disclaimer in the
;;      documentation and/or other materials provided with the distribution.
;;   3. The name of the author may not be used to endorse or promote
;;      products derived from this software without specific prior written
;;      permission.
;;
;;  THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
;;  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
;;  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
;;  NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
;;  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
;;  NOT LIMITED TO PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;;  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;;  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;;  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
;;  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;
;;---------------------------------------------------------------------------

(define (print-pos-nz n)
    (if (> n 0)
        (begin (print-pos-nz (quotient n 10))
               (write-char (integer->char (+ (modulo n 10) 48))))))

(define (print-pos n)
    (if (= n 0)
        (write-char #\0 (current-output-port))
        (print-pos-nz n)))

(define (print-nb n)
    (if (flonum? n)
       ($$print-flonum n) ;; TODO use special function ro print flonum
       (if (< n 0)
          (begin (print "-")
                 (print-pos (* -1 n)))
          (print-pos n))))

(define (print-char n)
  (write-char n (current-output-port)))

(define (print-bool n)
  (if (eq? n #t)
      (print "#t")
      (print "#f")))

(define (print-procedure n)
  (print "#<procedure>"))

(define (print-vector vector idx length)
  (if (< idx length)
    (begin (print (vector-ref vector idx))
           (print-vector vector (+ idx 1) length))))

(define (print-string str pos len)
  (if (< pos len)
     (begin (print (string-ref str pos))
            (print-string str (+ pos 1) len))))

(define (print-eof)
  (print "#!eof"))

(define (print-port p)
  (print "#<")
  (if (input-port? p)
    (print "input")
    (print "output"))
  (print "-port>"))

(define (print n)
    (cond ((null? n) #f)
          ((number? n) (print-nb n))
          ((char? n) (print-char n))
          ((procedure? n) (print-procedure n))
          ((pair? n) (begin (print (car n))
                            (print (cdr n))))
          ((vector? n) (print-vector n 0 (vector-length n)))
          ((string? n) (print-string n 0 (string-length n)))
          ((symbol? n)
             (let ((str (symbol->string n)))
               (print-string str 0 (string-length str))))
          ((eof-object? n)
             (print-eof))
          ((port? n) (print-port n))
          (else (print-bool n))))

(define (println n)
  (print n)
  (newline))





(define (pp-pair-h n)
  (cond ;; (e1)
        ((and (list? n) (= (length n) 1)) (pp-h (car n)))
        ;; (e1 . e2)
        ((not (pair? (cdr n)))
            (begin (pp-h (car n))
                   (print " . ")
                   (pp-h (cdr n))))
        ;; (e1 ...)
        (else (begin (pp-h (car n))
                     (print " ")
                     (pp-pair-h (cdr n))))))

(define (pp-pair n)
  (print "(")
  (pp-pair-h n)
  (print ")"))

(define (pp-char n)
  (print "#\\")
  (let ((v (char->integer n)))
    (if (> v 32)
       (print-char n)
       (cond ((eq? v  0) (print "nul"))
             ((<   v  7) (begin (print "x0") (print v)))
             ((eq? v  7) (print "alarm"))
             ((eq? v  8) (print "backspace"))
             ((eq? v  9) (print "tab"))
             ((eq? v 10) (print "newline"))
             ((eq? v 11) (print "vtab"))
             ((eq? v 12) (print "page"))
             ((eq? v 13) (print "return"))
             ((eq? v 14) (print "x0e"))
             ((eq? v 15) (print "x0f"))
             ((<   v 26) (begin (print "x") (print (- v 6))))
             ((eq? v 26) (print "x1a"))
             ((eq? v 27) (print "esc"))
             ((eq? v 28) (print "x1c"))
             ((eq? v 29) (print "x1d"))
             ((eq? v 30) (print "x1e"))
             ((eq? v 31) (print "x1f"))
             ((eq? v 32) (print "space"))
             (else (print "NYI"))))))

(define (pp-vector-h vector idx length)
  (cond ((= idx (- length 1))
            (pp-h (vector-ref vector idx)))
        ((< idx length)
            (begin (pp-h (vector-ref vector idx))
                   (print " ")
                   (pp-vector-h vector (+ idx 1) length)))))

(define (pp-vector vector)
  (print "#(")
  (pp-vector-h vector 0 (vector-length vector))
  (print ")"))

(define (pp-string-h string idx length)
  (if (< idx length)
     (begin (print (string-ref string idx))
            (pp-string-h string (+ idx 1) length))))

(define (pp-string string)
  (print "\"")
  (pp-string-h string 0 (string-length string))
  (print "\""))

(define (pp-h n)
  (cond ((null? n) (print "()")) ;; ()
        ((number? n) (print-nb n))
        ((char? n) (pp-char n))
        ((procedure? n) (print-procedure n))
        ((pair? n) (pp-pair n))
        ((vector? n) (pp-vector n))
        ((string? n) (pp-string n))
        ((symbol? n)
           (let ((str (symbol->string n)))
             (print-string str 0 (string-length str))))
        ((eof-object? n)
           (print-eof))
        ((port? n) (print-port n))
        (else (print-bool n))))

(define (pp n)
  (pp-h n)
  (newline))

(define write
  (lambda (n)
    (pp n)))

(define (newline)
  (print #\newline))
