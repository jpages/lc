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

(define a 10)
(define b 11)
(define c -10)
(define d -11)
(define e 0)

(pp (odd? a))
(pp (odd? b))
(pp (odd? c))
(pp (odd? d))
(pp (odd? e))

(pp (even? a))
(pp (even? b))
(pp (even? c))
(pp (even? d))
(pp (even? e))

(pp (negative? a))
(pp (negative? b))
(pp (negative? c))
(pp (negative? d))
(pp (negative? e))

(pp (positive? a))
(pp (positive? b))
(pp (positive? c))
(pp (positive? d))
(pp (positive? e))

(pp (zero? a))
(pp (zero? b))
(pp (zero? c))
(pp (zero? d))
(pp (zero? e))

(pp (remainder  5  4))
(pp (remainder -5  4))
(pp (remainder  5 -4))
(pp (remainder -5 -4))

(pp (modulo  5  4))
(pp (modulo -5  4))
(pp (modulo  5 -4))
(pp (modulo -5 -4))

;#f
;#t
;#f
;#t
;#f
;#t
;#f
;#t
;#f
;#t
;#f
;#f
;#t
;#t
;#f
;#t
;#t
;#f
;#f
;#f
;#f
;#f
;#f
;#f
;#t
;1
;-1
;1
;-1
;1
;3
;-3
;-1
