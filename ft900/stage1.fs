: bl        32 ;
: char      parse-name drop c@ ;

: [char]
    char postpone literal
; immediate

: (
    [char] ) parse 2drop
; immediate

internal-wordlist set-current

: ensign ( u1 n1 -- n2 ) \ n2 is u1 with the sign of n1
    0< if negate then
;

forth-wordlist set-current

\ Divide d1 by n1, giving the symmetric quotient n3 and the remainder
\ n2.
: sm/rem ( d1 n1 -- n2 n3 )
    2dup xor >r     \ combined sign, for quotient
    over >r         \ sign of dividend, for remainder
    abs >r dabs r>
    um/mod          ( remainder quotient )
    swap r> ensign  \ apply to remainder
    swap r> ensign  \ apply to quotient
;

\ Divide d1 by n1, giving the floored quotient n3 and the remainder n2.
\ Adapted from hForth
: fm/mod ( d1 n1 -- n2 n3 )
    dup >r 2dup xor >r
    >r dabs r@ abs
    um/mod
    r> 0< if
        swap negate swap
    then
    r> 0< if
        negate         \ negative quotient
        over if
            r@ rot - swap 1-
        then
    then
    r> drop
;

: */mod
    >r m* r> sm/rem
;

: */
    */mod nip
;

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

: variable
    create 4 allot
;

\ : constant  create , does> @ ;
: constant  : postpone literal postpone ; ;

\ #######   CORE EXT   ########################################

: source-id (source-id) @ ;

: tuck      swap over ;
: erase     0 fill ;

: pm+!
    tuck pm@ + swap pm!
;

: -rot
    rot rot
;

: bounds \ ( a u -- a+u a )
    over + swap
;

internal-wordlist set-current
: forstring
    postpone bounds
    postpone ?do
; immediate

: s,
    dup c,
    forstring
        i c@ c,
    loop
;
forth-wordlist set-current

: '
    parse-name
    sfind
    0= -13 and throw
;

: [']
    ' postpone literal
; immediate

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

: find
    dup
    count sfind
    dup 0= if
        nip nip
    else
        rot drop
    then
;

: type
    forstring
        i c@ emit
    loop
;

: .(
    [char] ) parse type
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

create tmpbuf 80 allot  \ The "temporary buffer" in the ANS standard

: s"
    [char] " parse
    state @ if
        postpone sliteral
    else
        tuck tmpbuf swap cmove
        tmpbuf swap
    then
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



\ From the ANS specification
: within  ( test low high -- flag )
    over - >r - r> u<
;

\     here   80    pad
\ -----|------------|-----
\       word,<# area

: pad
    here 80 + aligned
;

: word
    begin
        source drop >in @ + c@ over =
        source nip >in @ <> and
    while
        1 >in +!
    repeat

    parse
    dup here c!
    here 1+ swap cmove
    here
;

( Pictured numeric output                    JCB 08:06 07/18/14)
\ Adapted from hForth

variable hld

: <#
    pad hld !
;

: hold
    hld @ 1- dup hld ! c!
;

: sign
    0< if
        [char] - hold
    then
;

: #
    0 base @ um/mod >r base @ um/mod swap
    9 over < [ char A char 9 1 + - ] literal and +
    [ char 0 ] literal + hold r>
;

: #s
    begin
        #
        2dup d0=
    until
;

: #>
    2drop hld @ pad over -
;

: move ( addr1 addr2 u -- )
    >r 2dup < if
        r> cmove>
    else
        r> cmove
    then
;
: spaces
    begin
        dup 0>
    while
        space 1-
    repeat
    drop
;

internal-wordlist set-current

: (d.)
    dup >r dabs <# #s r> sign #>
;

forth-wordlist set-current

: d.
    (d.) type space
;

: .
    s>d d.
;
    
: u.
    0 d.
;

: rtype ( caddr u1 u2 -- ) \ display character string specified by caddr u1
                           \ in a field u2 characters wide.
    over - spaces type
;

: d.r
    >r (d.)
    r> rtype
;

: .r
    >r s>d r> d.r
;

: u.r
    0 swap d.r
;

( CASE                                       JCB 09:15 07/18/14)
\ From ANS specification A.3.2.3.2

0 constant case immediate  ( init count of ofs )

: of  ( #of -- orig #of+1 / x -- )
    1+    ( count ofs )
    >r    ( move off the stack in case the control-flow )
          ( stack is the data stack. )
    postpone over  postpone = ( copy and test case value)
    postpone if    ( add orig to control flow stack )
    postpone drop  ( discards case value if = )
    r>             ( we can bring count back now )
; immediate

: endof ( orig1 #of -- orig2 #of )
    >r   ( move off the stack in case the control-flow )
         ( stack is the data stack. )
    postpone else
    r>   ( we can bring count back now )
; immediate

: endcase  ( orig1..orign #of -- )
    postpone drop  ( discard case value )
    0 ?do
      postpone then
    loop
; immediate

: save-input
    >in @ 1
;

: restore-input
    drop >in !
    true
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


\ #######   STRING   ##########################################

: blank
    dup 0> if
        bl fill
    else
        2drop
    then
;

: -trailing
    dup 0> if
        begin
            2dup + 1- c@ bl =
            over 0<> and
        while
            1-
        repeat
    then
;

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
