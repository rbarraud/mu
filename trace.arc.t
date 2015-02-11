(selective-load "mu.arc" section-level)
(set allow-raw-addresses*)

(reset)
(new-trace "print-trace")
(add-code:readfile "trace.mu")
(add-code
  '((function! main [
      (default-space:space-address <- new space:literal 30:literal/capacity)
      (x:string-address <- new
"schedule: main
run: main 0: (((1 integer)) <- ((copy)) ((1 literal)))
run: main 0: 1 => ((1 integer))
mem: ((1 integer)): 1 <= 1
run: main 1: (((2 integer)) <- ((copy)) ((3 literal)))
run: main 1: 3 => ((2 integer))
mem: ((2 integer)): 2 <= 3
run: main 2: (((3 integer)) <- ((add)) ((1 integer)) ((2 integer)))
mem: ((1 integer)) => 1
mem: ((2 integer)) => 3
run: main 2: 4 => ((3 integer))
mem: ((3 integer)): 3 <= 4
schedule:  done with routine")
      (s:stream-address <- init-stream x:string-address)
      (traces:instruction-trace-address-array-address <- parse-traces s:stream-address)
      (len:integer <- length traces:instruction-trace-address-array-address/deref)
      (screen:terminal-address <- init-fake-terminal 70:literal 15:literal)
      (screen-state:space-address <- screen-state)
      (print-traces-collapsed screen-state:space-address screen:terminal-address traces:instruction-trace-address-array-address)
      (1:string-address/raw <- get screen:terminal-address/deref data:offset)
    ])))
;? (set dump-trace*)
;? (= dump-trace* (obj whitelist '("run")))
(run 'main)
(each routine completed-routines*
  (awhen rep.routine!error
    (prn "error - " it)))
;? (prn memory*.1)
(when (~memory-contains-array memory*.1
         (+ "+ main/ 0 : (((1 integer)) <- ((copy)) ((1 literal)))                 "
            "+ main/ 0 : 1 => ((1 integer))                                        "
            "+ main/ 1 : (((2 integer)) <- ((copy)) ((3 literal)))                 "
            "+ main/ 1 : 3 => ((2 integer))                                        "
            "+ main/ 2 : (((3 integer)) <- ((add)) ((1 integer)) ((2 integer)))    "
            "+ main/ 2 : 4 => ((3 integer))                                        "))
  (prn "F - print-traces-collapsed works"))

(reset)
(new-trace "print-trace-from-middle-of-screen")
(add-code:readfile "trace.mu")
(add-code
  '((function! main [
      (default-space:space-address <- new space:literal 30:literal/capacity)
      (x:string-address <- new
"schedule: main
run: main 0: (((1 integer)) <- ((copy)) ((1 literal)))
run: main 0: 1 => ((1 integer))
mem: ((1 integer)): 1 <= 1
run: main 1: (((2 integer)) <- ((copy)) ((3 literal)))
run: main 1: 3 => ((2 integer))
mem: ((2 integer)): 2 <= 3
run: main 2: (((3 integer)) <- ((add)) ((1 integer)) ((2 integer)))
mem: ((1 integer)) => 1
mem: ((2 integer)) => 3
run: main 2: 4 => ((3 integer))
mem: ((3 integer)): 3 <= 4
schedule:  done with routine")
      (s:stream-address <- init-stream x:string-address)
      (traces:instruction-trace-address-array-address <- parse-traces s:stream-address)
      (len:integer <- length traces:instruction-trace-address-array-address/deref)
      (1:terminal-address/raw <- init-fake-terminal 70:literal 15:literal)
      ; position the cursor away from top of screen
      (cursor-down 1:terminal-address/raw)
      (cursor-down 1:terminal-address/raw)
      (screen-state:space-address <- screen-state)
      (print-traces-collapsed screen-state:space-address 1:terminal-address/raw traces:instruction-trace-address-array-address)
      (2:string-address/raw <- get 1:terminal-address/raw/deref data:offset)
    ])))
(run 'main)
(each routine completed-routines*
  (awhen rep.routine!error
    (prn "error - " it)))
(when (~memory-contains-array memory*.2
         (+ "                                                                      "
            "                                                                      "
            "+ main/ 0 : (((1 integer)) <- ((copy)) ((1 literal)))                 "
            "+ main/ 0 : 1 => ((1 integer))                                        "
            "+ main/ 1 : (((2 integer)) <- ((copy)) ((3 literal)))                 "
            "+ main/ 1 : 3 => ((2 integer))                                        "
            "+ main/ 2 : (((3 integer)) <- ((add)) ((1 integer)) ((2 integer)))    "
            "+ main/ 2 : 4 => ((3 integer))                                        "))
  (prn "F - print-traces-collapsed works"))

(run-code main2
  (print-character 1:terminal-address/raw ((#\* literal))))
(when (~memory-contains-array memory*.2
         (+ "                                                                      "
            "                                                                      "
            "+ main/ 0 : (((1 integer)) <- ((copy)) ((1 literal)))                 "
            "+ main/ 0 : 1 => ((1 integer))                                        "
            "+ main/ 1 : (((2 integer)) <- ((copy)) ((3 literal)))                 "
            "+ main/ 1 : 3 => ((2 integer))                                        "
            "+ main/ 2 : (((3 integer)) <- ((add)) ((1 integer)) ((2 integer)))    "
            "+ main/ 2 : 4 => ((3 integer))                                        "
            "*                                                                     "))
  (prn "F - print-traces-collapsed leaves cursor at next line"))

(reset)
