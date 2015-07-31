LOCALWORDS      \ {

$10300
io-8 SA         \ Slave Address
io-8 SRCR       \ Status / Control
io-8 BUF        \ Data
io-8 TP         \ Time Period
1+  \ io-8 BL   \ FIFO Mode Byte Length
io-8 IE         \ Interrupt Enable
io-8 PEND       \ FIFO Mode Interrupt Enable
io-8 FIFO       \ FIFO Data Register
io-8 TRIG       \ Trigger
drop

: cmd
    \ cr dup .
    SRCR c!
    begin
        SRCR c@
        \ dup .
        1 and 0=
    until
;

PUBLICWORDS     \ {

: i2c0 ( -- ) \ use I2C port 0
    $40 44 setpad
    $40 45 setpad
    29 bit invert $10018 and!
;

: i2c1 ( -- ) \ use I2C port 1
    $40 46 setpad
    $40 47 setpad
    29 bit $10018 or!
;

: i2c-init ( -- ) \ initialize the I2C module and select I2C port 0
    9 clockon drop
    $80 cmd
    127 TP c!
    i2c0
;

: i2c-start ( devaddr -- ) \ send an I2C start symbol
    SA c!
    $21 cmd
;

: i2c-restart ( devaddr -- ) \ send an I2C restart symbol
    SA c!
    $23 cmd
;

: i2c-tx ( u -- ) \ transmit a byte over I2C
    BUF c!
    $01 cmd
;

: i2c-rx    ( -- u ) \ receive a byte over I2C
    $09 cmd
    BUF c@
;

: i2c-rx-last  ( -- u ) \ receive a byte over i2c, and respond with NAK
    $01 cmd
    BUF c@
;

: i2c-stop  ( -- )  \ send an I2C stop symbol
    $04 cmd
;

: i2c-rx16be  ( -- x ) \ receive a 16-bit big-endian value
    i2c-rx 8 lshift
    i2c-rx or
;

: i2c-error ( -- u ) \ u is non-zero if the I2C bus has detected an error
    SRCR c@
    $06 and
;

: i2c-reset ( -- ) \ reset all slaves by generating 9 I2C clocks, then a STOP
    $41 cmd
;

: i2c? ( -- ) \ scan the I2C bus for devices
    cr ." I2C device scan:"
    0
    $100 $00 do
        i 15 and 0= if cr then
        i hex2.

        i2c-reset
        i i2c-start
        i2c-error
        if space else 1+ [char] Y emit then
        space
        i2c-stop
    2 +loop
    cr . ." responses detected"
;

DONEWORDS       \ }
