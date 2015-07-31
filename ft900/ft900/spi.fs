\ 27 constant SCK         \ yellow
\ 28 constant SS          \ blue
\ 29 constant MOSI        \ red
\ 30 constant MISO        \ green
\ 
\ : spi-sel
\     0 SS digitalWrite
\ ;
\ 
\ : spi-unsel
\     1 SS digitalWrite
\ ;
\ 
\ : spi-init
\     INPUT   MISO pinMode
\     OUTPUT  SCK     pinMode
\     OUTPUT  MOSI    pinMode
\     OUTPUT  SS      pinMode
\     0 SCK digitalWrite
\     spi-unsel
\ ;
\ 
\ : spix  ( u - u )
\     8 0 do
\         dup 7 rshift MOSI digitalWrite
\         1 SCK digitalWrite
\         2*
\         MISO digitalRead 1 and or
\         0 SCK digitalWrite
\     loop
\     $ff and
\ ;

LOCALWORDS  \ {

$102a0
io-32 spcr
io-32 spsr
io-32 spdr
io-32 sscr
io-32 sfcr          \ FIFO control
io-32 stfcr         \ transfer format control
io-32 _             \ alt data, unused
io-32 rx_fifo_count \ RX FIFO count
drop

PUBLICWORDS \ }{

: spi-init ( -- ) \ initialize the SPI module
    7 clockon if
    then
        $d1 spcr !
        $a7 sfcr !
        $00 stfcr !

        \ Enable pads 
        \ 27 SPIM SCK
        \ 29 SPIM MOSI
        \ 30 SPIN MISO

        $40 27 setpad
        $40 29 setpad
        $40 30 setpad
;

: spix
    spdr !
    begin spsr @ $0c and $0c = until
    spdr @
;

: >spi ( u -- ) \ transmit byte u over SPI
    spix drop
;

: spi> ( -- u ) \ receive byte u from SPI
    0 spix
;

: l>spi ( u -- ) \ transmit little-endian 32-bit u over SPI
    dup spdr !
    8 rshift   dup spdr !
    8 rshift   dup spdr !
    8 rshift   spdr !
    begin spsr @ $0c and $0c = until
    spdr @ drop
    spdr @ drop
    spdr @ drop
    spdr @ drop
;

defer gd2-spi-init
defer gd2-sel
defer gd2-unsel

\ Set the SPI speed.
\ The value is a clock divider, one of:
\ 4,8,16,32,64,128,256,512

: spi-speed ( u -- )
    case
    4   of $00 endof
    8   of $01 endof
    16  of $02 endof
    32  of $03 endof
    64  of $20 endof
    128 of $21 endof
    256 of $22 endof
    512 of $23 endof
        -200 throw
    endcase

    spcr c@
    [ $23 invert ] literal and or
    spcr c!
;

code txempty
    begin
      spsr cc lda,
    2 2 0 jmpc,
    return,
end-code

: unroll64  ( caddr u -- caddr1 u1  caddr2 u2 )
    2dup dup 63 invert and /string
    2swap
    63 invert and
;

: blk>spi
    bounds
    do
        i @ l>spi
    4 +loop
;

\ Multibit (that is, dual or quad) mode versions
\ of >spi and spi>

: m>spi
    stfcr @ $fb and stfcr !
    spix drop
;

: mspi>
    stfcr @ $04 or stfcr !
    0 spix
;

: mblk>spi  ( caddr u -- )
    unroll64
    bounds ?do
        spdr i 64
        txempty
        streamout.b
    64 +loop
    txempty
    dup if
        spdr -rot streamout.b
        txempty
    else
        2drop
    then
;

: multimode
    ['] m>spi is >spi
    ['] mspi> is spi>
    ['] mblk>spi is blk>spi
;

: spi-dual  \ Enter SPI dual mode
    $40 31 setpad
    stfcr @ 1 or stfcr !
    multimode
;

: spi-quad  \ Enter SPI quad mode
    $40 31 setpad
    $40 32 setpad
    stfcr @ 2 or stfcr !
    multimode
;

code l>spi
    r0 spdr sta,
    8 # r0 r0 lshr,
    r0 spdr sta,
    8 # r0 r0 lshr,
    r0 spdr sta,
    8 # r0 r0 lshr,
    r0 spdr sta,

    begin
      spsr cc lda,
    dup 2 2 0 jmpc,
        3 2 0 jmpc,

    spdr cc lda,
    spdr cc lda,
    spdr cc lda,
    spdr cc lda,

    ' drop jmp,
end-code


\ Not worth it - SPI 32-bit mode
\
\ : blk>spi  ( caddr u -- )
\     $82 stfcr !
\     bounds do
\         spdr i 256
\         txempty
\         streamout
\     256 +loop
\     txempty
\     $02 stfcr !
\ ;

DONEWORDS    \ }
