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
: +!        tuck @ + swap ! ; 
: allot     dp +! ;
: dabs      dup 0< if dnegate then ;
: d0=       or 0= ;

\ : x [ here ] 1 ; 4 allot align here swap - .x

: create
    :
    here 28 + postpone literal
    postpone ;
    4 allot
    align
;

: >body
     9 + @
;

include double.fs
include core.fs

\ : bench 1 . cr  100000000 begin 1- dup 0= until . ; bench

: /mod      >r s>d r> sm/rem ;
: /         /mod nip ;
: mod       /mod drop ;

\ #######   CORE EXT   ########################################

\ : c"
\     here postpone literal
\     [char] " parse
\     s,
\ ; immediate

: (sliteral)
    r> count
    2dup + >r
;

: sliteral
    postpone (sliteral)
    dup c,
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
    forth @ dp @ cp @
    create
        , , ,
    does>
        dup @ cp !
        cell+ dup @ dp !
        cell+ @ forth !
;

: .xt  ( xt -- ) \ print xt's name
    >r
    forth @
    begin
        dup 0= if
            r> 2drop exit
        then
        dup
        2 +
        count + caligned
        uw@ r@ <>
    while
        uw@ -2 and
    repeat
    r> drop
    2 + count type
;

create op4          \ 4-bit field names, bits [11:8]
    s" T"           s,
    s" N"           s,
    s" T+N"         s,
    s" T&N"         s,
    s" T|N"         s,
    s" T^N"         s,
    s" ~T"          s,
    s" N==T"        s,
    s" N<T"         s,
    s" N>>T"        s,
    s" N<<T"        s,
    s" rT"          s,
    s" [T]"         s,
    s" io[T]"       s,
    s" status"      s,
    s" Nu<T"        s,

create op3          \ 3-bit operation, bits [6:4]
    s" "            s,
    s" T->N"        s,
    s" T->R"        s,
    s" N->[T]"      s,
    s" N->io[T]"    s,
    s" _IORD_"      s,

create opr          \ 2-bit R stack delta, bits [3:2]
    s" "            s,
    s" r+1"         s,
    s" "            s,
    s" r-1"         s,

create opd          \ 2-bit D stack delta, bits [1:0]
    s" "            s,
    s" d+1"         s,
    s" "            s,
    s" d-1"         s,

: skip." ( addr u -- ) \ skip u strings, then print
    0 ?do
        count +
    loop (.")
    space
;

: .alu
    ." ALU "

    op4 over 8 rshift skip."

    op3 over 4 rshift 7 and skip."

    opr over 2 rshift 3 and skip."

    opd over 3 and skip."

    space
    $80 and if ." ;" then
;

\ Construct a 4-entry jump table J1op
\ for the four J1 opcodes

( 3:ALU     ) :noname 2/ .alu ;
( 2:CALL    ) ' .xt    \ print xt's name
( 1:0BRANCH ) :noname [char] Z emit space . ;
( 0:JUMP    ) :noname [char] J emit space . ;
create J1op , , , ,

: see
    base @ hex
    '
    64 bounds
    begin
        cr dup .
        dup uw@
        dup 4 .r space
        dup 15 rshift if
            32767 and
            [char] $ emit dup .
            decimal
            [char] # emit .
            hex
        else
            dup 8191 and 2* swap
            13 rshift cells J1op + @ execute
        then
        2 +
        2dup =
    until
    2drop
    base !
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

: new
    s" | marker |" evaluate
;
marker |
