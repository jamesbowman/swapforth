\ Send a buffer as a sequence of run/literal pairs
\ a pair looks like:
\   #-to-repeat #-to-insert <literals>
\
\ The initial value at the start of the run is 0
\
variable tx

: send-length ( u -- )
    2/ 2/
    begin
        dup 254 >
    while
        255 -
        $ff emit
    repeat
    emit
;

: flush ( mode a -- mode )
    over if
        tx @ 2dup -         ( a tx u -- )
        dup send-length type
    else
        dup tx @ -
        send-length
    then
    tx !
    invert
;

: rlc
    2dup + >r       \ end-of-buffer
    over tx !
    0 0             ( mode prev )
    2swap
    bounds do
        i @ <>      ( mode cmp )
        over xor    ( mode ok )
        if
            i flush
        then
        i @         ( mode prev )
    4 +loop
    drop
    r> flush
    if
        0 send-length
    then
;

: send32
    pad !
    pad 4 type
;

hex
00302010    ( 00102410 )   constant    REG_SCREENSHOT_EN    \ Set to enable screenshot mode
00302014    ( 00102414 )   constant    REG_SCREENSHOT_Y     \ Y line register
00302018    ( 00102418 )   constant    REG_SCREENSHOT_START \ Screenshot start trigger
003020e8    ( 001024d8 )   constant    REG_SCREENSHOT_BUSY  \ Screenshot ready flags
00302174    ( 00102554 )   constant    REG_SCREENSHOT_READ  \ Set to enable readout
003c2000    ( 001c2000 )   constant    RAM_SCREENSHOT       \ Screenshot readout buffer
decimal

: GD.screenshot
    GD.finish
    1 REG_SCREENSHOT_EN GD.c!
    GD.REG_PCLK GD.@
    0 GD.REG_PCLK GD.c!
    cr ." !screenshot"
    GD.REG_HSIZE GD.@ send32 GD.REG_VSIZE GD.@ send32
    GD.REG_VSIZE GD.@ 0 do
        i REG_SCREENSHOT_Y GD.!
        1 REG_SCREENSHOT_START GD.c!
        begin
            REG_SCREENSHOT_BUSY dup GD.@
            swap cell+ GD.@ or 0=
        until
        1 REG_SCREENSHOT_READ GD.c!
        pad GD.REG_HSIZE GD.@ cells RAM_SCREENSHOT GD.move
        pad GD.REG_HSIZE GD.@ 4 * rlc \ type
        0 REG_SCREENSHOT_READ GD.c!
    loop
    0 REG_SCREENSHOT_EN GD.!
    GD.REG_PCLK GD.c!
    \ key [char] k <> 100 and throw
;
