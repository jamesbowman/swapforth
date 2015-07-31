: bounds \ ( a u -- a+u a )
    over + swap
;

: bl        32 ;

: type
    bounds ?do
        i c@ emit
    loop
;

include core0.fs
include core.fs

\ #######   CORE EXT   ########################################

: source-id (source-id) @ ;

: tuck      swap over ;

: -rot
    rot rot
;

internal-wordlist set-current

: s,
    dup c,
    bounds ?do
        i c@ c,
    loop
;

forth-wordlist set-current

: [compile]
    ' compile,
; immediate

: is
    '
    state @ if
        postpone literal postpone defer!
    else
        defer!
    then
; immediate

: defer@
    pm@ $1ffff and cells
;

: action-of
    '
    state @ if
        postpone literal
        postpone defer@
    else
        defer@
    then
; immediate

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

: pmcount
    dup 1+ swap pmc@
;

: (.")
    r>
    begin
        pmcount dup
    while
        emit
    repeat
    drop
    aligned
    >r
;

: ."
    [char] " parse
    state @ if
        postpone (.")
        sync
        0 swap
        0 ?do
            ( caddr u32 )
            over i + c@ i 8 * lshift or
            i 3 and 3 = if
                pm,
                0
            then
        loop
        pm, drop
    else
        type
    then
; immediate


include core-ext.fs

\     here   80    pad
\ -----|------------|-----
\       word,<# area

: pad
    here 80 + aligned
;

: 2variable
    create 8 allot
;

: 2constant
    align create , ,
    does> 2@
;

: dmax
    2over 2over d< if
        2swap
    then
    2drop
;

: dmin
    2over 2over d< invert if
        2swap
    then
    2drop
;

: m+
    s>d d+
;

\ From Wil Baden's "FPH Popular Extensions"
\ http://www.wilbaden.com/neil_bawd/fphpop.txt

: TNEGATE                           ( t . . -- -t . . )
    >R  2dup OR dup IF DROP  DNEGATE 1  THEN
    R> +  NEGATE ;

: T*                                ( d . n -- t . . )
                                    ( d0 d1 n)
    2dup XOR >R                     ( R: sign)
    >R DABS R> ABS
    2>R                             ( d0)( R: sign d1 n)
    R@ UM* 0                        ( t0 d1 0)
    2R> UM*                         ( t0 d1 0 d1*n .)( R: sign)
    D+                              ( t0 t1 t2)
    R> 0< IF TNEGATE THEN ;

: T/                                ( t . . u -- d . )
                                    ( t0 t1 t2 u)
    over >R >R                      ( t0 t1 t2)( R: t2 u)
    dup 0< IF TNEGATE THEN
    R@ UM/MOD                       ( t0 rem d1)
    ROT ROT                         ( d1 t0 rem)
    R> UM/MOD                       ( d1 rem' d0)( R: t2)
    NIP SWAP                        ( d0 d1)
    R> 0< IF DNEGATE THEN ;

: M*/  ( d . n u -- d . )  >R T*  R> T/ ;

\ From ANS specification A.6.2.0970

: CONVERT   CHAR+ 65535 >NUMBER DROP ;

include string.fs

\ #######   SEARCH   ##########################################

: wordlist
    align
    here dup
    _wl @ ,
    0 ,
    _wl !
;

\ #######   FLOATING   ########################################

\ : u>f   ( u -- f )
\     dup if
\         dup 1 rshift recurse    ( u f[u/2] )
\         dup f+                  ( u 2*f[u/2] )
\         swap 1 and if
\             $3f800000 f+
\         then
\     then
\ ;

\ #######   EXCEPTION   #######################################

: abort
    true throw
;

internal-wordlist set-current
: (abort")  ( x1 caddr -- )
    swap if
        count type -2 throw
    else
        drop
    then
;
forth-wordlist set-current

: abort"
    postpone c"
    postpone (abort")
; immediate

include tools-ext.fs

\ #######   SEARCH EXT   ######################################

: also
    get-order
    over swap 1+
    set-order
;

: forth
    get-order
    nip forth-wordlist swap
    set-order
;

wordlist constant root

root set-current
: forth             forth ;
: forth-wordlist    forth-wordlist ;
: set-order         set-order ;
forth-wordlist set-current
: only
    root root 2 set-order
;

: previous
    get-order
    nip 1-
    set-order
;

: set-order
    dup -1 = if
        drop only
    else
        set-order
    then
;

internal-wordlist set-current
: .wl   ( wid -- )
    case
        internal-wordlist   of ." INTERNAL" endof
        forth-wordlist      of ." FORTH" endof
        root                of ." ROOT" endof
        dup .
    endcase
    space
;
forth-wordlist set-current

: order
    base @ hex
    get-order
    0 do
        .wl
    loop
    ." | "
    get-current .wl
    base !
;

: environment?
    \ xxx 2drop
    false
;

\ See ANS specification 9.3.5

:noname
    source-id if
        cr source type
    then
    cr >inwas @ spaces [char] ^ emit
    cr ." error: " 
    case
    -1  of ." aborted" endof
    -4  of ." stack underflow" endof
    -9  of ." invalid memory address" endof
    -13 of ." undefined word" endof
    -14 of ." interpreting a compile-only word" endof
    -28 of ." user interrupt" endof
    dup .
    endcase
    cr
; is report


\ #############################################################
\   End of Forth words. Application words follow.
\ #############################################################
depth throw

include tester.fs

include ft900/assembler.fs

: defer
    code 
    ['] abort [ also assembler ] jmp, [ previous ]
    end-code 
;

include value.fs
include optimize.fs
