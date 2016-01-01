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
\ Swapforth X86.

\ #######   CORE AND DOUBLE   #################################
include core0.fs

: align     here aligned dp ! ;
: allot     dp +! ;
: dabs      dup 0< if dnegate then ;
: d0=       or 0= ;
: 2rot      >r >r 2swap r> r> 2swap ;

\ : x [ here ] 1 ; 4 allot align here swap - .x

: create
    align
    :
    here postpone literal
    postpone ;
;

\ Offset of the LIT in a CREATE is
\  7 bytes for x86
\ 10 bytes for x86-64
: >body
     [ 1 cells 8 = 3 and 7 + ] literal + @
;

include double.fs
include core.fs

\ decimal : bench 1 . cr  100000000 begin 1- dup 0= until . ; bench

: /mod      >r s>d r> sm/rem ;
: /         /mod nip ;
: mod       /mod drop ;

\ #######   CORE EXT   ########################################

: c"
    [char] " parse
    here postpone literal
    dup c, s,
; immediate

: sliteral ( caddr u -- )
    here postpone literal
    dup postpone literal
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

: pad here aligned ;

include core-ext0.fs
include core-ext.fs

: marker
    forth @ dp @
    create
        , ,
    does>
        dup @ dp !
        cell+ @ forth !
;

: environment?
    2drop false
;

\ #######   EVERYTHING ELSE   #################################

include float0.fs
include string0.fs
include string.fs
include tools-ext.fs
include value.fs
include exception.fs
include facilityext.fs

: LOCALWORDS ;
: PUBLICWORDS ;
: DONEWORDS ;

include escaped.fs
include deferred.fs
include forth2012.fs

include structures.fs
\ include memory.fs

include comus.fs
include mini-oof.fs

: .b ( u -- )
    base @ >r hex
    s>d <# # # #> type space
    r> base !
;

: .xt ( xt -- )
    40 - count type
;

: see ( -- )
    '
    ." : " dup .xt cr
    dup

    dup 8 - @ 32 rshift
    bounds ?do
        \ i .x
        i c@ case
            \ $e8 of
            \     ." call " i 1+ @ $ffffffff and $ffffffff00000000 or i 5 + + dup .x .xt
            \     5
            \     endof
            \ $e9 of
            \     ." jmp  " i 1+ @ $ffffffff and $ffffffff00000000 or i 5 + + dup .x .xt
            \     5
            \     endof
            dup .b 1 swap
        endcase
    +loop
    space cr

    ." ; "
    dup 8 - @
    dup 1 and if ." immediate " then
    2 and if ." inline" then
    cr
;

: new
    s" | marker |" evaluate
;
marker |
