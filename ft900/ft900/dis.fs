\ #######   DISASSEMBLER   ####################################

LOCALWORDS  \ {

decimal


: dis-hex5
    base @ >r
    0 hex <# # # # # # #> type
    r> base !
;

: dis-hex8
    base @ >r
    0 hex <# # # # # # # # # #> type
    r> base !
;

: .8
    6 spaces
    tuck
    type space
    7 swap - spaces
;

: 8"
    postpone s"
    postpone .8
; immediate

create dws
    char b c,
    char w c,
    char l c,

: .dw ( u1 c-addr u2 -- u1 ) \ display opcode with .bwl suffix
    6 spaces
    tuck type       ( u1 u2 )
    [char] . emit
    over 25 rshift 3 and dws + c@ emit
    5 swap - spaces space
;

: .signed ( n u -- ) \ print n as a signed decimal u-bit number
    32 swap -
    tuck lshift swap
    0 do 2/ loop
    decimal 0 .r
;

: dis-r ( u -- )
    31 and case 
        27 of ." dsp" endof
        30 of ." cc" endof
        31 of ." sp" endof
        dup [char] r emit decimal 0 u.r
    endcase
;

\ These are field names from the FT32 programmer's manual

: dis-rd ( u -- u )
    dup 20 rshift dis-r
;

: dis-r1 ( u -- u )
    dup 15 rshift dis-r
;

: dis-k8 ( u -- u)
    dup 8 .signed
;

: dis-k20 ( u -- u)
    dup 20 .signed
;

: comma
    [char] , emit
;

: dis-rimm ( u -- u )
    dup 4 rshift
    dup 1024 and if
        10 .signed
    else
        dis-r
    then
;

: dis-aluop ( u -- u )
    dup 15 and 5 *
    s" add  ror  sub  ldl  and  or   xor  xnor ashl lshr ashr bins bextsbextuflip ?????" drop
    + 5 .8
;

: dis-cmpop ( u -- u )
    dup 15 and 5 *
    s" addcc     cmp       tst                                                         " drop
    + 5 -trailing .dw
;

: dis-jmpcall ( u -- u )
    dup 20 rshift 3 and 3 = if
        dup 18 rshift 1 and if
            8" call"
        else
            8" jmp"
        then
    else
        8" jmpc"
        dup 19 rshift 255 and
        case
            $004 of ." nz" endof
            $005 of ." z" endof
            $00c of ." ae" endof
            $00d of ." b" endof
            $024 of ." lt" endof
            $025 of ." gte" endof
            $02c of ." lte" endof
            $02d of ." gt" endof
            $034 of ." be" endof
            $035 of ." a" endof
            \ dup dis-hex5 space
            dup 1 rshift 3 and 28 + dis-r comma
            dup 3 rshift 31 and decimal 0 u.r comma
            dup 1 and decimal 0 u.r
        endcase
        comma
    then
;

: atlink    ( pmaddr -- f )
    pm@ 27 rshift 28 =
;

: istext    ( u -- f )
    $80808080 and 0=
;

: xt-name   ( xt -- pmaddr u )
    4 -
    dup pm@ dup istext swap 24 rshift 0= and if
        \ search backwards, looking for link
        8 0 do
            dup atlink if
                cell+
                dup
                \ walk forward, searching for the $00 terminator
                begin
                    dup pmc@
                while
                    1+
                repeat
                over - unloop exit
            then
            4 -
        loop
    then
    0
;

: dis-aa    ( u -- u )
    dup 131071 and
    dis-hex5
;

: pmtype ( pmaddr u -- )
    bounds ?do
        i pmc@ emit
    loop
;

: dis-pa    ( u -- u )
    dup 262143 and 2 lshift
    dup xt-name     ( u pa pmaddr count )
    dup if 
        pmtype space space
    else
        2drop
    then
    dis-hex5
;

: dis-3addr
    dis-rd comma dis-r1 comma dis-rimm
;

: dis-header    ( pm-addr1 u -- pm-addr2 u )
    ." : "
    swap
    begin
        dup pmc@ ?dup
    while
        emit
        1+
    repeat
    1+ aligned
    swap
    dup 1 and if
        ."  (immediate)"
    then
;

: dis-illegal   ( u -- u )
;

( 31 ) ' dis-illegal
( 30 ) :noname  dup 15 and case
          0 of s" udiv"       endof
          1 of s" umod"       endof
          2 of s" div"        endof
          3 of s" mod"        endof
          4 of s" strcmp"     endof
          5 of s" memcpy"     endof
          6 of s" strlen"     endof
          7 of s" memset"     endof
          8 of s" mul"        endof
          9 of s" muluh"      endof
         10 of s" stpcpy"     endof
         12 of s" streamin"   endof
         13 of s" streamini"  endof
         14 of s" streamout"  endof
         15 of s" streamouti" endof
        drop
    endcase .dw dis-3addr ;
( 29 ) :noname  s" exi" .dw        dis-rd comma dis-k8 comma dis-r1 ;
( 28 ) ' dis-header
( 27 ) ' dis-illegal
( 26 ) ' dis-illegal
( 25 ) :noname  s" lpmi" .dw       dis-rd comma dis-r1 comma dis-k8 ;
( 24 ) :noname  s" lda" .dw        dis-rd comma dis-aa ;
( 23 ) :noname  s" sta" .dw        dis-aa comma dis-rd ;
( 22 ) :noname  s" sti" .dw        dis-rd comma dis-k8 comma dis-r1 ;
( 21 ) :noname  s" ldi" .dw        dis-rd comma dis-r1 comma dis-k8 ;
( 20 ) :noname  8" return" ;
( 19 ) ' dis-illegal
( 18 ) ' dis-illegal
( 17 ) :noname  8" pop"            dis-rd ;
( 16 ) :noname  8" push"           dis-r1 ;
( 15 ) ' dis-illegal
( 14 ) ' dis-illegal
( 13 ) :noname  s" lpm" .dw        dis-rd comma dis-pa ;
( 12 ) :noname  8" ldk"            dis-rd comma dis-k20 ;
( 11 ) :noname  dis-cmpop          dis-r1 comma dis-rimm ;
( 10 ) ' dis-illegal
(  9 ) ' dis-illegal
(  8 ) :noname  dis-aluop          dis-3addr ;
(  7 ) ' dis-illegal
(  6 ) ' dis-illegal
(  5 ) ' dis-illegal
(  4 ) ' dis-illegal
(  3 ) ' dis-illegal
(  2 ) ' dis-illegal
(  1 ) :noname  dup 18 rshift 1 and if 8" calli" else 8" jmpi" then dis-rimm ;
(  0 ) :noname  dis-jmpcall dis-pa  ;

align
create dis-pattern
, , , , , , , , , , , , , , , , , , , , , , , , , , , , , , , ,

: dis1 ( pm-addr1 -- pm-addr2 )
    base @ >r
    [ 3 invert ] literal and    \ in case user gave odd addresss
    dup cell+ swap

    hex
    dup dis-hex5
    space
    pm@
    dup dis-hex8
    3 spaces

    dup 27 rshift cells dis-pattern + @ execute drop
    r> base !
;

PUBLICWORDS     \ }{

: dis ( pm-addr1 -- pm-addr2 ) \ disassemble 25 lines at pm-addr1
    25 0 do
        cr dis1
    loop
;

: see
    '
    begin
        cr dis1
        dup atlink over pmdp @ = or
    until
    drop
;

: .xt   ( xt -- ) \ print the name of execution token xt
    2/ 2/ dis-pa drop
    space
;

DONEWORDS    \ }
