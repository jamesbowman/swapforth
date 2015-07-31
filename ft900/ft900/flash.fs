\ For the flash, a sector is 4K bytes

LOCALWORDS  \ {

\ First the CRC16 implementation

create fwdtab
    $0000 , $cc01 , $d801 , $1400 , $f001 , $3c00 , $2800 , $e401 ,
    $a001 , $6c00 , $7800 , $b401 , $5000 , $9c01 , $8801 , $4400 ,

create revtab
    $0000 , $4003 , $8006 , $c005 , $400f , $000c , $c009 , $800a ,
    $801e , $c01d , $0018 , $401b , $c011 , $8012 , $4017 , $0014 ,

: reflect
    15 flip
;

: fcrc4  ( crc u -- crc' )
    over xor
    15 and
    cells fwdtab + @
    swap 4 rshift xor
;

: fcrc8 ( crc u -- crc' )
    tuck fcrc4
    swap 4 rshift fcrc4
;

: fcrcs ( crc c-addr u -- crc' )
    bounds ?do
        i c@ fcrc8
    loop
;

: rcrc4  ( crc u -- crc' )
    over 12 rshift cells revtab + @ xor
    swap 4 lshift xor
    $ffff and
;

: rcrc8  ( crc u -- crc' )
    tuck 4 rshift rcrc4
    swap $f and rcrc4
;


$ffff constant crc-start

: crc-end  ( crc -- final-crc )
    crc-start xor reflect
;

: crc-16  ( c-addr u -- crc )
    crc-start -rot
    fcrcs
    crc-end
;

: pmcrc ( c-addr u -- crc ) \ Compute CRC of PM
    crc-start -rot
    bounds do
        i pmc@ fcrc8
    loop
    crc-end
;

$3effe constant fix_pos

: setcrc
    \ calculate crc register at position fix_pos
    0 fix_pos pmcrc crc-end >r

    \ calculate crc backwards to fix_pos, beginning at the end
    crc-start
    r@ 8 rshift rcrc8
    r> $ff and rcrc8

    16 lshift $0403 or
    fix_pos pm!
;

\ T{ $abcd $69 rcrc8 -> $8cf2 }T
\ T{ s" 123456789" crc-16 -> $132d }T

\ Controller's register definitions
$10800
3 io-n  rsaddr
3 io-n  fsaddr
3 io-n  blength
io-8    command
1+
io-8    semaphore
io-8    config
io-8    status
io-8    crcl
1+
drop

: cmd ( x -- )      \ issue command x
    \ status bit 6 means unit busy
    \ status bit 1 means flash busy
    begin
        status c@ $41 and 0=
    until
    command c!
;

: wecmd ( x -- )    \ set write-enable (WE) then command x
    $06 cmd
    cmd
;

: 24!   ( u a -- )  \ write u to little-endian 3-bytes at a
    3 0 do
        2dup c!
        1+ swap 8 rshift swap
    loop
    2drop
;

: lock
    semaphore c@ if
        abort" Cannot lock flash controller"
    then

    3 config c!
;

: unlock
    1 semaphore c!
;

PUBLICWORDS \ }{

marker flash-test
    
    t{ 0 pad ! -> }t
    t{ $12345678 pad 24! -> }t
    t{ pad c@ pad 1+ c@ pad 2 + c@ pad 3 + c@ -> $78 $56 $34 0 }t

flash-test

: flash@  ( flashaddr c-addr2 u -- ) \ fetch block from flash
    lock
    1-        blength 24!
    2 rshift  rsaddr 24!
              fsaddr 24!
    $fc cmd       \ from FLASH to RAM
    $05 cmd       \ wait for finish
    unlock
;

\ store block to flash from either PM or RAM
\ cmd is $f0 if the source is in program memory
\        $f8 is the source is in RAM
: wsetup  ( c-addr2 flashaddr u - ) \ flash write setup
    1-        blength 24!
              fsaddr 24!
    2 rshift  rsaddr 24!

    $20 wecmd   \ erase sector
;

: flash! ( c-addr2 flashaddr u - ) \ store block to flash
    lock
    wsetup
    $f8 wecmd   \ write sector from PM
    $05 cmd     \ wait for finish
    unlock
;

: burn ( -- ) \ write the current program to flash
    lock
    cr ." Starting flash write - do not interrupt!"
    commit drop setcrc
    $3f000 0 do
        cr i .
        i i 4096 wsetup
        $f0 wecmd   \ write sector from PM
        $05 cmd     \ wait for finish
    4096 +loop
    cr ." Finished"
    unlock
;

: reboot ( -- ) \ hard reset the system
    lock
    0 rsaddr 24!
    0 fsaddr 24!
    $1 blength 24!
    $fe wecmd   \ copy 1 byte from flash to RAM, then reboot
    begin again
;

: flashcrc
    lock
    crcl count
    swap c@ 256 * or
    unlock
;

: x
    cr ." Low          CRC: " 0 $3effc pmcrc .x
    cr ." Low          CRC: " 0 $3effe pmcrc .x
    cr ." Low  signed  CRC: " 0 $3f000 pmcrc .x
    cr ." Top          CRC: " $3f000 $1000 pmcrc .x
    cr ." Full         CRC: " 0 $40000 pmcrc .x
;

DONEWORDS    \ }
