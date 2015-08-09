\       
\ This file contains definitions in high-level Forth for the
\ rest of SwapForth. Many words were already defined in
\ nucleus -- this file fills in the gaps.
\       
\ This file is divided into sections for each word set in ANS
\ Forth.
\
\ The only definitions in this file should be specific to
\ J1a SwapForth.

\ #######   CORE AND DOUBLE   #################################

: [']
    ' postpone literal
; immediate

: [char]
    char postpone literal
; immediate

: (
    [char] ) parse 2drop
; immediate

: else
    postpone ahead
    swap
    postpone then
; immediate

: while
    postpone if
    swap
; immediate

: repeat
     postpone again
     postpone then
; immediate

: create
    :
    here 4 + postpone literal
    postpone ;
;

: >body
    @ 32767 and
;

: ?do postpone do ; immediate

: m*
    2dup xor >r
    abs swap abs um*
    r> 0< if dnegate then
;

include core.fs

: /mod      >r s>d r> sm/rem ;
: /         /mod nip ;
: mod       /mod drop ;

\ #######   CORE EXT   ########################################

: ."
    [char] " parse
    state @ if
        postpone sliteral
        postpone type
    else
        type
    then
; immediate

: unused
    $2000 here -
;

: pad
    here aligned
;

include core-ext.fs

: ms 0 do 1325 0 do loop loop ;
: leds  4 io! ;

: marker
    forth 2@        \ preserve FORTH and DP
    create
        , ,
    does>
        2@ forth 2! \ restore FORTH and DP
;

( ALL-MEMORY DUMP                            JCB 16:34 06/07/15)

: serialize \ print out all of memory as base-36 cells
    base @
    #36 base !
    $2000 $0000 do
        i @ .
    2 +loop
    base !
;

: new
    s" | marker |" evaluate
;
marker |

: hex2. ( u -- )
    base @ swap
    hex
    s>d <# # # #> type space
    base !
;

: .xt  \ print xt's name
    begin
        2 -
        dup c@ 20 <
    until
    count type
;

: see
    base @ hex
    '
    32 bounds
    begin
        cr dup .
        dup @ >r
        r@ 4 .r
        6 spaces
        r@ 15 rshift if
            [char] L emit space
            r@ 32767 and .
        else
            r@ 13 rshift 0 = if
                [char] J emit space
                r@ 8191 and 2* .
            then
            r@ 13 rshift 1 = if
                [char] Z emit space
                r@ 8191 and 2* .
            then
            r@ 13 rshift 2 = if
                r@ 8191 and 2* .xt
            then
        then
        r> drop
        2 +
        2dup =
    until
    2drop
    base !
;


: (.s)
    depth if
        >r recurse r>
        dup .x
    then
;

: .s
    [char] < emit depth .x [char] > emit space
    (.s)
;

: dump
    ?dup
    if
        base @ >r hex
        1- 4 rshift 1+
        0 do
            cr dup dup 8 u.r space space
            16 0 do
                dup c@ hex2. 1+
            loop
            space swap
            16 0 do
                dup c@ 127 and
                dup 0 bl within over 127 = or
                if drop [char] . then
                emit 1+
            loop
            drop
        loop
        r> base !
    then
    drop
;
