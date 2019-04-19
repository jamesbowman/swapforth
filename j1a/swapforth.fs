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

: >body
    4 +
;

: create
    :
    here >body postpone literal
    postpone ;
;

include ../common/core.fs

: /mod      >r s>d r> sm/rem ;
: /         /mod nip ;
: mod       /mod drop ;

: ."
    [char] " parse
    state @ if
        postpone sliteral
        postpone type
    else
        type
    then
; immediate

: abort"
    postpone if
    postpone ."
    postpone abort
    postpone then
; immediate

\ #######   CORE EXT   ########################################

: unused
    $2000 here -
;

: pad
    here aligned
;

include ../common/core-ext.fs

: marker
    forth 2@        \ preserve FORTH and DP
    create
        , ,
    does>
        2@ forth 2! \ restore FORTH and DP
;

: ms 0 do 5986 0 do loop loop ;
: leds  4 io! ;

: new
    s" | marker |" evaluate
;
marker |

: .xt ( xt -- ) \ print XT's address and name, if valid
    dup .x
    dup
    begin
        2 -
        dup c@ $20 <
    until
    \ confirm by looking up with FIND
    tuck      ( caddr xt caddr )
    find      ( caddr xt xt n | caddr xt caddr 0 )
    0<> and = if
        count type
    else
        drop  \ not valid, so discard
    then
;

\ Construct a 4-entry jump table called _
\ for the four J1 opcodes

( 3:ALU     ) :noname ." alu: " 2/ .x ;
( 2:CALL    ) :noname [char] C emit space .xt ;
( 1:0BRANCH ) :noname [char] Z emit space .x ;
( 0:JUMP    ) :noname [char] J emit space .xt ;
create _ , , , ,

: see
    '
    48 bounds
    begin
        cr dup .x
        dup @
        dup .x
        6 spaces
        dup 0< if
            [char] $ emit
            32767 and .x
        else
            dup 8191 and 2*
            swap 13 rshift cells _ + @ execute
        then
        cell+
        2dup =
    until
    2drop
;

: dump
    ?dup
    if
        1- 4 rshift 1+
        0 do
            cr dup dup .x space space
            16 0 do
                dup c@ .x2 1+
            loop
            space swap
            16 0 do
                dup c@ dup bl 127 within invert if
                    drop [char] .
                then
                emit 1+
            loop
            drop
        loop
    then
    drop
;
