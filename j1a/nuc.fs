
\   (doubleAlso) ( c-addr u -- x 1 | x x 2 )
\               If the string is legal, give a single or double cell number
\               and size of the number.
header negate   : negate    invert ;fallthru
header 1+       : 1+        d# 1 + ;
header 1-       : 1-        d# -1 + ;
header 0=       : 0=        d# 0 = ;
header cell+    : cell+     d# 2 + ;

header 0<>      : 0<>       d# 0 ;fallthru
header <>       : <>        = invert ; 
header >        : >         swap < ; 
header 0<       : 0<        d# 0 < ; 
header 0>       : 0>        d# 0 > ;
header u>       : u>        swap u< ; 

header lshift
: lshift
    begin
        dup
    while
        swap 2* swap
        1-
    repeat
    drop
;

header rshift
: rshift
    begin
        dup
    while
        swap 2/ h# 7fff and swap
        1-
    repeat
    drop
;

: uart-stat ( mask -- f ) \ is bit in UART status register on?
    h# 2000 io@ and
;

header key?
: key?
    d# 2 uart-stat 0<>
;

header key
: key
    begin
        key?
    until
;fallthru
: key>
    h# 1000 io@
;

header space
: space
    d# 32
;fallthru

header emit
: emit
    begin
        d# 1 uart-stat 
    until
    h# 1000 io!
;

header cr
: cr
    d# 10
    d# 13
;fallthru
: 2emit
    emit emit
;

header bl
: bl
    d# 32
;

: hex4
    dup d# 8 rshift
    DOUBLE
;fallthru
: hex2
    dup d# 4 rshift
    DOUBLE
    h# f and
    dup d# 10 < if
        [char] 0
    else
        d# 55
    then
    +
    emit
;

header .x
: . hex4 space ;

header false    : false d# 0 ; 
header true     : true  d# -1 ; 
header rot      : rot   >r swap r> swap ; 
header -rot     : -rot  swap >r swap r> ; 
header tuck     : tuck  swap over ; 
header 2drop    : 2drop drop drop ; 
header ?dup     : ?dup  dup if dup then ;

header 2dup     : 2dup  over over ; 
header +!       : +!    tuck @ + swap ! ; 
header 2swap    : 2swap rot >r rot r> ;
header 2over    : 2over >r >r 2dup r> r> 2swap ;

header min      : min   2dup< if drop else nip then ;
header max      : max   2dup< if nip else drop then ;

header c@
: c@
    dup@ swap
    d# 1 and if
        2/ 2/ 2/ 2/
        2/ 2/ 2/ 2/
    then
    d# 255 and
;


header c!
: c! ( u c-addr -- )
    dup>r d# 1 and if
        d# 8 lshift
        h# 00ff
    else
        h# 00ff and
        h# ff00
    then
    r@ @ and
    or r> !
;

header count
: count
    dup 1+ swap c@
;

header bounds
: bounds ( a n -- a+n a )
    over + swap
;

header type
: type
    bounds
    begin
        2dupxor
    while
        dup c@ emit
        1+
    repeat
    2drop
;

create base     $a ,
create forth    0 ,
create cp       0 ,         \ Code pointer, grows up
create dp       0 ,         \ Data pointer, grows up
create lastword 0 ,
create thisxt   0 ,
create syncpt   0 ,
create sourceC  0 , 0 ,
create >in      0 ,
create state    0 ,
create delim    0 ,
create rO       0 ,
create leaves   0 ,
create tethered 0 ,
create tib #128 allot

header dp    :noname dp ;
header cp    :noname cp ;
header state :noname state ;
header base  :noname base ;
header >in   :noname >in  ;
header forth :noname forth ;

\ tethered mode flag
header tth
: tth
    tethered
;

: nextword
    @ d# -2 and
;

header words : words
    forth @
    begin
        dup
    while
        dup d# 2 +
        count type
        space
        nextword
    repeat
    drop
;

\ header dump
\ : dump ( addr u -- )
\     cr over hex4
\     begin  ( addr u )
\         ?dup
\     while
\         over c@ space hex2
\         1- swap 1+   ( u' addr' )
\         dup h# f and 0= if  ( next line? )
\             cr dup hex4
\         then
\         swap
\     repeat
\     drop cr
\ ;

header -        : -         negate + ; 
header abs      : abs       dup 0< if negate then ; 
header here     : here      dp @ ;

: 1/string
    d# 1
header /string
: /string
    dup >r - swap r> + swap
; 

header aligned
: aligned
    1+ d# -2 and
; 

header d+
: d+                              ( augend . addend . -- sum . ) 
    rot + >r                      ( augend addend) 
    over+                         ( augend sum) 
    swap over swap                ( sum sum augend)
    u< if                         ( sum) 
        r> 1+ 
    else 
        r> 
    then                          ( sum . ) 
; 

header dnegate
: dnegate 
    invert swap invert swap 
    d# 1. d+
; 

header dabs
: dabs ( d -- ud )
    dup 0< if dnegate then
; 

header s>d
: s>d dup 0< ;

header m+
: m+
    s>d d+
;

header d0=
: d0=
    or 0=
;

\ : snap
\     cr depth hex2 space
\     begin
\         depth
\     while
\         .
\     repeat
\     cr
\     [char] # emit
\     begin again
\ ;

create scratch 0 ,

header d2*
: d2*
    2* over d# 0 < d# 1 and + swap 2* swap
;

: mulstep ( ud u1 -- ud u1 )
    DOUBLE DOUBLE DOUBLE DOUBLE
    >r
    d2*
    r@ d# 0 < if 
        scratch @ d# 0 d+ 
    then 
    r> 2*
;

header um*
: um*  ( u1 u2 -- ud ) 
    scratch ! 
    d# 0. rot
    mulstep
    drop 
; 

: mul32step ( u2 u1 -- u2 u1 )
    DOUBLE DOUBLE DOUBLE DOUBLE
    >r
    2*
    r@ d# 0 < if 
        scratch @ +
    then 
    r> 2*
;

header *
: *
    scratch !
    d# 0 swap
    mul32step
    drop
;

\ see Hacker's Delight (2nd ed) 9-4 "Unsigned Long Division"

: divstep  \ ( y x z )
    >r
    dup 0< >r
    d2*
    dup r> or r@ u< invert if
        r@ -
        swap 1+ swap
    then
    r>
;

header um/mod
: um/mod \ ( ud u1 -- u2 u3 ) ( 6.1.2370 ) 
    divstep divstep divstep divstep
    divstep divstep divstep divstep
    divstep divstep divstep divstep
    divstep divstep divstep divstep
    drop swap 
; 

header accept
: accept
    tethered @ if
        d# 30 emit
    then
    drop dup
    begin
        key
        dup h# 0d xor
    while
        dup h# 0a = if
            drop
        else
            tethered @ 0= if
                dup emit
            then
            over c! 1+
        then
    repeat
    drop swap -
;

: 3rd   >r over r> swap ;
: 3dup  3rd 3rd 3rd ;

: lower ( c1 -- c2 ) \ c2 is the lower-case of c1
    h# 40 over <
    over h# 5b < and
    h# 20 and +
;

: i<> ( c1 c2 -- f ) \ case-insensitive difference
    2dupxor h# 1f and if
        drop exit
    then
    lower swap lower xor
;

: sameword ( c-addr u wp -- c-addr u wp flag )
    2dup d# 2 + c@ = if
        3dup
        d# 3 + >r
        bounds
        begin
            2dupxor
        while
            dup c@ r@ c@ i<> if
                2drop rdrop false exit
            then
            1+
            r> 1+ >r
        repeat
        2drop rdrop true
    else
        false
    then
;

: >xt
    d# 2 +
    count +
    aligned
    @
;

header align
: align
    here
    aligned
    dp !
;

\ lsb 0 means non-immediate, return -1
\     1 means immediate,     return  1
: isimmediate ( wp -- -1 | 1 )
    @ d# 1 and 2* 1-
;

header sfind
: sfind
    forth @
    begin
        dup
    while
        sameword
        if 
            nip nip
            dup >xt
            swap isimmediate
            exit
        then
        nextword
    repeat
;

: digit? ( c -- u f )
   lower
   dup h# 39 > h# 100 and +
   dup h# 160 > h# 127 and - h# 30 -
   dup base @ u<
;

: ud* ( ud1 u -- ud2 ) \ ud2 is the product of ud1 and u
    tuck * >r
    um* r> +
;

header >number
: >number ( ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
    begin
        dup
    while
        over c@ digit?
        0= if drop exit then
        >r 2swap base @
        \ ud*
        tuck * >r um* r> +
        r> m+ 2swap
        1/string
    repeat
;

header fill
: fill ( c-addr u char -- ) ( 6.1.1540 ) 
  >r  bounds 
  begin
    2dupxor 
  while
    r@ over c! 1+ 
  repeat
  r> drop 2drop
; 

header cmove
: cmove ( addr1 addr2 u -- )
    bounds rot >r
    begin
        2dupxor
    while
        r@ c@ over c!
        r> 1+ >r
        1+
    repeat
    rdrop 2drop
;

header cmove>
: cmove> \ ( addr1 addr2 u -- )
    begin
        dup
    while
        1- >r
        over r@ + c@
        over r@ + c!
        r>
    repeat
    drop 2drop
;

header code@
: code@
    h# 2000 or
;fallthru
header execute
: execute
    >r
;

header source
: source
    sourceC
;fallthru

header 2@
: 2@ \ ( a -- lo hi )
    dup cell+ @ swap @
;

: source! ( addr u -- ) \ set the source
    sourceC
;fallthru

header 2!
: 2! \ ( lo hi a -- )
    tuck !
    cell+ !
;

\ From Forth200x - public domain

: isspace? ( c -- f )
    bl 1+ u< ;

: isnotspace? ( c -- f )
    isspace? 0= ;

: xt-skip   ( addr1 n1 xt -- addr2 n2 ) \ gforth
    \ skip all characters satisfying xt ( c -- f )
    >r
    BEGIN
    over c@ r@ execute
    over 0<> and
    WHILE
	1/string
    REPEAT
    r> drop ;

header parse-name
: parse-name ( "name" -- c-addr u )
    source >in @ /string
    ['] isspace? xt-skip over >r
    ['] isnotspace?
;fallthru
: _parse
    xt-skip ( end-word restlen r: start-word )
    2dup d# 1 min + source drop - >in !
    drop r> tuck -
;

: isnotdelim
    delim @ <>
;

header parse
: parse ( "ccc<char" -- c-addr u )
    delim !
    source >in @ /string
    over >r
    ['] isnotdelim
    _parse
;

header ,
: w,
    here !
    d# 2
;fallthru

header allot
: allot
    dp +!
;

header c,
: c,
    here c!
    d# 1 allot
;

: code,
    cp @ !
    d# 2 cp +!
;

: attach
    lastword @ ?dup if
        forth !
    then
;

: sync
    cp @ syncpt !
;

header s,
: s,
    dup c,
    bounds
    begin
        2dupxor
    while
        dup c@ c,
        1+
    repeat
    2drop
;

: mkheader
    align
    here lastword !
    forth @ w,
    parse-name
    s,
    align
    cp @ dup w,
    thisxt !
    sync
;

header immediate
:noname
    d# 1 lastword @ +!
;

header ]
: t]
    d# 3
;fallthru
: state!
    state !
;

header-imm [
: t[
    d# 0 state!
;

header :
:noname
    mkheader t]
;

header :noname
:noname
    align cp @
    dup thisxt !
    d# 0 lastword !
    sync
    t]
;

: (loopdone)  ( 0 -- )
    drop
    r> r> rO ! >r
;

header-imm exit
: texit
    inline: exit
;

header-imm ;
:noname
    attach
    texit
    t[
;

\ Represent forward branches in one word
\ using the high-3 bits for the branch type,
\ and low 13 bits for the address.
\ THEN does the work of extracting the pieces.

header-imm ahead
: tahead
    cp @ h# 0000 or
    d# 0 code,
;

header-imm if
: tif
    tahead h# 2000 or
;

header-imm then
: tthen
    dup h# e000 and
    cp @ 2/ or
    swap h# 1fff and !
    sync
;

header-imm begin
: tbegin
    cp @ 2/
;

header-imm again
: tagain
    code,
;

header-imm until
: tuntil
    h# 2000 or code,
;

\ : isreturn ( opcode -- f )
\     h# e080 and
\     h# 6080 =
\ ;
\ 
\ : isliteral ( ptr -- f)
\     dup @ h# 8000 and 0<>
\     swap d# 2 + @ h# 608c = and
\ ;
\ 
\ header compile,
\ : compile,
\     dup @ isreturn if
\         @ h# ff73 and
\         code,
\     else
\         dup isliteral if
\             @ code,
\         else
\             2/ h# 4000 or
\             code,
\         then
\     then
\ ;
header compile,
: compile,
    2/ h# 4000 or code,
;

header does>
:noname
    r> 2/
    lastword @
    >xt d# 2 +  \ ready to patch the RETURN
    !
;

header-imm recurse
:noname
    thisxt @ compile,
;

\
\ How DO...LOOP is implemented
\
\ Uses top of R-stack (R) and a variable rO:
\    R is the counter; it starts negative and counts up. When it reaches 0, loop exits
\    rO is the offset. It is set up at loop start so that I can be computed from (rC+rO)
\
\ So DO receives ( limit start ) on the stack. It needs to compute:
\      R = start - limit
\      rO = limit
\
\ E.g. for "13 3 DO"
\      rC = -10
\      rO = 13
\
\ So the loop runs:
\      R      -10 -9 -8 -7 -6 -5 -4 -3 -2 -1
\      I        3  4  5  6  7  8  9 10 11 12
\
\

: (do)  ( limit start -- start-limit )
    r> rO @ >r >r
    over rO !
    swap -
;

: (?do)  ( limit start -- start-limit start!=limit )
    r> rO @ >r >r
    over rO !
    swap -
    dup 0=
;

: (loopnext)
    d# 1 + dup
;

header-imm do
:noname
    leaves @ d# 0 leaves !
    ['] (do) compile,
    tbegin
    inline: >r
;

\ Finish compiling DO..LOOP
\ resolve each LEAVE by walking the chain starting at 'leaves'
\ compile a call to (loopdone)

: resolveleaves
\     leaves @
\     begin
\         dup
\     while
\         dup @ swap        ( next leafptr )
\         cp @ 2/ swap !
\     repeat
\     drop
    leaves !
    ['] (loopdone) compile,
;

header-imm loop
:noname
    inline: r>
    ['] (loopnext) compile,
    tif
    swap tagain
    tthen
    resolveleaves
;

: (+loopnext) ( inc R -- R finished )
    over 0< if
        dup>r +
        r> over ( R old new )
        u<
    else
        dup>r +
        r> over ( R old new )
        u>
    then
;

header-imm +loop
:noname
    inline: r>
    ['] (+loopnext) compile,
    tuntil
    resolveleaves
;

\ header-imm leave
\ : leave
\     inline: r>
\     cp @
\     leaves @ code,
\     leaves !
\ ;

\ header-imm ?do
\ :noname
\     leaves @ d# 0 leaves !
\     ['] (?do) compile,
\     tif
\         cp @
\         leaves @ code,
\         leaves !
\     tthen
\     tbegin
\     inline: >r
\ ;

header i
: i
    r>
    r@ rO @ +
    swap >r
;

header j
: j
    r> r>
    r> r> 2dup + -rot
    >r >r
    -rot
    >r >r
;

header-imm unloop
:noname
    inline: r>
    ['] (loopdone) compile,
;

header decimal
: decimal
    d# 10 base !
;

header cells
header 2*       :noname     2*       ;
header 2/       :noname     2/       ;
header !        :noname     !        ;
header +        :noname     +        ;
header xor      :noname     xor      ;
header and      :noname     and      ;
header or       :noname     or       ;
header invert   :noname     invert   ;
header =        :noname     =        ;
header <        :noname     <        ;
header u<       :noname     u<       ;
header swap     :noname     swap     ;
header dup      :noname     dup      ;
header drop     :noname     drop     ;
header over     :noname     over     ;
header nip      :noname     nip      ;
header @        :noname     @        ;
header io!      :noname     io!      ;
header io@      :noname     io@      ;
header depth    :noname     depth    ;
header-imm >r   :noname     inline: >r ;
header-imm r>   :noname     inline: r> ;
header-imm r@   :noname     inline: r@ ;

: jumptable ( u -- ) \ add u to the return address
    r> + >r ;

: -throw ( a b -- ) \ if a is nonzero, throw -b
    negate and
;fallthru

header throw
: throw
    ?dup if
        [char] e emit
        [char] r emit
        [char] r emit
        [char] o emit
        [char] r emit
        [char] : emit
        space
        .
        d# 0 execute
    then
;

header abort
: abort
    d# -1 throw
;

: isvoid ( caddr u -- ) \ any char remains, throw -13
    nip 0<> d# 13 -throw
;

: consume1 ( caddr u ch -- caddr' u' f )
    >r over c@ r> =
    over 0<> and
    dup>r d# 1 and /string r>
;

: ((doubleAlso))
    h# 0. 2swap
    [char] - consume1 >r
    >number
    [char] . consume1 if
        isvoid              \ double number
        r> if dnegate then
        d# 2 exit
    then
                            \ single number
    isvoid drop
    r> if negate then
    d# 1
;

: base((doubleAlso))
    base @ >r base !
    ((doubleAlso))
    r> base !
;

: is'c' ( caddr u -- f )
    d# 3 =
    over c@ [char] ' = and
    swap d# 2 + c@ [char] ' = and
;

\   (doubleAlso) ( c-addr u -- x 1 | x x 2 )
\               If the string is legal, give a single or double cell number
\               and size of the number.

: (doubleAlso)
    [char] $ consume1 if
        d# 16 base((doubleAlso)) exit
    then
    [char] # consume1 if
        d# 10 base((doubleAlso)) exit
    then
    [char] % consume1 if
        d# 2 base((doubleAlso)) exit
    then
    2dup is'c' if
        drop 1+ c@ d# 1 exit
    then
    ((doubleAlso))
;

: doubleAlso
    (doubleAlso) drop
;

header-imm literal
: tliteral
    dup 0< if
        invert tliteral
        inline: invert
    else
        h# 8000 or code,
    then
;

header-imm postpone
:noname
    parse-name sfind
    dup 0= d# 13 -throw
    0< if
        tliteral
        ['] compile,
    then
    compile,
;

: doubleAlso,
    (doubleAlso)
    1- if
        swap tliteral
    then
    tliteral
;

: dispatch
    jumptable ;fallthru
    jmp execute                 \      -1      0       non-immediate
    jmp doubleAlso              \      0       0       number
    jmp execute                 \      1       0       immediate

    jmp compile,                \      -1      2       non-immediate
    jmp doubleAlso,             \      0       2       number
    jmp execute                 \      1       2       immediate

: interpret
    begin
        parse-name dup
    while
        sfind
        state @ +
        1+ 2* dispatch
    repeat
    2drop
;

header refill
: refill
    tib dup d# 128 accept
    source!
    d# 0 >in !
    true
;

header evaluate
:noname
    source >r >r >in @ >r
    source! d# 0 >in !
    interpret
    r> >in ! r> r> source!
;

: main
    cr
    decimal
    d# 0 tethered !
    key> drop

header quit
    begin
        refill drop
        interpret
        state @ 0= if
            space space
            [char] k
            [char] o 2emit
            cr
        then
    again
;

meta
    link @ t' forth tw!
    there  t' dp tw!
    tcp @  t' cp tw!
target
