SwapForth on j1a
================

This is a 16-bit version of SwapForth,
intended as an interactive Forth system using very little logic and RAM.
See below for exactly *how* little.

Running the binary
------------------

After installing the
[icestorm](http://www.clifford.at/icestorm/)
tools, you can run on a
[Lattice iCEstick](http://www.latticesemi.com/icestick)
like this

    iceprog icestorm/j1a.bin
    PYTHONPATH=../shell:$PYTHONPATH python shell.py -h /dev/ttyUSB0 -p ../common/

(where `/dev/ttyUSB0` is the appropriate port your iCEstick was assigned).

You should get something like

    Contacting... established
    Loaded 196 words
    >

And you can now try the usual Forth things, e.g.

    1 2 + .
    words

There is a fairly complete 
[core ANS-compatible Forth system](http://forth.sourceforge.net/std/dpans/dpans6.htm)
running on the board, including a compiler.

Some demos
----------

You can control the five on-board LEDs

    $00 leds
    $1f leds

and to make them blink

    : blink
      32 0 do
        i leds
        100 ms
      loop
    ;
    blink

There is an
[Easter date calculator](http://www.wilbaden.com/neil_bawd/easter.txt).

    new
    #include ../demos/easter.fs
    
Now you can do

    >2015 .easter
    2015 April 5   ok

Or even

    >: 20easters
    +  2035 2015 do
    +    cr i .easter
    +  loop
    +;
     ok
    >20easters

    2015 April 5 
    2016 March 27 
    2017 April 16 
    2018 April 1 
    2019 April 21 
    2020 April 12 
    2021 April 4 
    2022 April 17 
    2023 April 9 
    2024 March 31 
    2025 April 20 
    2026 April 5 
    2027 March 28 
    2028 April 16 
    2029 April 1 
    2030 April 21 
    2031 April 13 
    2032 March 28 
    2033 April 17 
    2034 April 9   ok

Building from Scratch
---------------------

After installing the icestorm tools, run

    make -C icestorm

this will produce `j1a.bin` - but it only contains the very bare-bones system;
the rest of SwapForth still needs to be compiled.
Load `j1a.bin` as above, and on connecting on the board you should see

    Contacting... established
    Loaded 127 words

Compile the rest of SwapForth and write the finished executable by 

    #include swapforth.fs
    #flash build/nuc.hex
    #bye

Now run `make` again - this compiles an FPGA image with the complete code base built-in.

Resources
---------

The FPGA on the iCEstick has 8Kbytes of RAM.
SwapForth's base system takes up about 5Kbytes of this, leaving about 3K for your use.

The j1a and its current peripherals (LEDs, uart) take 1162 of the available 1280 logic cells on the
iCE40 HX1K. So there is room for some more peripherals.
