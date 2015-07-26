\ Micron N25Q032A SPI flash driver

\ Uses port $0008 bits:
\   bit 0       CS
\   bit 1       MOSI
\   bit 2       SCK
\ and port $2000:
\   bit 2       MISO
\

new

: idle
    1 8 io!
;

: spix
    8 lshift
    8 0 do
        dup 0< 2 and            \ extract MS bit
        dup 8 io!               \ lower SCK, update MOSI
        4 + 8 io!               \ raise SCK
        2*                      \ next bit
        $2000 io@ 2/ 2/ 1 and + \ read MISO into lo bit
    loop
;

cr
$9e spix drop
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
$00 spix .x
idle
cr
