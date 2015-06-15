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

: false     0 ;
: true      -1 ;
: 1+        1 + ;
: 1-        -1 + ;
: 0=        0 = ;
: cell+     4 + ;
: <>        = invert ; 
: >         swap < ; 
: 0<        0 < ; 
: 0>        0 > ;
: 0<>       0 <> ;
: u>        swap u< ; 
: rot       >r swap r> swap ; 
: -rot      swap >r swap r> ; 
: ?dup      dup if dup then ;
: abs       dup 0< if negate then ;
: +!        tuck @ + swap ! ; 
: 2*        dup + ;
: cells     4 * ;
: count     dup 1+ swap c@ ;

include core0.fs
include double0.fs

: aligned   ;
: align     ;

: 2>r   swap >r >r ;
: 2r>   r> r> swap ;
: 2r@   2r> 2dup 2>r ;

: create
    :
    align here postpone literal
    postpone ;
;

include double.fs

: bounds
    over + swap
;

: type
    bounds ?do
        i c@ emit
    loop
;

: fill \ ( c-addr u char -- ) ( 6.1.1540 )
    >r bounds
    begin
      2dup xor
    while
      r@ over c! 1+
    repeat
    r> drop 2drop
;

: cmove \ ( addr1 addr2 u -- )
    bounds rot >r
    begin
        2dup xor
    while
        r@ c@ over c!
        r> 1+ >r
        1+
    repeat
    r> drop 2drop
;

: cmove> \ ( addr1 addr2 u -- )
    begin
        dup
    while
        1- >r
        over r@ + c@
        over r@ + c!
        r>
    repeat
    drop 2drop
;

include core.fs

: /         /mod nip ;
: mod       /mod drop ;

\ #######   CORE EXT   ########################################

: s,
    dup c,
    bounds ?do
        i c@ c,
    loop
;

: c"
    here postpone literal
    [char] " parse
    s,
; immediate

: sliteral
    here postpone literal
    postpone count
    s,
; immediate

: (.")
    count 2dup type + 1+ >r
;

: ."
    [char] " parse
    state @ if
        here postpone literal
        postpone (.")
        s,
    else
        type
    then
; immediate

: unused here negate ;

create pad 65536 allot

include core-ext0.fs
include core-ext.fs

\ #######   EVERYTHING ELSE   #################################

include float0.fs
include string0.fs
include string.fs
include tools-ext.fs
include value.fs
include exception.fs


: LOCALWORDS ;
: PUBLICWORDS ;
: DONEWORDS ;

include escaped.fs
include deferred.fs
include forth2012.fs

include structures.fs
include memory.fs

include runtests.fs
