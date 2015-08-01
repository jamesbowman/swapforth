: \     source nip >in ! ; immediate \ Now can use comments!
\       
\ This file contains definitions in high-level Forth for the
\ rest of Swapforth. Many words were already defined in
\ nucleus -- this file fills in the gaps.
\       
\ This file is divided into sections for each word set in ANS
\ Forth.
\
\ The only definitions in this file should be specific to
\ Swapforth Python (sfpy).

\ #######   CORE AND DOUBLE   #################################

: '
    parse-name
    sfind
    0= -13 and throw
;

: [']
    ' postpone literal
; immediate

: char
    parse-name drop c@
;

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

\ include double0.fs

\ : 2>r   r> -rot swap >r >r >r ;
\ : 2r>
\     postpone r>
\     postpone r>
\     postpone swap
\ ; immediate
\ : 2r@   r> 2r> 2dup 2>r rot >r ;

: create
    :
    here postpone literal
    postpone ;
;

\ : >body
\     uw@ 32767 and
\ ;

: ?do postpone do ; immediate
\ include double.fs

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

: sliteral
    here postpone literal
    postpone count
    s,
; immediate

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
    $3000 cp @ - here -
;

: pad
    here aligned
;

include core-ext.fs

: ms 0 do 1491 0 do loop loop ;
: leds  4 io! ;

: marker
    forth @
    dp @
    cp @
    create
        , , ,
    does>
        dup @ cp !
        cell+ dup @ dp !
        cell+ @ forth !
;

( ALL-MEMORY DUMP                            JCB 16:34 06/07/15)

: serialize \ print out all of program memory as base-36 cells
    base @
    #36 base !
    $1000 $0000 do
        i code@ .
    2 +loop
    $2000 $1000 do
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

: chars ;
: char+ 1+ ;
