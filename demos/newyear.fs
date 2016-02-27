include screenshot.fs

160 constant NSPARKS

GD.init

\ 0 64 64 * GD.cmd_memwrite
\ include star.fs
\ 0 GD.L8 64 64 GD.cmd_setbitmap
\ $0000ff GD.ClearColorRGB#
\ GD.Clear
\ GD.BITMAPS GD.Begin
\ 100 100 31 64 GD.Vertex2ii
\ 100 200 0 0 GD.Vertex2ii
\ GD.swap

: srandom ( n -- x ) dup 2* randrange - ;

object class
    1 cells var x
    1 cells var y
    1 cells var dx
    1 cells var dy
    1 cells var age
    method park         \ 
    method born         \ randomize position, velocity
    method move         \ compute new position
    method draw         \ draw self
end-class spark

: rr ( a b -- u ) over - randrange + ;

:noname ( dx dy x -- )
    >r
    -8000 r@ x !
    16 768 * r@ y !
    0 r@ dx !
    0 r@ dy !
    999 r@ age !
    r> drop
; spark defines park

:noname ( dx dy x -- )
    >r
    r@ x !
    -3 3 rr + r@ dx !
    -230 r@ dy !
    768 16 * -16 16 rr + r@ y !
    0 8 rr r@ age !
    r> drop
; spark defines born

:noname
    >r
    r@ x @
    r@ y @ GD.Vertex2f
    r> drop
; spark defines draw

: lin ( x x0 x255 )
    over - >r
    -
    255 r> */
    0 max 255 min
;

:noname
    >r
    r@ age @ 60 = if
        -50 50 rr r@ dx +!
        -30 50 rr r@ dy +!
    then
    r@ dx @ r@ x +!
    r@ dy @ r@ y +!
    3 r@ dy +!
    1 r@ age +!
    r> drop
; spark defines move

\ create bb NSPARKS cells allot
\ : b[] ( u -- a ) cells bb + @ ;
\ 
\ :noname
\     NSPARKS 0 do
\         spark anew
\         i cells bb + !
\     loop
\ ; execute

:noname
    NSPARKS 0 do
        spark anew drop
    loop
;
create bb execute

: b[] ( u -- a ) spark @ * bb + ;

: kind ( color i )
    b[] age @ dup
    2* 80 max GD.PointSize
    160 120 lin GD.ColorA
    GD.ColorRGB#
;

: x
    NSPARKS 0 do
        i b[] park
    loop

    0 34 GD.cmd_romfont

    GD.REG_FRAMES GD.@
    6000 0 do
        i 40 mod 0= if
            -16 16 rr  1024 16 * randrange
            i NSPARKS mod dup 40 + swap do
                2dup i b[] born
            loop
            2drop
        then
        GD.Clear

        $808080 GD.ColorRGB#
        512 200 0 GD.OPT_CENTER s" HAPPY" GD.cmd_text
        512 300 0 GD.OPT_CENTER s" NEW" GD.cmd_text
        512 400 0 GD.OPT_CENTER s" YEAR" GD.cmd_text
        512 500 0 GD.OPT_CENTER s" 2016" GD.cmd_text

        GD.SRC_ALPHA 1 GD.BlendFunc
        GD.POINTS GD.Begin
        NSPARKS 0 do
            i case
            0   of $f08040 i kind endof
            40  of $80f040 i kind endof
            80  of $8040f0 i kind endof
            120 of $4080f0 i kind endof
            endcase
            i b[] dup move draw
        loop

        GD.swap
        \ i 1 and if GD.screenshot then
    loop
    GD.finish GD.REG_FRAMES GD.@ swap - .
;
