: roll
    ?dup if
        swap >r
        1- recurse
        r> swap
    then
;

: pick
    ?dup if
        swap >r
        1- recurse
        r> swap
    else
        dup
    then
;
