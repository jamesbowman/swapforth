( ALL-MEMORY DUMP                            JCB 16:34 06/07/15)

: serialize \ print out all of program memory as base-36 cells
    base @
    #36 base !
    32768 0 do
        i @ .
    4 +loop
    base !
;
