LOCALWORDS  \ {

$10320  constant    uart0
$10330  constant    uart1

: uartreg
    :
    postpone literal
    postpone +
    postpone ;
;

\ 550 registers

0 uartreg rhr 0 uartreg thr 0 uartreg dll
1 uartreg ier               1 uartreg dlm
2 uartreg isr 2 uartreg fcr
3 uartreg lcr
4 uartreg mcr
5 uartreg lsr
6 uartreg msr
7 uartreg spr

\ 650 registers

2 uartreg efr
7 uartreg xoff2

\ 950 registers

1 uartreg asr
4 uartreg tfl
5 uartreg icr

: ix!  ( val reg uart -- )   \ Indexed Control Register store
    >r
    r@ spr c!
    r> icr c!
;

: ix@  ( reg uart -- val )   \ Indexed Control Register fetch
    >r
    0 r@ spr c!
    r@ icr c@ $40 or r@ icr c!
    r@ spr c!
    r@ icr c@
    0 r@ spr c!
    r@ icr c@ $40 invert and r@ icr c!
    r> drop
;

: acr!  ( val uart -- )
    >r $20 or $00 r> ix!
;

: 950{  ( uart -- )
    $80 swap acr!
;

: }950  ( uart -- )
    $00 swap acr!
;

: uemit  ( u uart -- )
    >r
    r@ 950{
    begin
        r@ tfl c@ 128 <
    until
    r@ }950
    r> rhr c!
;

: ukey? ( uart -- f )
    lsr c@ 1 and
;

: ukey ( uart -- c )
    >r
    begin
        r@ ukey?
    until
    r> rhr c@
;

: consume ( uart -- ) \ consume all pending characters from UART
    begin
        dup ukey?
    while
        dup ukey drop
    repeat
    drop
;

: u^c  ( uart -- ) \ ctrl-c handler. If special character pending, consume input and throw -28 
    >r
    r@ 950{
    r@ asr c@
    r@ }950
    $10 and   \ bit 4 means special character
    if
        r@ consume
        -28 ithrow
    then
    r> drop
;

: ^c
    uart0 u^c
    uart1 u^c
;

: speed  ( baud uart -- ) \ Set the speed of a UART in baud
    >r
    4 * 
    100000000 swap /

    dup 65536 < if
        4
    else
        2 rshift
        0
    then
    2 r@ ix!       \ TCR

    r@ lcr c@ swap
    $80 r@ lcr c!
    dup r@ dll c!
    8 rshift r@ dlm c!
    r@ lcr c!

    8 1 r@ ix!     \ CPR
        
    0 r@ fcr c!     \ FCR = 0
    2 r> mcr c!     \ MCR = 2
;

: line ( bits parity stopbits uart -- ) \ set line format
    >r
    >r >r       \ bits first
    5 -
    r> or       \ parity
    r>          \ stopbits
    2 = 4 and or
    r> lcr c!
;

: special ( efr uart -- )
    >r
    r@ lcr c@ $bf r@ lcr c! \ save lcr, set to $bf {
    swap r@ efr c!          \ 950 mode. Special Character Detection
    $03 r@ xoff2 c!         \ Special Character is ^C
    r@ lcr c!               \ } restore lcr
    $07 r@ fcr c!           \ Enable 128-byte FIFOs
    $20 r> ier c!           \ enable special character interrupt
;

: uart?  ( uart -- id1 id2 id3 )
    >r
    8 r@ ix@
    9 r@ ix@
    10 r> ix@
;

PUBLICWORDS \ }{

: uart0-key ( -- c ) \ receive character from UART 0
    uart0 ukey
;

: uart0-key? ( -- f ) \ is a key waiting on UART 0?
    uart0 ukey?
;

: uart0-emit ( c --  ) \ write character c to UART 0
    uart0 uemit
;

: uart0-setspeed ( baud -- ) \ Set the speed of UART 0 in baud
    uart0 speed
;

: uart0-setline ( bits parity stopbits -- ) \ Set the line format of UART 0
    uart0 line
;

: uart1-key ( -- c ) \ receive character from UART 1
    uart1 ukey
;

: uart1-key? ( -- f ) \ is a key waiting on UART 1?
    uart1 ukey?
;

: uart1-emit ( c --  ) \ write character c to UART 1
    uart1 uemit
;

: uart1-setspeed ( baud -- ) \ Set the speed of UART 1 in baud
    uart1 speed
;

: uart1-setline ( bits parity stopbits -- ) \ Set the line format of UART 1
    uart1 line
;

\ parity values for uart0-setline
$18 constant EVEN
$08 constant ODD
$00 constant NONE
: 8N1     8 NONE 1 ;

: uart1-init
    16 bit 18 bit or $10018 or!
    3 clockon drop
    $80 52 setpad
    $80 53 setpad
    115200 uart1-setspeed
    8N1 uart1-setline
    $10 uart1 special
;

: cold 
    cold

    \ wait for uart TX idle
    1 ms

    ['] uart0-key? is key?
    ['] uart0-key is key
    ['] uart0-emit is emit
    ['] ^c 13 set-interrupt

    $30 uart0 special
;

DONEWORDS    \ }
