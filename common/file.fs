0 value fib

: refill
    source-id 0> if
        fib 256 source-id read-line throw
        if
            fib swap tosource
            >in off
            true
        else
            drop false
        then
    else
        refill
    then
;

: include-file ( fileid -- )
    fib >r
    256 allocate throw to fib
    source 2>r
    >in @ >r
    source-id >r
    \ Store fileid in SOURCE-ID.
    \ Make the file specified by fileid the input source.
    \ Store zero in BLK.

    (source-id) !
    1 >r
    begin
        fib 256 (source-id) @ read-line throw
    while
        fib swap tosource
        >in off
        ['] interpret catch
\ cr .s [char] | emit source type
        ?dup if
            \ produce a friendly error message
            \ XXX - how to generate filename?
            \ XXX - should try to match a vim errorformat
            decimal
            cr ." At line " r@ u. ." column " >inwas @ u.
            cr source type
            throw
        then
        r> 1+ >r
    repeat
    r> 2drop
    (source-id) @ close-file throw

    r> (source-id) !
    r> >in !
    2r> tosource
    fib free throw
    r> to fib
;

: included  ( c-addr u -- )
    r/o open-file throw
    include-file
;

: include                         ( "filename" -- )
    parse-name included decimal
;

\ #######   TOOLS EXT   #######################################

( [IF] [ELSE] [THEN]                         JCB 10:59 07/18/14)
\ From ANS specification A.15.6.2.2533

: [ELSE]  ( -- )
    1 BEGIN                               \ level
      BEGIN
        BL WORD COUNT DUP  WHILE          \ level adr len
        2DUP  S" [IF]"  COMPARE 0=
        IF                                \ level adr len
          2DROP 1+                        \ level'
        ELSE                              \ level adr len
          2DUP  S" [ELSE]"
          COMPARE 0= IF                   \ level adr len
             2DROP 1- DUP IF 1+ THEN      \ level'
          ELSE                            \ level adr len
            S" [THEN]"  COMPARE 0= IF     \ level
              1-                          \ level'
            THEN
          THEN
        THEN ?DUP 0=  IF EXIT THEN        \ level'
      REPEAT  2DROP                       \ level
    REFILL 0= UNTIL                       \ level
    DROP
;  IMMEDIATE

: [IF]  ( flag -- )
0= IF POSTPONE [ELSE] THEN ;  IMMEDIATE

: [THEN]  ( -- )  ;  IMMEDIATE
