\ #######   CORE EXT   ########################################

\ : source-id (source-id) @ ;

: erase     0 fill ;

: within    over - >r - r> u< ;

: .(
    [char] ) parse type
; immediate

: find
    count sfind
    dup 0= if
        2drop 1- 0
    then
;

: [compile]
    ' compile,
; immediate

create _ 80 allot  \ The "temporary buffer" in ANS: A.11.6.1.2165

: s"
    [char] " parse
    state @ if
        postpone sliteral
    else
        tuck _ swap cmove
        _ swap
    then
; immediate

( CASE                                       JCB 09:15 07/18/14)
\ From ANS specification A.3.2.3.2

0 constant case immediate  ( init count of ofs )

: of  ( #of -- orig #of+1 / x -- )
    1+    ( count ofs )
    postpone over  postpone = ( copy and test case value)
    postpone if    ( add orig to control flow stack )
    postpone drop  ( discards case value if = )
    swap           ( bring count back now )
; immediate

: endof ( orig1 #of -- orig2 #of )
    >r   ( move off the stack in case the control-flow )
         ( stack is the data stack. )
    postpone else
    r>   ( we can bring count back now )
; immediate

: endcase  ( orig1..orign #of -- )
    postpone drop  ( discard case value )
    begin
        dup
    while
        swap postpone then 1-
    repeat drop
; immediate

: hex
    16 base !
;

: save-input
    >in @ 1
;

: restore-input
    drop >in !
    true
;

\ From ANS specification A.6.2.0970
: convert   1+ 511 >number drop ;
