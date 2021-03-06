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

;; This is the most simple strategy
;; Generate lazy-code objects with given contexts until hard limit is reached
;; Then fallback to a generic version

(define opt-max-versions #f)
(define lazy-code-entry? #f)

(define lco_versions (make-table test: eq?))
(define lco_generic  (make-table test: eq?))

;;------------------------------------------------------------------------------
;; PUBLIC

(define (lazy-code-versions lco)
  (let ((versions (table-ref lco_versions lco #f)))
    (or versions
        (let ((versions (make-table)))
          (table-set! lco_versions lco versions)
          versions))))

(define (lazy-code-nb-versions lazy-code)
  (table-length (lazy-code-versions lazy-code)))

(define (lazy-code-nb-real-versions lazy-code)
  (count (table->list (lazy-code-versions lazy-code)) cddr))

;;------------------------------------------------------------------------------
;; PRIVATE

(define (lazy-code-generic lco)
  (table-ref lco_generic lco #f))

(define (lazy-code-generic-set! lco ctx version)
  (table-set! lco_generic lco (cons ctx version)))

(define (get-version lazy-code ctx)
  (let* ((key (if (lazy-code-entry? lazy-code)
                  ctx;(ctx-stack ctx)
                  ctx))
         (versions (lazy-code-versions lazy-code))
         (version  (table-ref versions key #f)))
    (and version (car version))))

(define (put-version lazy-code ctx version real-version?)
  (let ((key (if (lazy-code-entry? lazy-code)
                 ctx;(ctx-stack ctx)
                 ctx))
        (versions (lazy-code-versions lazy-code)))
    (table-set! versions key (cons version real-version?))))

(define (limit-reached? lco)
  (and opt-max-versions
       (let ((nb-versions (lazy-code-nb-real-versions lco)))
         (>= nb-versions opt-max-versions))))

(define (strat-get-version lco ctx)

  ;; CASE 1: a version exists for this ctx, use it
  (define (case-use-version version)
    (list version ctx (lambda (r) r)))

  ;; CASE 2: no version for this ctx, and limit is not reached
  ;; then generate a new version
  (define (case-gen-version)
    (list #f ctx (lambda (label) (put-version lco ctx label #t))))

  ;; CASE 3: no version for this ctx, limit reached, generic exists
  ;; then use the generic version
  (define (case-use-generic generic)
    (let ((callback (lambda (label-merge) (put-version lco ctx label-merge #f))))
      (list (cdr generic) (car generic) callback)))

  ;; CASE 4: no version for this ctx, limit reached, generic does not exist
  ;; then generate the generic version
  (define (case-gen-generic)
    (let* ((gctx (ctx-generic ctx))
           (callback (lambda (label-merge label-version)
                       (put-version lco ctx label-merge #f)
                       (lazy-code-generic-set! lco gctx label-version))))
      (list #f gctx callback)))

  (let ((version (get-version lco ctx)))
    (if version
        (case-use-version version) ;; CASE 1
        (if (not (limit-reached? lco))
            (case-gen-version)     ;; CASE 2
            (let ((generic (lazy-code-generic lco)))
              (if generic
                  (case-use-generic generic) ;; CASE 3
                  (case-gen-generic)))))))   ;; CASE 4
