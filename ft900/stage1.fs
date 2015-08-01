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

include double.fs

include string.fs

\ #######   SEARCH   ##########################################

: wordlist
    align
    here dup
    _wl @ ,
    0 ,
    _wl !
;

\ #######   EXCEPTION   #######################################

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
