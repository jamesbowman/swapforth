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

: m*
    2dup xor >r
    abs swap abs um*
    r> 0< if dnegate then
;

include core.fs

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

include core-ext.fs

: marker
    forth 2@        \ preserve FORTH and DP
    create
        , ,
    does>
        2@ forth 2! \ restore FORTH and DP
;

: ms 0 do 5986 0 do loop loop ;
: leds  4 io! ;

( ALL-MEMORY DUMP                            JCB 16:34 06/07/15)

: new
    s" | marker |" evaluate
;
marker |

\ Construct a 4-entry jump table called _
\ for the four J1 opcodes

( 3:ALU     ) :noname ." alu: " 2/ .x ;
( 2:CALL    ) :noname  \ print xt's name
                  begin
                      2 -
                      dup c@ 20 <
                  until
                  count type
              ;
( 1:0BRANCH ) :noname [char] Z emit space .x ;
( 0:JUMP    ) :noname [char] J emit space .x ;
create _ , , , ,

: see
    '
    32 bounds
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
