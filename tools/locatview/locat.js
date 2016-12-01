var locat_info = {
  "10.1.0": ["~#versions","1","~ctx1","Stack -> integer ","Reg-alloc -> ((0 r . 8))",],
  "10.13.0": ["~#versions","1","~ctx1","Stack -> ","Reg-alloc -> ()",],
  "7.7.0": ["~#versions","3","~ctx1","Stack -> integer integer integer closure retaddr ","Reg-alloc -> ((4 r . 2) (3 m . 4) (2 m . 2) (1 m . 3) (0 m . 0))","~ctx2","Stack -> 1 1 integer closure retaddr ","Reg-alloc -> ((4 . #f) (3 . #f) (2 r . 0) (1 r . 2) (0 m . 0))","~ctx3","Stack -> 1 integer integer closure retaddr ","Reg-alloc -> ((4 . #f) (3 r . 2) (2 m . 2) (1 m . 3) (0 m . 0))",],
  "7.7.1": ["~#versions","1","~ctx1","Stack -> integer integer integer integer integer closure retaddr ","Reg-alloc -> ((6 r . 8) (5 m . 5) (4 m . 1) (3 m . 4) (2 m . 2) (1 m . 3) (0 m . 0))",],
  "8.10.0": ["~#versions","1","~ctx1","Stack -> integer integer integer integer closure retaddr ","Reg-alloc -> ((5 r . 8) (4 m . 1) (3 m . 4) (2 m . 2) (1 m . 3) (0 m . 0))",],
  "7.10.0": ["~#versions","1","~ctx1","Stack -> integer integer integer closure retaddr ","Reg-alloc -> ((4 r . 4) (3 r . 2) (2 m . 2) (1 m . 3) (0 m . 0))",],
  "5.7.0": ["~#versions","2","~ctx1","Stack -> 2 integer integer 1 integer closure retaddr ","Reg-alloc -> ((6 . #f) (5 r . 3) (4 r . 1) (3 . #f) (2 r . 0) (1 r . 2) (0 m . 0))","~ctx2","Stack -> 2 integer integer integer integer closure retaddr ","Reg-alloc -> ((6 . #f) (5 r . 8) (4 r . 4) (3 r . 2) (2 m . 2) (1 m . 3) (0 m . 0))",],
  "8.15.0": ["~#versions","2","~ctx1","Stack -> 2 integer 1 integer closure retaddr ","Reg-alloc -> ((5 . #f) (4 r . 3) (3 . #f) (2 r . 0) (1 r . 2) (0 m . 0))","~ctx2","Stack -> 2 integer integer integer closure retaddr ","Reg-alloc -> ((5 . #f) (4 r . 8) (3 r . 2) (2 m . 2) (1 m . 3) (0 m . 0))",],
  "7.7.2": ["~#versions","1","~ctx1","Stack -> integer integer integer integer closure retaddr ","Reg-alloc -> ((5 r . 8) (4 m . 4) (3 m . 1) (2 m . 2) (1 m . 3) (0 m . 0))",],
  "8.10.1": ["~#versions","1","~ctx1","Stack -> integer integer integer closure retaddr ","Reg-alloc -> ((4 r . 8) (3 m . 1) (2 m . 2) (1 m . 3) (0 m . 0))",],
  "7.10.1": ["~#versions","1","~ctx1","Stack -> integer integer closure retaddr ","Reg-alloc -> ((3 r . 3) (2 r . 0) (1 r . 2) (0 m . 0))",],
  "5.7.1": ["~#versions","1","~ctx1","Stack -> 2 integer integer integer closure retaddr ","Reg-alloc -> ((5 . #f) (4 r . 1) (3 r . 3) (2 r . 0) (1 r . 2) (0 m . 0))",],
  "7.15.0": ["~#versions","1","~ctx1","Stack -> 1 integer integer closure retaddr ","Reg-alloc -> ((4 . #f) (3 r . 1) (2 r . 0) (1 r . 2) (0 m . 0))",],
  "5.7.2": ["~#versions","1","~ctx1","Stack -> 2 integer integer closure retaddr ","Reg-alloc -> ((4 . #f) (3 r . 1) (2 r . 0) (1 r . 2) (0 m . 0))",],
  "7.15.1": ["~#versions","1","~ctx1","Stack -> 1 integer 0 integer integer closure retaddr ","Reg-alloc -> ((6 . #f) (5 r . 1) (4 . #f) (3 r . 3) (2 r . 0) (1 r . 2) (0 m . 0))",],
  "8.15.1": ["~#versions","1","~ctx1","Stack -> 2 integer 0 integer integer integer closure retaddr ","Reg-alloc -> ((7 . #f) (6 r . 4) (5 . #f) (4 r . 8) (3 m . 1) (2 m . 2) (1 m . 3) (0 m . 0))",],
  "7.15.2": ["~#versions","1","~ctx1","Stack -> 1 integer 0 integer integer integer closure retaddr ","Reg-alloc -> ((7 . #f) (6 r . 8) (5 . #f) (4 r . 4) (3 r . 2) (2 m . 2) (1 m . 3) (0 m . 0))",],
  "8.15.2": ["~#versions","1","~ctx1","Stack -> 2 integer 0 integer integer integer integer closure retaddr ","Reg-alloc -> ((8 . #f) (7 r . 0) (6 . #f) (5 r . 8) (4 m . 1) (3 m . 4) (2 m . 2) (1 m . 3) (0 m . 0))",],
}
var code = "(declare (standard-bindings) (extended-bindings) (not inline-primitives) (block) (not safe))\n\n\n(define (fib n)\n  (if (< n 2)\n      1\n      (+ (fib (- n 1))\n         (fib (- n 2)))))\n\n(gambit$$pp (fib 40))\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n;; WIP:\n;; -> Quand on g\351n\350re un E.P. g\351n\351rique, il faut patcher le pt g\351n\351rique + la fermeture a l'index\n\n;; ->\n;; * Merge regalloc\n;; * Merge max versions\n;; * add bound tests\n\n\n;; NEXT:\n;; * check cc-key\n;; * utiliser un systeme pour les globales non mutables compatible avec le nouvel cst vers.\n;; * return value (type cr)\n\n;; TODO: quand on r\351cup\350re l'emplacement d'une variable, regarder les slots pour trouver la meilleure loc (cst >\240reg >\240mem)\n;; TODO: #<ctx-tclo #3 sym: closure mem-allocated?: #t is-cst: (lambda () ($$atom 1)) cst: #f fn-num: 0>\n;;       pourquoi l'ast dans is-cst?\n;; TODO: merge de regalloc\n;; TODO: merge de version\n;; TODO: jitter le alloc-rt pour ne pas g\351n\351rer de code si la taille ne n\351cessite pas un still\n;; TODO: ajouter le support des constantes dans les globales non mutables\n\n;; Liveness: terminer le travail\n;; Letrec: attention aux lates !function\n;; Liveness: pb sur '() ?\n;; Liveness: cas sp\351cial, set-box! est un kill\n;; Liveness: alpha conversion\n;; Regalloc: pb movs en trop (fib.s)\n\n;; TODO: optimization: pour un pt entr\351e:\n;;       * si on g\351n\350re un pt entr\351e dont la 1ere instruction est un jump,\n;;       * on peut patcher le pt d'entr\351e pour sauter directement au bon endroit\n";