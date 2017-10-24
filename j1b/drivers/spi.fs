( SPI driver for GD2                         JCB 13:38 06/09/15)

LOCALWORDS

11 constant MOSI
12 constant MISO
13 constant SCK

: xbit ( u n -- ) \ send bit n of u over SPI
    rshift MOSI io!
    1 SCK io!
    0 SCK io!
;

PUBLICWORDS

: spix ( u -- u )
    0
    8 0 do
        over 7 rshift MOSI io!
        SCK hi
        2* MISO io@ +
        SCK lo
        swap 2* swap
    loop
    nip
;

: spi>
    1 MOSI io!
    0 SCK io! 1 SCK io!  MISO io@  7 lshift
    0 SCK io! 1 SCK io!  MISO io@  6 lshift +
    0 SCK io! 1 SCK io!  MISO io@  5 lshift +
    0 SCK io! 1 SCK io!  MISO io@  4 lshift +
    0 SCK io! 1 SCK io!  MISO io@  3 lshift +
    0 SCK io! 1 SCK io!  MISO io@  2 lshift +
    0 SCK io! 1 SCK io!  MISO io@  1 lshift +
    0 SCK io! 1 SCK io!  MISO io@           +
;

: spi-init
    OUTPUT MOSI pinMode
    OUTPUT SCK pinMode
;

: >spi
    dup 7 xbit
    dup 6 xbit
    dup 5 xbit
    dup 4 xbit
    dup 3 xbit
    dup 2 xbit
    dup 1 xbit
        0 xbit
;

: blk>spi ( caddr u -- )
    bounds do
        i @
        dup >spi
        8 rshift dup >spi
        8 rshift dup >spi
        8 rshift >spi
    4 +loop
;

DONEWORDS
