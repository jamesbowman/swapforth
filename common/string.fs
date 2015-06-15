\ #######   STRING   ##########################################
        
: blank 
    bl fill 
;       

: -trailing
    begin   
        2dup + 1- c@ bl =
        over and
    while   
        1-  
    repeat  
;

\ Search the string specified by c-addr1 u1 for the string
\ specified by c-addr2 u2. If flag is true, a match was found
\ at c-addr3 with u3 characters remaining. If flag is false
\ there was no match and c-addr3 is c-addr1 and u3 is u1.

: search ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 flag )
    dup 0= if   \ special-case zero-length search
        2drop true exit
    then

    2>r 2dup
    begin
        dup
    while
        2dup 2r@            ( c-addr1 u1 c-addr2 u2 )
        rot over min -rot   ( c-addr1 min_u1_u2 c-addr2 u2 )
        compare 0= if
            2swap 2drop 2r> 2drop true exit
        then
        1 /string
    repeat
    2drop 2r> 2drop
    false
;
