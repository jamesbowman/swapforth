LOCALWORDS      \ {

: interrupt ( u1 -- u2 )
    3 cells * $94 +
;

PUBLICWORDS     \ }{

: interrupts?  ( -- ) \ display the current interrupt vector table
    32 0 do
        cr
        i 2 u.r space
        i interrupt pm@ .xt
    loop
;

: set-interrupt ( xt u -- ) \ Set interrupt vector u to execute xt
    interrupt >r
    r@ pm@ $fff00000 and or
    r> pm!
;

: interrupt-master ( u0 -- u1 ) \ Set the interrupt master control to u0. u1 is its previous value
    0= $80 and
    $100e3 atomic-swap
    $80 and 0=
;

defer hook-1khz  ' noop is hook-1khz

LOCALWORDS  \ {

$10340 constant timer_control_0
$10341 constant timer_control_1
$10342 constant timer_control_2
$10343 constant timer_control_3
$10344 constant timer_control_4
$10345 constant timer_int
$10346 constant timer_select
$10347 constant timer_wdg
$10348 constant timer_write_ls
$10349 constant timer_write_ms
$1034a constant timer_presc_ls
$1034b constant timer_presc_ms
$1034c constant timer_read_ls
$1034d constant timer_read_ms

\ Set up timer0 to generate interrupt every 65536 clocks,
\ which is once every 655360 ns, or every 655.36 us.

0 0 create _ns , ,

: ticker
    timer_int c@ $55 and
    _ns 2@ 655360 m+ _ns 2!
    timer_int c@ or timer_int c!
    hook-1khz
;

: timer-init    \ initialize timer unit
    3 timer_control_0 c!
    2 timer_control_0 c!
    $10 timer_control_3 c!
    $02 timer_int c!
    ['] ticker 17 set-interrupt

    $ff timer_write_ls c!
    $ff timer_write_ms c!

    $01 timer_control_4 c!
    $01 timer_control_1 c!
;

PUBLICWORDS \ }{

: ns@ ( -- d. ) \ d is the number of nanoseconds since system startup
    begin
        timer_read_ms c@ dup >r
        8 lshift
        timer_read_ls c@
        _ns 2@
        r> timer_read_ms c@ <>
    while
        2drop 2drop
    repeat
    2swap + 10 * m+
;

: m/    ( ud1 u -- ud2 ) \ Divide ud1 by u, giving the quotient ud2
    0 swap
    dup >r
    um/mod -rot r> um/mod nip swap
;

: us@  ( -- d. ) \ d is the number of microseconds since system startup
    ns@ 1000 m/
;

: ms@  ( -- u ) \ u is the number of milliseconds since system startup
    ns@ 1000000 um/mod nip
;

: .ms
    0 <# # # # [char] . hold #s #>
    11 rtype space
;

code ns  ( u -- )  \ delay at least u ns
    \ call to get here:       10 ns
    80 # r0 cc sub,         \ 10 ns
    begin
        20 # cc cc sub,
    31 2 0 jmpc,
    ' drop jmp,             \ 40 ns
end-code

: us  ( u -- )  \ delay at least u microseconds
    \ each iteration below takes 20ns.
    \ so multiply by 50
    50 * 0 do loop
;

\ #######   FACILITY EXT   ####################################

: ms ( u -- )
    \ ms@ negate   ( u -t0 )
    \ begin
    \     2dup ms@ + <
    \ until
    \ 2drop
    1000 * us
;

: cold
    timer-init
    1 interrupt-master drop
;

DONEWORDS    \ }

