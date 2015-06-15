LOCALWORDS

: freq
    $1010 io@
;

: clk@
    0 $1010 io!
    $1014 io@ $1018 io@
;

: tu ( u -- d ) \ return time in 1/u of a second
    clk@ rot freq m*/
;

PUBLICWORDS

: ms@   1000 tu d>s ;
: us@   1000000 tu ;
: ns@   1000000000 tu ;

: ms
    s>d freq 1000 m*/
    clk@ d+
    begin
        2dup clk@ d<
    until
    2drop
;

DONEWORDS
