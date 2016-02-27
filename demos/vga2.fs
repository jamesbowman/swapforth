( Setup for Ken Boak's VGA shield, which uses an FT812 )

9  constant CS

: gd2-sel   0 CS io! ;
: gd2-unsel 1 CS io! ;
: gd2-spi-init
    OUTPUT CS pinMode
    gd2-unsel
    spi-init
;

include gd2.fs

\ H and Vsync parameters start at GD.REG_HCYCLE, VCYCLE
\ and are ordered: HCYCLE HOFFSET HSIZE HSYNC0 HSYNC1

: setsync ( visible sync back whole REG -- )
    20 GD.cmd_memwrite
    GD.c            \ CYCLE
    over + GD.c     \ OFFSET
    swap GD.c       \ SIZE
    0 GD.c          \ SYNC0
    GD.c            \ SYNC1
;

: hs GD.REG_HCYCLE setsync ;
: vs GD.REG_VCYCLE setsync ;

: pll ( pll -- ) \ set PLL clock multiplier 
    dup GD.pll GD.crystal
    13000000 * GD.REG_FREQUENCY GD.!
;

: pclk ( pclk -- ) \ common register settings for EVITA display
    0 GD.REG_CSPREAD GD.!
    0 GD.REG_SWIZZLE GD.!
    0 GD.REG_ROTATE GD.!
      GD.REG_PCLK GD.!
;

\ H/V timing parameters order: visible sync back whole

: res create , does> @ GD.setcustom ;
:noname 5 pll 1024 136 160 1344 hs 768 6 29 806 vs 1 pclk ;
:noname 3 pll  800 128  88 1056 hs 600 4 23 628 vs 1 pclk ;
:noname 4 pll  640  96  48  800 hs 480 2 33 542 vs 2 pclk ;
res 640x480  res 800x600  res 1024x768

1024x768        \ default resolution

: GD.calibrate ;    ( there is no touch screen )

: test-page
    GD.init

    0 34 GD.cmd_romfont

    begin
        0 0 $00ff00 1024 768 $ff0000 GD.cmd_gradient
        16 16 GD.SCISSORXY
        1024 32 - 768 32 - GD.SCISSORSIZE
        GD.Clear

        512 50 GD.SCISSORSIZE
        3 0 do
            256 i 100 * 484 + GD.SCISSORXY
            256 i 100 * 484 + $000000
            768 i 100 * 484 + $0000ff i 8 * lshift
            GD.cmd_gradient
        loop
        GD.RestoreContext

        512 186 150 0
        ms@ 1000 /mod 2>r
        r@ 3600 / 12 mod    ( hours )
        r@ 60 / 60 mod      ( minutes )
        r> 60 mod           ( seconds )
        r>                  ( ms )
        GD.cmd_clock 

        32 32 30 0
        GD.wh s>d <# #s 2drop 'x' hold s>d #s #>
        GD.cmd_text
        512 404 0 GD.OPT_CENTER s" Hello world" GD.cmd_text

        GD.swap
        GD.finish
    again
;

128 48 * 2* constant NB \ bytes in 1024x768 text mode

: test-vga
    GD.init

    0 GD.TEXTVGA 1024 768 GD.cmd_setbitmap

    GD.Clear
    1 0 GD.BlendFunc
    GD.BITMAPS GD.Begin
    0 0 0 0 GD.Vertex2ii
    GD.swap
    begin
        0 NB GD.cmd_memwrite
        NB 0 do
            random GD.c
        4 +loop
        1000 ms
    again
;

: .3 ( u -- ) \ print as 3-digit decimal
    s>d <# # # # '.' hold #s #> type space
;

: sync \ wait until REG_FRAMES changes
    GD.REG_FRAMES GD.c@
    begin
        dup GD.REG_FRAMES GD.c@ xor
    until
    drop
;

: report
    cr
    \ GD.@ .

    ." REG_ID              "
    GD.REG_ID GD.@ hex2. cr

    ." resolution          "
    GD.wh swap 0 .r 'x' emit . cr

    ." Measured core freq. "
    GD.REG_CLOCK GD.@
    1000 ms
    GD.REG_CLOCK GD.@
    swap - 1000 / .3
    ." MHz" cr

    ." Measured frame rate "
    sync ms@
    100 0 do sync loop
    ms@ swap -
    100000000 swap / .3
    ." Hz" cr
;
