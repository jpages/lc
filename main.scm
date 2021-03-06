#! gsi-script
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

(include "~~lib/_x86#.scm")
(include "config.scm")
(include "./extern/Sort.scm")

(define pp pretty-print)

(define-macro (string-bold str)
    `(string-append "\033[1m" ,str "\033[0m"))

(define-macro (run-add-to-ctime f)
  (let ((tmp (gensym)))
    `(if opt-ctime
         (let ((,tmp (##exec-stats ,f)))
           (set! user-compilation-time
                 (+ (- (+ (cdr (assoc 'user-time ,tmp))
                          (cdr (assoc 'sys-time  ,tmp)))
                       (+ (cdr (assoc 'gc-user-time ,tmp))
                          (cdr (assoc 'gc-sys-time ,tmp))))
                    user-compilation-time))
           (cdr (assoc 'result ,tmp)))
         (,f))))

;;--------------------------------------------------------------------------------
;; Compiler options

;; Contains all compiler options
;; An option contains (option-text help-text option-lambda)
(define compiler-options `(

  (--cc-max
    "Set the max size of the global entry points table"
    ,(lambda (args) (set! opt-cc-max (string->number (cadr args)))
                    (cdr args)))

  (--cr-max
    "Set the max size of the global return points table"
    ,(lambda (args) (set! opt-cr-max (string->number (cadr args)))
                    (cdr args)))

  (--const-vers-types
    "Select the type of the constants used for interprocedural versioning. (ex. --const-vers-types boo cha str)"
    ,(lambda (args)
       ;; TODO: types -> preds
       (define (end next-args types)
         (set! opt-cv-preds types)
         (cons (car args) next-args))
       (assert opt-const-vers "--const-vers-types needs --opt-const-vers")
       (let loop ((curr (cdr args))
                  (types '()))
         (if (null? curr)
             (end curr types)
             (let* ((next  (car curr))
                    (chars (string->list next)))
               (if (char=? (car chars) #\-)
                   (end curr types)
                   (loop
                     (cdr curr)
                     (cons (ctx-string->tpred next)
                           types))))))))

  (--ctime
    "Print compilation time after execution"
    ,(lambda (args) (set! opt-ctime #t) args))

  (--disable-entry-points
    "Disable the use of multiple entry points use only one generic entry point"
    ,(lambda (args) (set! opt-entry-points #f) args))

  ;(--disable-regalloc-vers
  ;  "Do not use register allocation information to specialize generated code"
  ;  ,(lambda (args) (set! opt-vers-regalloc #f) args))

  (--disable-return-points
      "Disable the use of multiple return points use only one generic return point"
      ,(lambda (args) (set! opt-return-points #f) args))

  (--enable-const-vers
    "Enable Interprocedural versioning based on constants"
    ,(lambda (args) (set! opt-const-vers #t) args))

  (--enable-cxoverflow-fallback
    "Enable automatic fallback to generic entry/return point when cxtable overflows, default throws an error"
    ,(lambda (args) (set! opt-overflow-fallback #t) args))

  (--help
    "Print help"
    ,(lambda (args)
      (newline)
      (println (string-bold "NAME"))
      (println "       lazy-comp - Scheme JIT compiler")
      (newline)
      (println (string-bold "SYNOPSIS"))
      (println "       ./lazy-comp [files] [options]")
      (newline)
      (println (string-bold "OPTIONS"))
      (for-each (lambda (option) (println "       " (car option))
                                 (println "       " "       " (cadr option))
                                 (newline))
                compiler-options)
      (newline)
      (exit 0)))

  (--dump-binary
    "Dump machine code block"
    ,(lambda (args) (set! opt-dump-bin #t)
                    args))

  (--dump-versions
    "Dump versions for each lco"
    ,(lambda (args) (set! opt-dump-versions #t)
                    args))

  (--export-locat-info
    "Export locat info so it can be used by locatview tool"
    ,(lambda (args) (set! opt-export-locat-info #t)
                    args))

  (--max-versions
    "Set a limit on the number of versions of lazy code objects"
    ,(lambda (args) (set! opt-max-versions (string->number (cadr args)))
                    (set! args (cdr args))
                    args))

  (--nolib
     "Do not include the standard library"
     ,(lambda (args) (set! opt-use-lib #f)
                     args))

  (--stats
    "Print stats about execution"
    ,(lambda (args) (assert (not opt-time) "--stats option can't be used with --time")
                    (set! opt-stats #t)
                    args))

  (--time
    "Print exec time information"
    ,(lambda (args) (assert (not opt-stats) "--time option can't be used with --stats")
                    (set! opt-time #t)
                    args))

  (--verbose-jit
    "Set jit as verbose"
    ,(lambda (args) (set! opt-verbose-jit #t) args))
))

(define (parse-args args)
    (cond ;;
          ((null? args) '())
          ;;
          ((not (eq? (string-ref (car args) 0) #\-))
            (cons (car args) (parse-args (cdr args))))
          ;;
          (else
            (let ((opt (assq (string->symbol (car args)) compiler-options)))
              (if opt
                (let ((fn (caddr opt)))
                 (set! args (fn args)))
                (error "Unknown argument " (car args))))
            (parse-args (cdr args)))))

;;-----------------------------------------------------------------------------

(define (lazy-exprs exprs succ)

  (let ((lazy-final
          (make-lazy-code
            #f
            (lambda (cgc ctx)

              ;; Update gambit heap ptr from LC heap ptr
              (x86-mov cgc (x86-mem (get-hp-addr)) alloc-ptr)

              ;; TODO regalloc: opt-time

              (let ((loc (ctx-get-loc ctx 0))) ;; Get loc of value in top of stack
                (cond ;; No return value
                      ((and (not loc)
                            (not (ctx-get-type ctx 0)))
                        (x86-mov cgc (x86-rax) (x86-imm-int 0)))
                      ((not loc)
                        (let* ((type (ctx-get-type ctx 0))
                               (cst  (ctx-type-cst type)))
                          (x86-mov cgc (x86-rax) (x86-imm-int (obj-encoding cst)))))
                      ((ctx-loc-is-register? loc)
                        (x86-mov cgc (x86-rax) (codegen-reg-to-x86reg loc)))
                      ((ctx-loc-is-fregister? loc)
                        (x86-mov cgc (x86-rax) (x86-imm-int 0)))
                      (else (error "NYI main"))))

              (if (> (ctx-ffs ctx) 0)
                  (x86-add cgc (x86-rsp) (x86-imm-int (* 8 (ctx-ffs ctx)))))

              ;; Restore registers values from pstack
              (ppop-regs-reverse cgc all-regs)
              (ppop-xmm cgc)
              (x86-ret cgc)))))


    (cond ((null? exprs) succ)
          ((and (= (length exprs) 1)
                (not succ))
             (gen-ast (car exprs) lazy-final))
          (else
            (let ((next (lazy-exprs (cdr exprs) succ)))
              (gen-ast (car exprs)
                       (make-lazy-code
                         #f
                         (lambda (cgc ctx)
                           (jump-to-version cgc
                                            next
                                            (ctx-pop ctx))))))))))

;;-----------------------------------------------------------------------------
;; Interactive mode (REPL)

(define (repl prog)

  (init-backend)

  (println "  _     ____       ")
  (println " | |   / ___|      ")
  (println " | |  | |          ")
  (println " | |__| |___       ")
  (println " |_____\\____| REPL")
  (println "")

  (let ((lco (lazy-exprs prog lazy-repl-call)))
    (gen-version-first lco (ctx-init)))

  (##machine-code-block-exec mcb))

(define lazy-repl-call
  (make-lazy-code
    #f
    (lambda (cgc ctx)
      ;; Generate call to repl handler defined in core.scm
      ;; This handler read from stdin, build lco chain,
      ;; and generate a version of the first lco of the chain.
      ;; The address of this version is returned in rax
      ;; then, jump to the version
      (x86-pcall cgc label-repl-handler)
      (x86-jmp cgc (x86-rax)))))

;;-----------------------------------------------------------------------------
;; Bash mode

(define (exec prog)

    (define (one-exec)
      (set! from-space init-from-space)
      (set! to-space   init-to-space)
      (##machine-code-block-exec mcb))

  (init-backend)

  (let ((lco (lazy-exprs prog #f)))
    (run-add-to-ctime
      (lambda ()
        (gen-version-first lco (ctx-init)))))

  (if opt-time
      (begin (##machine-code-block-exec mcb)
             (set! lco #f)
             (set! all-lazy-code #f)
             (set! asc-cc-stub #f)
             (set! asc-entry-load #f)
             (set! ctime-entries #f)
             (set! stub-freelist #f)
             (let loop ((i 0))
               (if (< i (/ ustack-len 8))
                   (begin (vector-set! ustack i 0)
                          (loop (+ i 1)))))
             (let loop ((i 0))
               (if (< i globals-len)
                   (begin (vector-set! globals-space i 0)
                          (loop (+ i 1)))))
             (##gc)
             (time (##machine-code-block-exec mcb)
                   (current-output-port)))
       (##machine-code-block-exec mcb)))

;;-----------------------------------------------------------------------------
;; Main

;; Run command
(define (run path . args)
  (let* ((port
          (open-process (list path: path
                              arguments: args
                              ;;stderr-redirection: #t
                              )))
         (output
          (read-line port #f))
         (status
          (process-status port)))
    (close-port port)
    (cons status output)))

(define (copy-with-declare src dst)
  (run "./copy-with-declare.sh" src dst (if opt-use-lib "lib" "nolib")))

(define (main . args)

  ;; Set options and get files from cl args
  (define files (parse-args args))

  (init-frontend)

  (cond ;; If no files specified then start REPL
        ((null? files)
          (copy-with-declare "" "./tmp")
          (let ((content (c#expand-program "./tmp" #f locat-table)))
            (repl (expand-tl content))))
        ;; Can only exec 1 file
        ((= (length files) 1)
          (copy-with-declare (car files) "./tmp")
        (let ((content (c#expand-program "./tmp" #f locat-table)));(read-all (open-input-file (car files)))))
              (let ((exp-content (expand-tl content)))
                (analyses-find-global-types! exp-content)
                (analyses-a-conversion! exp-content)
                (compute-liveness exp-content)
                ;(pp content))))
                ;(exec content))))
                (exec exp-content))))
        (else (error "NYI")))

  (rt-print-opts)
  (print-opts)
  0)

;; TODO
(define (get-versions-info lazy-codes)

  (define (get-versions-info-h lcs min max)
    (if (null? lcs)
       (cons min max)
       (let* ((lc (car lcs))
              (nb (lazy-code-nb-real-versions lc)))
         (cond ((< nb min)
                   (get-versions-info-h (cdr lcs) nb max))
               ((> nb max)
                   (get-versions-info-h (cdr lcs) min nb))
               (else
                   (get-versions-info-h (cdr lcs) min max))))))

  (if (null? lazy-codes)
     (cons 0 0)
     (let* ((lc (car lazy-codes))
            (nb (lazy-code-nb-real-versions lc)))
       (get-versions-info-h (cdr lazy-codes) nb nb))))

;; TODO
(define (get-versions-info-full lazy-codes)

  (define table (make-table))

  (define (get-versions-info-full-h lcs)
    (if (null? lcs)
       #t
       (let* ((lco (car lcs))
              (nb-versions (lazy-code-nb-real-versions lco))
              (r  (table-ref table nb-versions (cons 0 '()))))
        (table-set!
          table nb-versions
          (cons (+ (car r) 1)
                (cons (lazy-code-flags lco) (cdr r))))
        (get-versions-info-full-h (cdr lcs)))))

  (get-versions-info-full-h lazy-codes)
  (table->list table))

;;-----------------------------------------------------------------------------

(define (rt-print-opts)
  (if opt-stats
    (begin (println "Closures: " (get-slot 'closures))
           (println "Executed tests: " (get-slot 'tests)))))

(define (print-opts)
  (if opt-ctime
      (print-ctime))
  (if opt-stats
      (print-stats))
  (if opt-export-locat-info
      (export-locat-info))
  (if opt-dump-bin
      (print-mcb))
  (if opt-dump-versions
      (print-versions)))

(define (print-ctime)
  (println
    "Compilation time (user time):"
    user-compilation-time))

(define (print-mcb)
  (let ((f (open-output-file "dump.bin")))
      (define (print-mcb-h pos lim)
        (if (= pos lim)
            (newline)
            (let ((byte (get-u8 pos)))
              (write-char (integer->char byte) f)
              (print-mcb-h (+ pos 1) lim))))
      (print-mcb-h code-addr code-alloc)
      (println ">> Dump written in dump.bin")
      (close-output-port f)))

(define (print-versions)
  (let loop ((lcos all-lazy-code) (i 0))
    (if (not (null? lcos))
        (let ((lco (car lcos)))
          (if (> (lazy-code-nb-real-versions lco) 0)
              (let* ((versions (lazy-code-versions lco))
                     (real-versions (keep cddr (table->list (lazy-code-versions lco)))))
                (print "#" (##object->serial-number lco) "# ")
                (for-each (lambda (flag) (print flag ",")) (lazy-code-flags lco))
                (newline)
                (let loop2 ((rv real-versions))
                  (if (not (null? rv))
                      (let* ((version (car rv))
                             (ctx (car version))
                             (stack
                                 (if (ctx? ctx)
                                     (ctx-stack ctx)
                                     ctx)))
                        (if (null? stack)
                            (print "EMPTY")
                            (for-each
                              (lambda (type)
                                (if (not (ctx-type-ret? type))
                                    (begin
                                      (print (ctx-type-symbol type))
                                      (if (ctx-type-cst? type)
                                          (print "(" (ctx-type-cst type) ") ")
                                          (print " ")))))
                              stack))
                        (newline)
                        (loop2 (cdr rv)))))))
          (loop (cdr lcos) (+ i 1))))
    all-lazy-code))

(define (print-stats)
  ;; Print stats report
  (let ((code-bytes (- code-alloc code-addr))
        (stub-bytes (- (+ code-addr code-len) stub-alloc)))
    ;; Code size
    (println "Code size (bytes): " code-bytes)
    ;; Stub size
    (println "Stub size (bytes): " stub-bytes)
    ;; Code + Stub size
    (println "Total size (bytes): " (+ code-bytes stub-bytes))
    ;; Global cc-table size
    (println "Global table size: " (table-length global-cc-table))
    ;; Number of cc tables
    (println "Number of cctables: " (cctables-total))
    ;; Number of cr tables
    (println "Number of crtables: " (crtables-total))
    ;; CC table space (kb)
    (print "CC table space (kbytes): ")
    (pp-flonum (/ (* (table-length global-cc-table) 8 (cctables-total)) 1000) 5)
    ;; CR table space (kb)
    (print "CR table space (kbytes): ")
    (pp-flonum (/ (* 16 8 (crtables-total)) 1000) 5)
    ;; Min/Max versions number of stubs
    (let ((versions-info (get-versions-info all-lazy-code)))
      (println "Min versions number: " (car versions-info))
      (println "Max versions number: " (cdr versions-info)))
    ;; Number of stubs, number of return stubs, and number of entry stubs for each number of versions
    (println "-------------------------")
    (println "Number of stubs for each number of version")
    (println "#versions;#stubs;#ret;#entry;#cont;#cond")
    (let ((versions-info-full (get-versions-info-full all-lazy-code)))
      (for-each (lambda (n)
                  (println (car n) ";"
                           (cadr n) ";"
                           (count (cddr n) (lambda (n) (member 'ret n))) ";"
                           (count (cddr n) (lambda (n) (member 'entry n))) ";"
                           (count (cddr n) (lambda (n) (member 'cont n))) ";"
                           (count (cddr n) (lambda (n) (member 'cond n)))))
                (sort versions-info-full (lambda (n m) (< (car n) (car m)))))
      (println "-------------------------"))))

;;-----------------------------------------------------------------------------
;; Locat infos

(define (export-locat-info)

  (define restable '())

  (define (restable-add locat lco)
    (set! restable
          (cons (cons locat lco)
                restable)))

  ;;---------------------------------------------------------------------------
  ;; Locat formatter to output data so that locat tool can use it (tools/locatview)

  (define locat-formatted-str "")
  (define asc-linecol-n (make-table)) ;; associate a integer n to a "line.col" string
  (define (next-linecol-n lin col)
    (let* ((str (string-append (number->string lin) "." (number->string col)))
           (r (table-ref asc-linecol-n str 0)))
     (table-set! asc-linecol-n str (+ r 1))
     r))

  (define (print-array-item i)
    (print "\"" i "\"" ","))

  (define (format-code-header)
    (print "var code = "))
  (define (format-code-footer)
    (println ";"))

  (define (format-locat-header)
    (println "var locat_info = {"))
  (define (format-locat-footer)
    (println "}"))

  (define (format-n-versions n)
    (print-array-item "~#versions")
    (print-array-item n))

  (define (format-serial s)
    (print-array-item "~#serial")
    (print-array-item s))

  (define (format-ctxs versions)
    (define (format-ctx ctx n)
      ;; Ctx id
      (print-array-item (string-append "~ctx" (number->string n)))
      ;; Stack
      (print-array-item
        (string-append
          "Stack -> "
          (with-output-to-string '()
            (lambda ()
              (for-each
                (lambda (stype)
                  (if (ctx-type-cst? stype)
                      (print (ctx-type-symbol stype) "(" (ctx-type-cst stype) ") ")
                      (print (ctx-type-symbol stype) " ")))
                (ctx-stack ctx))))))
      ;; Slot loc
      (print-array-item
        (string-append
          "Reg-alloc -> "
          (with-output-to-string '()
            (lambda () (display (ctx-slot-loc ctx)))))))

    (let loop ((versions (table->list versions))
               (n 1))
      (if (not (null? versions))
          (let* ((version-entry (car versions))
                 (real-version? (cddr version-entry)))
            (if real-version?
                (begin
                  ;(print-array-item (string-append "ctx" (number->string n)))
                  (format-ctx (car version-entry) n)
                  (set! n (+ n 1))))
            (loop (cdr versions) n)))))

  (define (format-entry lin col lco)
    (let ((n (next-linecol-n lin col)))
      (print "  \"" lin "." col "." n "\"" ": [")
      (format-n-versions (lazy-code-nb-real-versions lco))
      (format-serial (##object->serial-number lco))
      (format-ctxs (lazy-code-versions lco))
      (println "],")))

  ;; For each lco
  (for-each
    (lambda (x)
      (let ((ast (lazy-code-ast x)))
        ;; If an ast is associated to the lco and there is 1 or more versions
        (if (and ast (> (lazy-code-nb-real-versions x) 0))
            ;; Then, if a locat object is associated to this ast, add versions number
            (let ((r (table-ref locat-table ast #f)))
              (if r
                  (restable-add r x))))))
    all-lazy-code)

  ;; Format locat info for jsview (see tools/)
  ;; Add locat_info var to string
  (let ((file (open-output-file '(path: "./tools/locatview/locat.js" char-encoding: UTF-8)))
        (output
          (with-output-to-string '()
            (lambda ()
              ;; Write locat info
              (format-locat-header)
              (for-each
                (lambda (x)
                  (let* ((locat (car x))
                         (file (vector-ref locat 0))
                         (lin (+ 1 (bitwise-and (vector-ref locat 1) (- (expt 2 16) 1))))
                         (col (+ 1 (arithmetic-shift (vector-ref locat 1) -16))))
                    (format-entry lin col (cdr x))))
                restable)
              (format-locat-footer)
              ;; Write code
              (let* ((port (open-input-file '(path: "./tmp" char-encoding: UTF-8)))
                     (code (read-line port #f)))
                (close-input-port port)
                (format-code-header)
                (write code)
                (format-code-footer))))))
    ;;
    (display output file)
    (force-output file)
    (close-output-port file)))
