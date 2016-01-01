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

:noname
    GD.crystal
    1344    GD.REG_HCYCLE GD.!
    184     GD.REG_HOFFSET GD.!
    1024    GD.REG_HSIZE GD.!
    0       GD.REG_HSYNC0 GD.!
    24      GD.REG_HSYNC1 GD.!

    806     GD.REG_VCYCLE GD.!
    35      GD.REG_VOFFSET GD.!
    768     GD.REG_VSIZE GD.!
    0       GD.REG_VSYNC0 GD.!
    6       GD.REG_VSYNC1 GD.!
    0       GD.REG_CSPREAD GD.!
    0       GD.REG_SWIZZLE GD.!
    0       GD.REG_ROTATE GD.!
    0       GD.REG_DITHER GD.!
    0       GD.REG_PCLK_POL GD.!
    1       GD.REG_PCLK GD.!
; GD.setcustom

: GD.calibrate ;    ( there is no touch screen )

: testpage
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

        512 404 0 GD.OPT_CENTER s" Hello world" GD.cmd_text

        GD.swap
        GD.finish
    again
;
