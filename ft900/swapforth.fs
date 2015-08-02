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

\ stage1.fs contains everything up to the optimizer
\ compile it once, so we have a first-stage optimizer
\ then recompile 'for real'.
\ This means that everything in stage1.fs is built
\ optimized.

marker --base--

$8000 dp !
$20000 cp !

include stage1.fs
--base--
include stage1.fs

include localwords.fs
include float1.fs
include float2.fs

include facilityext.fs
defer key?

include ft900/dis.fs

\ #############################################################
depth throw

only forth definitions

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
include memory.fs
include comus.fs
include mini-oof.fs

include ft900/uart.fs

: new
    s" | marker |" evaluate
;
marker |

\ include runtests.fs
