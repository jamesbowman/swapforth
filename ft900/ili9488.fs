defer gd2-spi-init
defer gd2-sel
defer gd2-unsel

include gd2.fs

66 constant PD#
65 constant DISP

: CS
    33 digitalWrite
;

36 constant DCX

: >DCX
    DCX digitalWrite
;

27 constant ILI9488_CLK
29 constant ILI9488_MOSI

: high
    1 swap digitalWrite
;

: low
    0 swap digitalWrite
;

: >ili ( u -- )
    8 0 do
        ILI9488_CLK low
        1 us
        dup 7 rshift ILI9488_MOSI digitalWrite
        ILI9488_CLK high
        1 us
        2*
    loop
    drop
;

: write_command
    0 CS
    0 >DCX
    >ili
    1 CS
;

: write_data
    0 CS
    1 >DCX
    >ili
    1 CS
;

: ili8 ( u -- u )
    8 0 do
        ILI9488_CLK low 1 us
        ILI9488_CLK high 1 us
        2*
        30 digitalRead 1 and +
    loop
;

: command32 ( u -- u )
    0 33 digitalWrite     \ HX8357 selected
    0 >DCX
    >ili
    ILI9488_CLK low 1 us
    ILI9488_CLK high 1 us
    1 >DCX
    0 ili8 ili8 ili8 ili8
    1 33 digitalWrite     \ HX8357 selected
;

: command8
    0 CS
    0 >DCX
    >ili
    1 >DCX
    0 ili8
    1 CS
;

: ili9488
    $E0 write_command     \  positive gamma control
    $00 write_data     
    $04 write_data 
    $0E write_data 
    $08 write_data 
    $17 write_data 
    $0A write_data 
    $40 write_data 
    $79 write_data 
    $4D write_data 
    $07 write_data 
    $0E write_data 
    $0A write_data 
    $1A write_data 
    $1D write_data 
    $0F write_data 

    $E1 write_command     \  Negative gamma control
    $00 write_data 
    $1B write_data 
    $1F write_data 
    $02 write_data 
    $10 write_data 
    $05 write_data 
    $32 write_data 
    $34 write_data 
    $43 write_data 
    $02 write_data 
    $0A write_data 
    $09 write_data 
    $33 write_data 
    $37 write_data 
    $0F write_data 

    $C0 write_command     \ power control 1
    $18 write_data 
    $16 write_data 

    $C1 write_command     \ power control 2
    $41 write_data 

    $C5 write_command     \ vcom control
    $00 write_data 
    $1E write_data        \ VCOM
    $80 write_data 

    $36 write_command     \ madctrl - memory access control
    $48 write_data        \ bgr connection and colomn address order

    $3A write_command     \ Interface Mode Control
    $66 write_data        \ 18BIT

    $B1 write_command     \ Frame rate 60HZ
    $B0 write_data 

    $E9 write_command     \ set image function
    $00 write_data        \ DB_EN off - 24 bit is off

    $F7 write_command     \ adjust control 3
    $A9 write_data 
    $51 write_data 
    $2C write_data 
    $82 write_data 

    $B0 write_command     \ Interface Mode Control
    $02 write_data        \ set DE,HS,VS,PCLK polarity

    $B6 write_command 

    $30 write_data        \ 30 set rgb
    $02 write_data        \ GS,SS
    $3B write_data 

    $2A write_command     \ colomn address set
    $00 write_data 
    $00 write_data 
    $01 write_data 
    $3F write_data 

    $2B write_command     \ Display function control
    $00 write_data 
    $00 write_data 
    $01 write_data 
    $DF write_data 

    $11 write_command     \ sleep out

    120 ms

    $29 write_command
;

: ili?
    ." ( " dup hex2. ." ) "
    command8 hex2.
;

: ili9488?
    cr
    $04 command32 .x space

    $09 command32
    dup .x
    cr 0 31 do                  i 3 .r -1 +loop
    cr 0 31 do dup i rshift 1 and 3 .r -1 +loop drop

    cr ." ILI9488 id1               " $da ili?
    cr ." ILI9488 id2               " $db ili?
    cr ." ILI9488 id3               " $dc ili?
    cr ." ILI9488 disp identy       " $04 ili?
    cr ." ILI9488 disp power mode   " $0a ili?
    cr ." ILI9488 mad ctrl          " $0b ili?
    cr ." ILI9488 pixel format      " $0c ili?
    cr ." ILI9488 disp signal mode  " $0e ili?
;

: sw-spi
    OUTPUT ILI9488_MOSI pinMode 1 ILI9488_MOSI digitalWrite     \ SPI
    OUTPUT ILI9488_CLK pinMode 1 ILI9488_CLK digitalWrite     \ SPI
    INPUT 30 pinMode
;

: ili-init
    sw-spi

    1 DISP digitalWrite
    1 ms
    0 DISP digitalWrite

    $01 write_command
    120 ms

    ili9488

    cr ili9488?

    1 CS
    spi-init
;

: GD.320x480
    329 GD.REG_HCYCLE GD.!
    6   GD.REG_HOFFSET GD.!
    320 GD.REG_HSIZE GD.!
    0   GD.REG_HSYNC0 GD.!
    3   GD.REG_HSYNC1 GD.!

    489 GD.REG_VCYCLE GD.!
    4   GD.REG_VOFFSET GD.!
    480 GD.REG_VSIZE GD.!
    0   GD.REG_VSYNC0 GD.!
    2   GD.REG_VSYNC1 GD.!

    1   GD.REG_CSPREAD GD.!
    1   GD.REG_DITHER GD.!
    2   GD.REG_SWIZZLE GD.!
    1   GD.REG_PCLK_POL GD.!
    4   GD.REG_PCLK GD.!
;

: GD.320x480
    400 GD.REG_HCYCLE GD.!
    40  GD.REG_HOFFSET GD.!
    0   GD.REG_HSYNC0 GD.!
    10  GD.REG_HSYNC1 GD.!
    320 GD.REG_HSIZE GD.!
    500 GD.REG_VCYCLE GD.!
    10  GD.REG_VOFFSET GD.!
    480 GD.REG_VSIZE GD.!
    0   GD.REG_VSYNC0 GD.!
    5   GD.REG_VSYNC1 GD.!
    2   GD.REG_SWIZZLE GD.!
    0   GD.REG_CSPREAD GD.!
    1   GD.REG_DITHER GD.!
    1   GD.REG_PCLK_POL GD.!
    GD.REG_FREQUENCY GD.@
    6000000 + 12000000 /
    GD.REG_PCLK GD.!
;

create fixcal
    -28913 ,
    -1001 ,
    25406329 ,
    -459 ,
    36315 ,
    -2951166 ,

: me800a-hv33r
    \ ." me800a-hv33r"
    GD.nocrystal
    GD.320x480

    $80 GD.REG_GPIO_DIR     GD.c!
    $80 GD.REG_GPIO         GD.c!
    1 GD.REG_ROTATE         GD.c!
    GD.REG_TOUCH_TRANSFORM_A 24 GD.cmd_memwrite
    fixcal 24 GD.supply
    GD.suspend ili-init GD.resume
;

( Board selection                            JCB 10:15 03/01/15)

: resetpin ( pin -- )
    OUTPUT over pinMode
    0 over digitalWrite
    1 ms
    1 swap digitalWrite
    200 ms
;

: 411-gd2-spi-init
    spi-init
    \ OUTPUT 18 pinMode 1 18 digitalWrite         \ DISP
    \                   0 18 digitalWrite         \ DISP
    \                   1 18 digitalWrite         \ DISP
    OUTPUT 33 pinMode 1 33 digitalWrite         \ CS1
    OUTPUT DCX pinMode 1 DCX digitalWrite
    OUTPUT 28 pinMode
    gd2-unsel
    PD# resetpin
    \ cr gd2-sel 0 spix hex2. 0 spix hex2. 0 spix hex2. gd2-unsel
;
: 28-sel       0 28 digitalWrite ;
: 28-unsel     1 28 digitalWrite ;

: pro43-gd2-spi-init
    spi-init
    OUTPUT 28 pinMode
    gd2-unsel
    32 resetpin
;

: board-411
    ['] 28-sel is gd2-sel
    ['] 28-unsel is gd2-unsel
    ['] 411-gd2-spi-init is gd2-spi-init
    ['] me800a-hv33r GD.setcustom
;

: board-pro43
    ['] 28-sel is gd2-sel
    ['] 28-unsel is gd2-unsel
    ['] pro43-gd2-spi-init is gd2-spi-init
    ['] ftdi-eval GD.setcustom
;

: i2c-probe ( addr -- f ) \ is device present
    i2c-reset
    i2c-start
    i2c-error 0=
    i2c-stop
;

: board-id
    i2c-init

    \ 411 and PRO43 have $34 and $A0-A7 on i2c1
    i2c1
    $34 i2c-probe
    $A8 $A0 do
        i i2c-probe and
    loop
    if
        i2c0
        \ The 411 board has the RTC at address DE
        $DE i2c-probe if
            board-411
        then
        $60 i2c-probe if
            board-pro43
        then
    then
    i2c0
;

\ board-id
board-411

: helloworld
    GD.init

    $000000 GD.ClearColorRGB# GD.Clear
    \ 0 0 $000000 320 320 $ffffff GD.cmd_gradient
    160  20 31 GD.OPT_CENTER s" Hello world" GD.cmd_text
    160 460 31 GD.OPT_CENTER s" Hello world" GD.cmd_text

    $ff0000 GD.ColorRGB#    160 160 31 GD.OPT_CENTER s" RED" GD.cmd_text
    $00ff00 GD.ColorRGB#    160 240 31 GD.OPT_CENTER s" GREEN" GD.cmd_text
    $0000ff GD.ColorRGB#    160 320 31 GD.OPT_CENTER s" BLUE" GD.cmd_text

    GD.swap
;

: x  \ attempt to talk to ILI9488
    OUTPUT DISP pinMode 0 DISP digitalWrite         \ DISP
    OUTPUT PD# pinMode 0 PD# digitalWrite           \ Hold FT800 in reset
    OUTPUT 28 pinMode 1 28 digitalWrite             \ FT800 not selected
    OUTPUT 33 pinMode
    OUTPUT 34 pinMode

    1 CS
    helloworld

    cr
    GD.REG_CLOCK GD.@
    1000 ms
    GD.REG_CLOCK GD.@
    swap - .
;

: getcal
    GD.init GD.calibrate
    6 0 do
        cr i cells GD.REG_TOUCH_TRANSFORM_A + GD.@ . ." ,"
    loop
;

\ GD.init $00ff00 GD.ClearColorRGB# GD.Clear GD.swap

OUTPUT DISP pinMode 0 DISP digitalWrite     \ DISP
OUTPUT PD# pinMode 0 PD# digitalWrite     \ Hold FT800 in reset
OUTPUT 28 pinMode 1 28 digitalWrite     \ FT800 not selected
OUTPUT 33 pinMode
OUTPUT 34 pinMode

1 CS

include screenshot.fs
