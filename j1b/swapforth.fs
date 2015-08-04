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
include core0.fs
include double0.fs

: align     here aligned dp ! ;

: 2>r   r> -rot swap >r >r >r ;
: 2r>
    postpone r>
    postpone r>
    postpone swap
; immediate
: 2r@   r> 2r> 2dup 2>r rot >r ;

: create
    :
    align here postpone literal
    postpone ;
;

: >body
    uw@ 32767 and
;

: allot
    dp +!
;

\ : ?do postpone do ; immediate
include double.fs
include core.fs

: /mod      >r s>d r> sm/rem ;
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

: ."
    [char] " parse
    state @ if
        postpone sliteral
        postpone type
    else
        type
    then
; immediate

: unused $4000 cp @ - $8000 here - + ;
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

: .xt  \ print xt's name
    . exit
    begin
        2 -
        dup c@ 20 <
    until
    count type
;

: see
    base @ hex
    '
    64 bounds
    begin
        cr dup .
        dup uw@ >r
        r@ 4 .r space
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

: new
    s" | marker |" evaluate
;
marker |
