LOCALWORDS
PUBLICWORDS

0 constant INPUT
1 constant OUTPUT

: pinMode
    $100 + io!
;

: digitalRead ( pin -- 0 | 1 ) \ read from pin
    io@
;

: digitalWrite ( b pin -- ) \ write the low bit of b to pin
    io!
;

: throb ( pin -- ) \ output a fast square wave on pin
    OUTPUT over pinMode
    begin
        0 over io!
        1 over io!
    again
;

: lo 0 swap io! ;
: hi 1 swap io! ;

DONEWORDS
