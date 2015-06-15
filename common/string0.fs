: same? ( c-addr1 c-addr2 u -- -1|0|1 )
    bounds ?do
        i c@ over c@ - ?dup if
            0> 2* 1+
            nip unloop exit
        then
        1+
    loop
    drop 0
;

: compare
    rot 2dup swap - >r          \ ca1 ca2 u2 u1  r: u1-u2
    min same? ?dup
    if r> drop exit then
    r> dup if 0< 2* 1+ then ;
