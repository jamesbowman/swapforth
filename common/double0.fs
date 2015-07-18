\ #######   DOUBLE low-level primmitives   ####################

: 2@ \ ( a -- lo hi )
    dup cell+ @ swap @
;

: 2! \ ( lo hi a -- )
    tuck !
    cell+ !
;

: 2rot
    >r >r 2swap r> r> 2swap
;

: 2literal
    swap postpone literal postpone literal
; immediate

: dnegate 
    invert swap invert swap 
    1. d+
; 

: dabs
    dup 0< if dnegate then
;

: s>d   dup 0< ;
: d>s   drop ;

: d=                        \ a b c d -- f ) 
    >r                      \ a b c 
    rot =                   \ b a=c 
    swap r> =               \ a=c b=d 
    and
; 

: d<            \ ( al ah bl bh -- flag ) 
    rot         \ al bl bh ah 
    2dup = 
    if 
        2drop u< 
    else 
        > nip nip
    then 
; 

: du<           \ ( al ah bl bh -- flag ) 
    rot         \ al bl bh ah 
    2dup = 
    if 
        2drop u< 
    else 
        u> nip nip
    then 
; 

: d-
    dnegate d+
;

: d0<
    nip 0<
;

: d0=
    or 0=
;

: d2*
    2dup d+
; 

: d2/
    >r 1 rshift r@
    [ 8 cells 1- ] literal lshift
    or r> 2/
;
