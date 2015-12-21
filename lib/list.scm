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

(define (length l)
  (if (null? l)
      0
      (+ 1 (length (cdr l)))))

(define (list . l) l)

(define (append . lsts)
  (define (append-two lst1 lst2)
    (if (null? lst1)
      lst2
      (cons (car lst1) (append-two (cdr lst1) lst2))))
  (define (append-h lsts)
    (if (null? lsts)
      '()
      (append-two (car lsts) (append-h (cdr lsts)))))
  (append-h lsts))

(define (list? n)
  (cond ((null? n) #t)
        ((pair? n) (list? (cdr n)))
        (else #f)))

(define (list-ref lst i)
  (if (= i 0)
    (car lst)
    (list-ref (cdr lst) (- i 1))))

(define (reverse lst)
   (if (null? lst)
       '()
       (append (reverse (cdr lst))
               (list (car lst)))))

(define (for-each f lst)
   (if (not (null? lst))
     (begin (f (car lst))
            (for-each f (cdr lst)))))

(define (assq el lst)
  (cond ((null? lst) #f)
        ((eq? el (car (car lst))) (car lst))
        (else (assq el (cdr lst)))))

(define (assv el lst)
  (cond ((null? lst) #f)
        ((eqv? el (car (car lst))) (car lst))
        (else (assv el (cdr lst)))))

(define (assoc el lst)
  (cond ((null? lst) #f)
        ((equal? el (car (car lst))) (car lst))
        (else (assoc el (cdr lst)))))

(define (memq el lst)
  (cond ((null? lst) #f)
        ((eq? el (car lst)) lst)
        (else (memq el (cdr lst)))))

(define (memv el lst)
  (cond ((null? lst) #f)
        ((eqv? el (car lst)) lst)
        (else (memv el (cdr lst)))))

(define (member el lst)
  (cond ((null? lst) #f)
        ((equal? el (car lst)) lst)
        (else (member el (cdr lst)))))
