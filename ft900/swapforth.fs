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
\ Swapforth FT900.

\ #######   CORE   ############################################

: marker
    here >r
    ctx swap over r@ swap cmove
    allot

    \ record the dictionary pointer of every word list
    align
    _wl @
    begin
        dup cell+ @ ,
        @ dup 0=
    until
    drop
    create r> ,

    does> @ dup ctx cmove           \ restore context
    ctx nip + aligned
    \ restore the dictionary pointer of every word list
    _wl @                           \ ( ptr wl )
    begin
        over @ over cell+ !         \ restore
        swap cell+ swap @ dup 0=    \ next
    until
    2drop
;

marker --base--

$8000 dp !
$20000 pmdp !

include stage1.fs
--base--
include stage1.fs

\ Start a local word definition region
\ These words will not be globally visible.
\ Usage:
\
\       localwords  \ {
\           ... define local words ...
\       publicwords \ }{
\           ... define public words ...
\       donewords   \ }
\

: LOCALWORDS
    get-current
    get-order wordlist swap 1+ set-order definitions
;

: PUBLICWORDS
    set-current
;

: DONEWORDS
    previous
;

marker testing-localwords
    : k0 100 ;
    t{ k0 -> 100 }t
    localwords
        : k0 200 ;
        : k1 300 ;
    publicwords
        t{ k0 k1 -> 200 300 }t
        : k01 k0 k1 ;
    donewords
    t{ k0 -> 100 }t
    t{ k01 -> 200 300 }t
    t{ bl word k1 find nip -> 0 }t
testing-localwords

include float1.fs
include float2.fs

include facilityext.fs

: key?  ( -- f )
    $10325 c@ 1 and 0<>
;

include ft900/dis.fs

\ #############################################################
depth throw

only forth definitions

\  from Wil Baden:
\  ANEW                            ( "name" -- )( Run: -- )
\     Compiler directive used in the form: `ANEW _name_`. If the word
\     _name_ already exists, it and all subsequent words are
\     forgotten from the current dictionary, then a `MARKER` word
\     _name_ is created. This is usually placed at the start of a
\     file. When the code is reloaded, any prior version is
\     automatically pruned from the dictionary.
\     Executing _name_ will also cause it to be forgotten, since
\     it is a `MARKER` word.

: POSSIBLY  ( "name" -- )  BL WORD FIND  ?dup AND IF  EXECUTE  THEN ;
: ANEW  ( "name" -- )( Run: -- )  >IN @ POSSIBLY  >IN ! MARKER ;

: bit
    1 swap lshift
;

: or!   ( x a -- )  \ logical or x with the cell at a
    tuck @ or swap !
;

: and!  ( x a -- )  \ logical and x with the cell at a
    tuck @ and swap !
;

: setbit  ( x a -- )  \ set bit x in cell a
    swap bit swap
    or!
;

: clearbit  ( x a -- )  \ clear bit x in cell a
    swap bit invert swap
    and!
;

t{ 3 bit -> 8 }t

: io
    $10000 + constant
;

: io-n  ( a0 u -- a1 )
    over constant +
;
: io-8   1 io-n ;
: io-16  2 io-n ;
: io-32  4 io-n ;

\ $00     io  regchipid
\ $04     io  regefcfg
$08     io  regclkcfg
\ $0c     io  regpmcfg
\ $10     io  regtstnset
\ $14     io  regtstnsetr
\ $18     io  regmsc0cfg_b0
\ $19     io  regmsc0cfg_b1
\ $1a     io  regmsc0cfg_b2
\ $1b     io  regmsc0cfg_b3
\ 
\ $a8     io  regphymsc_b0
\ $a9     io  regphymsc_b1

: clockon   ( u -- f )    \ enable clock of unit u
    dup bit regclkcfg @ and 0= swap
    regclkcfg setbit
;

: clockoff  ( u -- )    \ disable clock of unit u
    regclkcfg clearbit
;

include ft900/int.fs
include ft900/flash.fs

: .version
    cr ." swapForth v0.1"
;

: cold
    .version
    cold
;

only forth definitions

( FT900 operations                           JCB 16:14 07/21/14)

decimal

: pads  ( u pad -- ) \ set pad's function to u
    $1001c + c!
;

0 constant INPUT
4 constant OUTPUT

: pinMode ( mode pin -- ) \ set pin to INPUT or OUTPUT GPIO
    0 over pads
    dup 2/ $10060 + >r
    1 and if
        4 lshift $0f
    else
        $f0
    then
    r@ c@ and or r> c!
;

: serialize \ print out all of program memory as base-36 cells
    base @
    commit
    $24 base !
    0 do
        i pm@ .
    4 +loop
    base !
;

depth 0<> throw

include escaped.fs
include forth2012.fs
include structures.fs

include comus.fs
include mini-oof.fs

: new
    s" | marker |" evaluate
;
marker |

include runtests.fs
