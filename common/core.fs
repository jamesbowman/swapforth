\ #######   CORE   ############################################

: variable
    create 0 ,
;

: constant  : postpone literal postpone ; ;

: sgn ( u1 n1 -- n2 ) \ n2 is u1 with the sign of n1
    0< if negate then
;

\ Divide d1 by n1, giving the symmetric quotient n3 and the remainder
\ n2.
: sm/rem ( d1 n1 -- n2 n3 )
    2dup xor >r     \ combined sign, for quotient
    over >r         \ sign of dividend, for remainder
    abs >r dabs r>
    um/mod          ( remainder quotient )
    swap r> sgn     \ apply to remainder
    swap r> sgn     \ apply to quotient
;

\ Divide d1 by n1, giving the floored quotient n3 and the remainder n2.
\ Adapted from hForth
: fm/mod ( d1 n1 -- n2 n3 )
    dup >r 2dup xor >r
    >r dabs r@ abs
    um/mod
    r> 0< if
        swap negate swap
    then
    r> 0< if
        negate         \ negative quotient
        over if
            r@ rot - swap 1-
        then
    then
    r> drop
;

: */mod     >r m* r> sm/rem ;
: */        */mod nip ;

: spaces
    begin
        dup 0>
    while
        space 1-
   repeat
    drop
;

( Pictured numeric output                    JCB 08:06 07/18/14)
\ Adapted from hForth

\ "The size of the pictured numeric output string buffer shall
\ be at least (2*n) + 2 characters, where n is the number of
\ bits in a cell."
\
\ The size of the region identified by WORD shall be at least
\ 33 characters.

create BUF0
16 cells 2 + 33 max
allot here constant BUF

variable hld

: <#
    BUF hld !
;

: hold
    -1 hld +! hld @ c!
;

: sign
    0< if
        [char] - hold
    then
;

: #
    0 base @ um/mod >r base @ um/mod swap
    9 over < [ char A char 9 1 + - ] literal and +
    [char] 0 + hold r>
;

: #s
    begin
        #
        2dup d0=
    until
;

: #>
    2drop hld @ BUF over -
;

: d.r  ( d n -- )
    >r
    dup >r dabs <# #s r> sign #>
    r> over - spaces type
;

: d.  ( d -- )
    0 d.r space
;

: .  ( n -- )
    s>d d.
;

: u.  ( u -- )
    0 d.
;

: .r  ( n1 n2 -- )
    >r s>d r> d.r
;

: u.r  ( u n -- )
    0 swap d.r
;

( Memory operations                          JCB 18:02 05/31/15)

: move \ ( addr1 addr2 u -- )
    >r 2dup u< if
        r> cmove>
    else
        r> cmove
    then
;

: word
    begin
        source >r >in @ + c@ over =
        r> >in @ xor and
    while
        1 >in +!
    repeat

    parse
    dup BUF0 c!
    BUF0 1+ swap cmove
    BUF0
;
