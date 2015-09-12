LOCALWORDS

: freq
    $1010 io@
;

: clk@
    0 $1010 io!
    $1014 io@ $1018 io@
;

\ return time in 1/u of a second

: tu ( u -- d )
    clk@ rot freq m*/
;

PUBLICWORDS

: ms@   $101c io@ ;         \ in milliseconds, single prec
: us@   1000000 tu ;        \ in microseconds, double prec
: ns@   1000000000 tu ;     \ in nanoseconds, double prec

: ms
    s>d freq 1000 m*/
    clk@ d+
    begin
        2dup clk@ d<
    until
    2drop
;

DONEWORDS
