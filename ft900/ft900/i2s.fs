42 constant mutepin

\ The WM8731 control interface is a write-only i2c
\
\ Internally, it has 16-bit registers, but it
\ only allows a single byte write in each i2c
\ transaction.
\

: wm! ( val reg -- )
                    \ cr
    $34 i2c-start   \ i2c-error .
    i2c-tx          \ i2c-error .
    i2c-tx          \ i2c-error .
    i2c-stop        \ i2c-error .
;

: wm ( val reg -- ) \ reg is 0-15, val 0-511
    2* over 8 rshift or
    $34 i2c-start   \ i2c-error .
    i2c-tx          \ i2c-error .
    i2c-tx          \ i2c-error .
    i2c-stop        \ i2c-error .
;

0 constant SIDEATT
0 constant SIDETONE
1 constant DACSEL
0 constant BYPASS
0 constant INSEL
0 constant MUTEMIC
0 constant MICBOOST

: wm8743-init
    i2c1

    0 15 wm     \ RESET

    $00 \ turn everything on
    6 wm \ power reduction register
    
    16
    0 wm \ left in setup register
    
    16
    1 wm \ right in setup register
    
    90
    2 wm \ left headphone out register
    
    90
    3 wm \ right headphone out register
    
    0
    5 wm \ digital audio path configuration
    
    SIDEATT     6 lshift
    SIDETONE    5 lshift or
    DACSEL      4 lshift or
    BYPASS      3 lshift or
    INSEL       2 lshift or
    MUTEMIC     1 lshift or
    MICBOOST             or
    4 wm \ analog audio pathway configuration

    $02 7 wm \ digital audio interface format

;

\ Controller's register definitions
$10350
io-16 cr1
io-16 cr2
io-16 irqen
io-16 irqpend
io-16 rwdata
2+
io-16 rxcount
io-16 txcount
drop

: i2s-init
    67 60 do
        $40 i setpad
    loop

    $20 cr1 w!
    $07 cr2 w!
;

: i2s?
    txcount uw@ .
;

pi 2.e f* fconstant 2pi

: warray create 2* allot does> swap 2* + ;

4096 warray wave

variable phi
variable volume 128 volume !
variable evol

: wave@ ( -- )
    \ phi @ 0< if -32768 else 32767 then exit

    phi @ 20 rshift wave w@
    phi @ $100000 + 20 rshift wave w@             ( w w+1 )
    over -
    dup >r abs
    phi @
    12 lshift um* nip
    r> 0< if negate then +
;

: inc ( freq -- inc )
    $100000000. rot 192000 m*/ drop
;

: unmute
    1 mutepin digitalWrite
;

: mute
    0 mutepin digitalWrite
;

: feedms ( inc -- inc ) \ feed 1 ms of audio to i2s
    begin
        txcount uw@ [ 1008 192 2* - ] literal <
    until
    192 0 do
        wave@
        evol @ * 8 rshift
        dup rwdata w! rwdata w!
        dup phi +!
    loop
;

: feed10ms ( inc -- inc )
    10 0 do
        feedms
    loop
;

: ibeep ( inc ms -- )
    >r
    evol off
    feed10ms

    unmute

    feed10ms

    volume @ 0 ?do
        feedms
        1 evol +!
    loop

    r> 0 do
        feedms
    loop

    volume @ 0 ?do
        -1 evol +!
        feedms
    loop

    feed10ms
    mute
    drop
;

: beep ( ms freq )
    $01 9 wm \ active control
    inc swap ibeep
    $00 9 wm \ active control
;

: y
    0 phi !
    cr
    1000 0 do
        ." sample "
        $100000000. i 1000 m*/ drop
        phi ! wave@ .
        cr
    loop
;

: b us@
    1000 0 do
        wave@ drop
    loop
    us@ 2swap d- d>s .ms
;

: dog-cold
    OUTPUT mutepin pinMode mute

    i2c-init wm8743-init

    1 clockon drop
    i2s-init

    1008 0 do
        0 rwdata w!
    loop

    \ 44100: 22.5792 clk input, 32fs, divide by 16
    $003 cr2 w!      \ MCLK:/1 BCLK:/16
    $41 cr1 w!      \ 16-bit, 16 BLK cycles, MasterMode, IsMaster22, TX enable
    $3c 8 wm

    \ 100 0 do
    \     cr i2s?
    \ loop
    \ exit

    4096 0 do
        i s>f 4096.0e f/ 2pi f*  \ theta
        fsin 32767e f* f>s      \ wave
        i wave w!
    loop
;

: cold
    cold
    dog-cold
;

: smoke
    1 volume !
    50 4000 beep
    128 volume !
;

: r 5000 5000 randrange 22000 + beep ;
: x100 100 0 do r loop ;

: blink
    OUTPUT over pinMode
    begin
        0 over digitalWrite
        1 over digitalWrite
    again
;
