
;;-----------------------------------------------------------------------------
;; x86 Codegen utils
(define (x86-codegen-void cgc)
  (x86-push cgc (x86-imm-int ENCODING_VOID)))

;;-----------------------------------------------------------------------------
;; Define
(define (x86-codegen-define-id cgc)
  (x86-mov cgc (x86-rax) (x86-imm-int ENCODING_VOID))
  (x86-mov cgc (x86-mem (* 8 (length globals)) (x86-r10)) (x86-rax)))

(define (x86-codegen-define-bind cgc pos)
  (x86-pop cgc (x86-rax))
  (x86-mov cgc (x86-mem (* 8 pos) (x86-r10)) (x86-rax))
  (x86-push cgc (x86-imm-int ENCODING_VOID)))

;;-----------------------------------------------------------------------------
;; Special forms
;;-----------------------------------------------------------------------------
;; Begin
(define (x86-codegen-begin-out cgc nb-expr)
  (x86-pop  cgc (x86-rax)) ;; Pop result of last expr
  (x86-add  cgc (x86-rsp) (x86-imm-int (* 8 nb-expr))) ;; Clean stack
  (x86-push cgc (x86-rax))) ;; Push result

;;-----------------------------------------------------------------------------
;; Values
;;-----------------------------------------------------------------------------

;;-----------------------------------------------------------------------------
;; Literal
(define (x86-codegen-literal cgc lit)
  (if (and (number? lit)
           (or (>= lit (expt 2 29))   ;; 2^(32-1-2) (32bits-sign-tags)
               (<  lit (expt 2 28))))
      (begin (x86-mov  cgc (x86-rax) (x86-imm-int (obj-encoding lit)))
             (x86-push cgc (x86-rax)))
             (x86-push cgc (x86-imm-int (obj-encoding lit)))))

;;-----------------------------------------------------------------------------
;; Flonum
(define (x86-codegen-flonum cgc immediate)
  (let ((header-word (mem-header 2 STAG_FLONUM)))
    (gen-allocation cgc #f STAG_FLONUM 2) ;; TODO #f
    ;; Write header
    (x86-mov cgc (x86-rax) (x86-imm-int header-word))
    (x86-mov cgc (x86-mem 0 alloc-ptr) (x86-rax))
    ;; Write number
    (x86-mov cgc (x86-rax) (x86-imm-int immediate))
    (x86-mov cgc (x86-mem 8 alloc-ptr) (x86-rax))
    ;; Push flonum
    (x86-lea cgc (x86-rax) (x86-mem TAG_MEMOBJ alloc-ptr))
    (x86-push cgc (x86-rax))))

;;-----------------------------------------------------------------------------
;; Symbol
(define (x86-codegen-symbol cgc sym)
  (let ((qword (get-symbol-qword sym)))
    (x86-mov cgc (x86-rax) (x86-imm-int qword))
    (x86-push cgc (x86-rax))))

;;-----------------------------------------------------------------------------
;; String
(define (x86-codegen-string cgc str)
  (let* ((len (string-length str))
         (size (arithmetic-shift (bitwise-and (+ len 8) (bitwise-not 7)) -3))
         (header-word (mem-header (+ size 2) STAG_STRING)))

    (gen-allocation cgc #f STAG_STRING (+ size 2))
    ;; Write header
    (x86-mov cgc (x86-rax) (x86-imm-int header-word))
    (x86-mov cgc (x86-mem 0 alloc-ptr) (x86-rax))
    ;; Write length
    (x86-mov cgc (x86-rax) (x86-imm-int (obj-encoding (string-length str))))
    (x86-mov cgc (x86-mem 8 alloc-ptr) (x86-rax))
    ;; Write chars
    (write-chars cgc str 0 16)
    ;; Push string
    (x86-lea cgc (x86-rax) (x86-mem TAG_MEMOBJ alloc-ptr))
    (x86-push cgc (x86-rax))))

;; Write chars of the literal string 'str':
;; Write str[pos] char to [alloc-ptr+offset], and write next chars
(define (write-chars cgc str pos offset)
  (if (< pos (string-length str))
      (let* ((int (char->integer (string-ref str pos)))
             (encoded (if (> int 127)
                          (* -1 (- 256 int))
                          int)))
        (x86-mov cgc (x86-al) (x86-imm-int encoded))
        (x86-mov cgc (x86-mem offset alloc-ptr) (x86-al))
        (write-chars cgc str (+ pos 1) (+ offset 1)))))

;;-----------------------------------------------------------------------------
;; Pair
(define (x86-codegen-pair cgc)
  (let ((header-word (mem-header 3 STAG_PAIR)))
    ;; Alloc
    (gen-allocation cgc #f STAG_PAIR 3)
    ;; Write object header
    (x86-mov cgc (x86-rax) (x86-imm-int header-word))
    (x86-mov cgc (x86-mem 0 alloc-ptr) (x86-rax))
    (x86-pop cgc (x86-rbx)) ;; pop CDR
    (x86-pop cgc (x86-rax)) ;; pop CAR
    ;; Write pair
    (x86-mov cgc (x86-mem 8 alloc-ptr)  (x86-rax))
    (x86-mov cgc (x86-mem 16 alloc-ptr) (x86-rbx))
    ;; Tag,Push closure and update alloc-ptr
    (x86-mov cgc (x86-rax) alloc-ptr)
    (x86-add cgc (x86-rax) (x86-imm-int TAG_MEMOBJ))
    (x86-push cgc (x86-rax))))

;;-----------------------------------------------------------------------------
;; Primitives
;;-----------------------------------------------------------------------------

;;-----------------------------------------------------------------------------
;; not
(define (x86-codegen-not cgc)
  (let ((label-done
          (asm-make-label cgc (new-sym 'done))))
    (x86-mov cgc (x86-rax) (x86-imm-int (obj-encoding #f)))
    (x86-cmp cgc (x86-mem 0 (x86-rsp)) (x86-rax))
    (x86-mov cgc (x86-rax) (x86-imm-int (obj-encoding #t)))
    (x86-je  cgc label-done)
    (x86-mov cgc (x86-rax) (x86-imm-int (obj-encoding #f)))
    (x86-label cgc label-done)
    (x86-mov cgc (x86-mem 0 (x86-rsp)) (x86-rax))))

;;-----------------------------------------------------------------------------
;; eq?
(define (x86-codegen-eq? cgc)
  (let ((label-done (asm-make-label cgc (new-sym 'done))))
    (x86-pop cgc (x86-rax))
    (x86-cmp cgc (x86-mem 0 (x86-rsp)) (x86-rax))
    (x86-mov cgc (x86-rax) (x86-imm-int (obj-encoding #t)))
    (x86-je  cgc label-done)
    (x86-mov cgc (x86-rax) (x86-imm-int (obj-encoding #f)))
    (x86-label cgc label-done)
    (x86-mov cgc (x86-mem 0 (x86-rsp)) (x86-rax))))

;;-----------------------------------------------------------------------------
;; car/cdr
(define (x86-codegen-car/cdr cgc op)
  (let ((offset
          (if (eq? op 'car)
              (-  8 TAG_MEMOBJ)
              (- 16 TAG_MEMOBJ))))
    (x86-pop cgc (x86-rax))
    (x86-mov cgc (x86-rax) (x86-mem offset (x86-rax)))
    (x86-push cgc (x86-rax))))

;;-----------------------------------------------------------------------------
;; set-car!/set-cdr!
(define (x86-codegen-scar/scdr cgc op)
  (let ((offset
          (if (eq? op 'set-car!)
              (-  8 TAG_MEMOBJ)
              (- 16 TAG_MEMOBJ))))
    (x86-pop cgc (x86-rax)) ;; val
    (x86-pop cgc (x86-rbx)) ;; pair
    (x86-mov cgc (x86-mem offset (x86-rbx)) (x86-rax))
    (x86-push cgc (x86-imm-int ENCODING_VOID))))

;;-----------------------------------------------------------------------------
;; current-input/output-port
(define (x86-codegen-current-io-port cgc op)
  (let ((block-offset (if (eq? op 'current-output-port) 8 24)))
    (x86-mov cgc (x86-rax) (x86-imm-int (+ TAG_MEMOBJ block-offset block-addr)))
    (x86-push cgc (x86-rax))))

;;-----------------------------------------------------------------------------
;; close-input/output-port
(define (x86-codegen-close-io-port cgc)
  (gen-syscall-close cgc)
  (x86-push cgc (x86-imm-int ENCODING_VOID)))

;;-----------------------------------------------------------------------------
;; open-input/output-port
(define (x86-codegen-open-io-file cgc op)
  (let* ((direction   (if (eq? op 'open-output-file) 'out 'in))
         (stag        (if (eq? direction 'in) STAG_IPORT STAG_OPORT))
         (header-word (mem-header 2 stag)))
    ;; Gen 'open' syscall, file descriptor in rax
    (gen-syscall-open cgc direction)
    (x86-mov cgc (x86-rbx) (x86-rax))
    ;; Allocate port object
    (gen-allocation cgc #f stag 2)
    ;; Mov header
    (x86-mov cgc (x86-rax) (x86-imm-int header-word))
    (x86-mov cgc (x86-mem 0 alloc-ptr) (x86-rax))
    ;; Mov descriptor
    (x86-mov cgc (x86-mem 8 alloc-ptr) (x86-rbx))
    ;; Tag & push
    (x86-lea cgc (x86-rax) (x86-mem TAG_MEMOBJ alloc-ptr))
    (x86-mov cgc (x86-mem 0 (x86-rsp)) (x86-rax))))

;;-----------------------------------------------------------------------------
;; eof-object?
(define (x86-codegen-eof? cgc)
  (let ((label-end (asm-make-label #f (new-sym 'label-end))))
    (x86-pop cgc (x86-rax))
    (x86-cmp cgc (x86-rax) (x86-imm-int ENCODING_EOF))
    (x86-mov cgc (x86-rax) (x86-imm-int (obj-encoding #f)))
    (x86-jne cgc label-end)
    (x86-mov cgc (x86-rax) (x86-imm-int (obj-encoding #t)))
    (x86-label cgc label-end)
    (x86-push cgc (x86-rax))))

;;-----------------------------------------------------------------------------
;; read-char
(define (x86-codegen-read-char cgc)
  ;; Gen 'read' syscall (read 1 byte), encoded value (char or eof) in rax
  (gen-syscall-read-char cgc)
  ;; Push encoded result
  (x86-mov cgc (x86-mem 0 (x86-rsp)) (x86-rax)))

;;-----------------------------------------------------------------------------
;; write-char
(define (x86-codegen-write-char cgc)
  ;; Gen 'read' syscall, encoded value (char or eof) in rax
  (gen-syscall-write-char cgc)
  (x86-add cgc (x86-rsp) (x86-imm-int 16)) ;; NOTE: clean stack in gen-syscall-write-char?
  ;; Push encoded result
  (x86-push cgc (x86-imm-int ENCODING_VOID)))

;;-----------------------------------------------------------------------------
;; char->integer/integer->char
(define (x86-codegen-ch<->int cgc op)
  (if (eq? op 'char->integer)
      (x86-xor cgc (x86-mem 0 (x86-rsp)) (x86-imm-int TAG_SPECIAL) 8)
      (x86-or  cgc (x86-mem 0 (x86-rsp)) (x86-imm-int TAG_SPECIAL) 8)))

;;-----------------------------------------------------------------------------
;; make-string
(define (x86-codegen-make-string cgc init-value?)
  (let* ((header-word (mem-header 3 STAG_STRING)))
    ;; Pop encoded length
    (if init-value?
        (x86-mov cgc (x86-rax) (x86-mem 8 (x86-rsp)))
        (x86-pop cgc (x86-rax)))
    (x86-mov cgc (x86-rbx) (x86-rax))
    ;; Nb chars to byte size
    (x86-shr cgc (x86-rax) (x86-imm-int 2))
    (x86-and cgc (x86-rax) (x86-imm-int (bitwise-not 7)))
    (x86-shr cgc (x86-rax) (x86-imm-int 1))
    (x86-mov cgc (x86-rsi) (x86-rax))
    ;; Alloc
    (gen-allocation cgc #f STAG_STRING 3 #t)
    ;; Fill string
    (x86-push cgc (x86-rbx))
    ;;
    (x86-mov cgc (x86-rax) alloc-ptr)
    (let ((label-loop (asm-make-label cgc (new-sym 'fill-string-loop)))
          (label-end  (asm-make-label cgc (new-sym 'fill-string-end))))

      (if init-value?
          (begin (x86-mov cgc (x86-rdx) (x86-mem 8 (x86-rsp)))
                 (x86-sar cgc (x86-rdx) (x86-imm-int 2))))
      ;; LOOP:
      ;;   if (rbx == 0) jump END
      (x86-label cgc label-loop)
      (x86-cmp cgc (x86-rbx) (x86-imm-int 0))
      (x86-jle  cgc label-end)
        ;; Write init value
        (if init-value?
            (begin (x86-mov cgc (x86-mem 16 (x86-rax)) (x86-dl)) ;; Write char
                   (x86-add cgc (x86-rax) (x86-imm-int 1)) ;; Update offset
                   (x86-sub cgc (x86-rbx) (x86-imm-int 4))) ;; Remove 1 (=1*4=4) to encoded number (remaining els)
            (begin (x86-mov cgc (x86-mem 16 (x86-rax)) (x86-imm-int 0) 64) ;; Write 0 in 8 chars
                   (x86-add cgc (x86-rax) (x86-imm-int 8)) ;; Update offset
                   (x86-sub cgc (x86-rbx) (x86-imm-int 32)))) ;; Remove 8 (=8*4=32) to encoded number (remaining els)
        ;; Loop
        (x86-jmp cgc label-loop)
      ;; END:
      (x86-label cgc label-end)
      (x86-pop cgc (x86-rbx)))
    ;; Clean stack
    (if init-value?
        (x86-add cgc (x86-rsp) (x86-imm-int 16)))
    ;; Write encoded length
    (x86-mov cgc (x86-mem 8 alloc-ptr) (x86-rbx))
    ;; Write header
    (x86-shl cgc (x86-rsi) (x86-imm-int 6))
    (x86-add cgc (x86-rsi) (x86-imm-int header-word))
    (x86-mov cgc (x86-mem 0 alloc-ptr) (x86-rsi))
    ;; Push string
    (x86-lea cgc (x86-rax) (x86-mem TAG_MEMOBJ alloc-ptr))
    (x86-push cgc (x86-rax))))

;;-----------------------------------------------------------------------------
;; make-vector
(define (x86-codegen-make-vector cgc init-value?)
  (let* ((header-word (mem-header 2 STAG_VECTOR)))
    ;; Pop encoded length
    (if init-value?
        (x86-mov cgc (x86-rax) (x86-mem 8 (x86-rsp)))
        (x86-pop cgc (x86-rax)))
    (x86-mov cgc (x86-rbx) (x86-rax))
    ;; Alloc
    (gen-allocation cgc #f STAG_VECTOR 2 #t)
    ;; Get vector position in R15
    (x86-mov cgc (x86-r15) alloc-ptr)
    ;; Fill vector
    (x86-push cgc (x86-rbx))
    ;; Init value in RAX (0)
    (if init-value?
        (x86-mov cgc (x86-rax) (x86-mem 8 (x86-rsp)))
        (x86-mov cgc (x86-rax) (x86-imm-int 0)))
    ;;
    (let ((label-loop (asm-make-label #f (new-sym 'fill-vector-loop)))
          (label-end  (asm-make-label #f (new-sym 'fill-vector-end))))

      ;; LOOP:
      ;;    if (rbx == 0) jump END
      (x86-label cgc label-loop)
      (x86-cmp cgc (x86-rbx) (x86-imm-int 0))
      (x86-je  cgc label-end)
        ;; Init vector slot
        (x86-mov cgc (x86-mem 16 (x86-r15)) (x86-rax))
        ;; Update offset and remaining elements nb
        (x86-add cgc (x86-r15) (x86-imm-int 8))
        (x86-sub cgc (x86-rbx) (x86-imm-int 4))
        ;; loop
        (x86-jmp cgc label-loop)
      ;; END:
      (x86-label cgc label-end)
      (x86-pop cgc (x86-rbx)))
    ;; Clean stack
    (if init-value?
        (x86-add cgc (x86-rsp) (x86-imm-int 16)))
    ;; Write encoded length
    (x86-mov cgc (x86-mem 8 alloc-ptr) (x86-rbx))
    ;; Write header
    (x86-shl cgc (x86-rbx) (x86-imm-int 6))
    (x86-add cgc (x86-rbx) (x86-imm-int header-word))
    (x86-mov cgc (x86-mem 0 alloc-ptr) (x86-rbx))
    ;; Push vector
    (x86-lea cgc (x86-rax) (x86-mem TAG_MEMOBJ alloc-ptr))
    (x86-push cgc (x86-rax))))

;;-----------------------------------------------------------------------------
;; string->symbol
(define (x86-codegen-str->sym cgc)
  (gen-interned-symbol cgc))

;;-----------------------------------------------------------------------------
;; symbol->string
(define (x86-codegen-sym->str cgc)
  ;; Alloc
  (x86-mov cgc (x86-rax) (x86-mem 0 (x86-rsp)))
  (x86-sub cgc (x86-rax) (x86-imm-int TAG_MEMOBJ))
  (x86-mov cgc (x86-rax) (x86-mem 0 (x86-rax)))
  (x86-shr cgc (x86-rax) (x86-imm-int 8))
  (x86-shl cgc (x86-rax) (x86-imm-int 2)) ;; Length in rax
  (gen-allocation cgc #f STAG_STRING 0 #t)
  ;; String address in rbx
  (x86-mov cgc (x86-rbx) alloc-ptr)
  ;; Symbol address in rax
  (x86-pop cgc (x86-rax))
  (x86-sub cgc (x86-rax) (x86-imm-int TAG_MEMOBJ))
  ;; Mov length in string
  (x86-mov cgc (x86-r15) (x86-mem 8 (x86-rax)))
  (x86-mov cgc (x86-mem 8 (x86-rbx)) (x86-r15))
  ;; Mov header in string
  (x86-mov cgc (x86-r15) (x86-mem 0 (x86-rax)))
  (x86-add cgc (x86-r15) (x86-imm-int (arithmetic-shift (- STAG_STRING STAG_SYMBOL) 3)))
  (x86-mov cgc (x86-mem 0 (x86-rbx)) (x86-r15))
  ;; Encoded length in r15
  (x86-shr cgc (x86-r15) (x86-imm-int 8))
  (x86-shl cgc (x86-r15) (x86-imm-int 3))
  ;; If encoded length == 16
  ;;    jump label-fin
  (let ((label-loop (asm-make-label cgc (new-sym 'label-loop)))
        (label-fin  (asm-make-label cgc (new-sym 'label-fin))))

    (x86-label cgc label-loop)
    (x86-cmp cgc (x86-r15) (x86-imm-int 16))
    (x86-jle cgc label-fin)

      (x86-mov cgc (x86-rdx) (x86-mem -8 (x86-r15) (x86-rax)))
      (x86-mov cgc (x86-mem -8 (x86-r15) (x86-rbx)) (x86-rdx))
      (x86-sub cgc (x86-r15) (x86-imm-int 8))
      (x86-jmp cgc label-loop)

    (x86-label cgc label-fin)
    (x86-add cgc (x86-rbx) (x86-imm-int TAG_MEMOBJ))
    (x86-push cgc (x86-rbx))))


;;-----------------------------------------------------------------------------
;; vector/string-length
(define (x86-codegen-vec/str-length cgc)
  (x86-pop cgc (x86-rax)) ;; Pop vector
  (x86-push cgc (x86-mem (- 8 TAG_MEMOBJ) (x86-rax))))

;;-----------------------------------------------------------------------------
;; vector-ref
(define (x86-codegen-vector-ref cgc)
  (x86-pop cgc (x86-rax)) ;; Pop index
  (x86-pop cgc (x86-rbx)) ;; Pop vector
  (x86-shl cgc (x86-rax) (x86-imm-int 1))
  (x86-add cgc (x86-rbx) (x86-rax))
  (x86-push cgc (x86-mem (- 16 TAG_MEMOBJ) (x86-rbx))))

;;-----------------------------------------------------------------------------
;; string-ref
(define (x86-codegen-string-ref cgc)
  (x86-pop cgc (x86-rax)) ;; Pop index
  (x86-pop cgc (x86-rbx)) ;; Pop string
  (x86-shr cgc (x86-rax) (x86-imm-int 2)) ;; Decode position
  (x86-mov cgc (x86-al) (x86-mem (- 16 TAG_MEMOBJ) (x86-rax) (x86-rbx))) ;; Get Char
  (x86-and cgc (x86-rax) (x86-imm-int 255)) ;; Clear bits before al
  (x86-shl cgc (x86-rax) (x86-imm-int 2)) ;; Encode char
  (x86-add cgc (x86-rax) (x86-imm-int TAG_SPECIAL))
  (x86-push cgc (x86-rax))) ;; Push char

;;-----------------------------------------------------------------------------
;; vector-set!
(define (x86-codegen-vector-set! cgc)
  (x86-mov cgc (x86-rax) (x86-mem 8 (x86-rsp)))  ;; Get index
  (x86-mov cgc (x86-rbx) (x86-mem 16 (x86-rsp))) ;; Get vector
  (x86-mov cgc (x86-rdx) (x86-mem 0 (x86-rsp)))  ;; Get new value
  (x86-shl cgc (x86-rax) (x86-imm-int 1))
  (x86-mov cgc (x86-mem (- 16 TAG_MEMOBJ) (x86-rbx) (x86-rax)) (x86-rdx))
  (x86-add cgc (x86-rsp) (x86-imm-int 24))
  (x86-mov cgc (x86-rax) (x86-imm-int ENCODING_VOID))
  (x86-push cgc (x86-rax)))

;;-----------------------------------------------------------------------------
;; string-set!
(define (x86-codegen-string-set! cgc)
  (x86-mov cgc (x86-rax) (x86-mem 8 (x86-rsp)))  ;; Get index
  (x86-mov cgc (x86-rbx) (x86-mem 16 (x86-rsp))) ;; Get string
  (x86-mov cgc (x86-rdx) (x86-mem 0 (x86-rsp)))  ;; Get new value
  (x86-shr cgc (x86-rdx) (x86-imm-int 2))
  (x86-shr cgc (x86-rax) (x86-imm-int 2))
  (x86-mov cgc (x86-mem (- 16 TAG_MEMOBJ) (x86-rbx) (x86-rax)) (x86-dl))
  (x86-add cgc (x86-rsp) (x86-imm-int 24))
  (x86-mov cgc (x86-rax) (x86-imm-int ENCODING_VOID))
  (x86-push cgc (x86-rax)))