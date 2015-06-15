: char+     1+ ;
: chars     ;

: abort     -1 throw ;

: '
    parse-name
    sfind
    0= -13 and throw
;

: [']
    ' postpone literal
; immediate

: char
    parse-name drop c@
;

: [char]
    char postpone literal
; immediate

: (
    [char] ) parse 2drop
; immediate

: else
    postpone ahead
    swap
    postpone then
; immediate

: while
    postpone if
    swap
; immediate

: repeat
     postpone again
     postpone then
; immediate
