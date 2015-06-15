variable abortmsg

: (abort")  ( x1 caddr u -- )
    swap if
        abortmsg ! -2 throw
    else
        drop
    then
;

: abort"
    postpone c"
    postpone (abort")
; immediate

