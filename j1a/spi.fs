#bye
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
        $2000 io@ 4 and +       \ read MISO, accumulate
    loop
    2/ 2/
;

: >spi      spix drop ;
: spi>      0 spix ;

cr
$9e >spi
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
spi> .x
idle
cr
