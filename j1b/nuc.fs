$1000 constant UART-D
$2000 constant UART-STATUS

\ meta
\     $3f80 org 
\ target
\ 
\ : b.key
\     begin
\         UART-STATUS io@
\         d# 4 and
\     until
\     UART-D io@
\ ;
\ 
\ : b.32
\     b.key
\     b.key d# 8 lshift or
\     b.key d# 16 lshift or
\     b.key d# 24 lshift or
\ ;
\ 
\ : section
\     b.32 b.32
\     begin
\         2dupxor
\     while
\         b.32 over !
\         d# 4 +
\     repeat
\     drop drop
\ ;
\ 
\ : bootloader
\     begin
\         b.key d# 27 =
\     until
\ 
\     section section
\ ;

meta
    4 org 
target

header 1+       : 1+        d# 1 + ;
header 1-       : 1-        d# -1 + ;
header 0=       : 0=        d# 0 = ;
header cell+    : cell+     d# 4 + ;
header cells    : cells     d# 2 lshift ;

header <>       : <>        = invert ; 
header >        : >         swap < ; 
header 0<       : 0<        d# 0 < ; 
header 0>       : 0>        d# 0 > ;
header 0<>      : 0<>       d# 0 <> ;
header u>       : u>        swap u< ; 

: off
    d# 0 swap !
;

header key?
: key?
    d# 2
: uart-stat ( mask -- f ) \ is bit in UART status register on?
    h# 2000 io@ and 0<>
;

header key
: key
    begin
        key?
    until
    UART-D io@
;

header emit
: emit
    begin
        d# 1 uart-stat 
    until
    UART-D io!
;

header cr
: cr
    d# 13 emit
    d# 10 emit
;

header space
: space
    d# 32 emit
;

header bl
: bl
    d# 32
;

: hex8 dup d# 16 rshift DOUBLE
: hex4 dup d# 8 rshift DOUBLE
: hex2 dup d# 4 rshift DOUBLE
: hex1
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
: . hex8 space ;

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
    d# 3 lshift rshift
    d# 255 and
;

: hi16
    d# 16 rshift d# 16 lshift
;

: lo16
    d# 16 lshift d# 16 rshift
;

header uw@
: uw@
    dup@ swap
    d# 2 and d# 3 lshift rshift
    lo16
;

header w@
: w@
    uw@
    h# 8000 overand if
        h# -10000 +
    then
;

header w!
: w! ( u c-addr -- )
    dup>r d# 2 and if
        d# 16 lshift
        r@ @ lo16
    else
        lo16
        r@ @ hi16
    then
    or r> !
;

: w+!   ( u a -- ) \ like +! but for 16-bit a
    tuck uw@ + swap w!
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
    r@ uw@ and
    or r> w!
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

create "cold"
    'c' c, 'o' c, 'l' c, 'd' c,

create base     $a ,
create forth    0 ,
create cp       0 ,         \ Code pointer, grows up
create dp       0 ,         \ Data pointer, grows up
create lastword 0 ,
create thisxt   0 ,
create syncpt   0 ,
create sourceC  0 , 0 ,
create sourceid 0 ,
create >in      0 ,
create state    0 ,
create delim    0 ,
create rO       0 ,
create leaves   0 ,
create tethered 0 ,
create tib $80 allot

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
    uw@ d# -2 and
;

header words : words
    forth uw@
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

\ header dump : dump ( addr u -- )
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

header negate   : negate    invert 1+ ; 
header -        : -         negate + ; 
header abs      : abs       dup 0< if negate then ; 
header 2*       : 2*        d# 1 lshift ; 
header 2/       : 2/        dup 0< if invert d# 1 rshift invert else d# 1 rshift then ; 
header here     : here      dp @ ;
header depth    : depth     depths h# 1f and ;

header /string
: /string
    dup >r - swap r> + swap
; 

header aligned
: aligned
    d# 3 + d# -4 and
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

header 2@
: 2@ \ ( a -- lo hi )
    dup cell+ @ swap @
;

header 2!
: 2! \ ( lo hi a -- )
    tuck !
    cell+ !
;

header 2rot
: 2rot
    >r >r 2swap r> r> 2swap
;

header d>s
: d>s   drop ;

header d=
: d=                        \ a b c d -- f ) 
    >r                      \ a b c 
    rot =                   \ b a=c 
    swap r> =               \ a=c b=d 
    and
; 

header d<
: d<            \ ( al ah bl bh -- flag ) 
    rot         \ al bl bh ah 
    2dup = 
    if 
        2drop u< 
    else 
        > nip nip
    then 
; 

header du<
: du<           \ ( al ah bl bh -- flag ) 
    rot         \ al bl bh ah 
    2dup = 
    if 
        2drop u< 
    else 
        u> nip nip
    then 
; 

header d-
: d-
    dnegate d+
;

header d0<
: d0<
    nip 0<
;

header d0=
: d0=
    or 0=
;

header d2*
: d2*
    2dup d+
; 

header d2/
: d2/
    >r d# 1 rshift r@
    d# 31 lshift
    or r> 2/
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

: mulstep ( ud u1 -- ud u1 )
    DOUBLE DOUBLE DOUBLE DOUBLE DOUBLE
    >r
    d# 1 lshift over d# 31 rshift + swap d# 1 lshift swap
    r@ d# 0 < if 
        scratch @ d# 0 d+ 
    then 
    r> d# 1 lshift
;

header um*
: um*  ( u1 u2 -- ud ) 
    scratch ! 
    d# 0. rot
    mulstep
    drop 
; 

: mul32step ( u2 u1 -- u2 u1 )
    DOUBLE DOUBLE DOUBLE DOUBLE DOUBLE
    >r
    d# 1 lshift
    r@ d# 0 < if 
        scratch @ +
    then 
    r> d# 1 lshift
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
    DOUBLE DOUBLE DOUBLE DOUBLE DOUBLE
    >r
    dup 0< >r
    2dup d+
    dup r> or r@ u< invert if
        r@ -
        swap 1+ swap
    then
    r>
;

header um/mod
: um/mod \ ( ud u1 -- u2 u3 ) ( 6.1.2370 ) 
    divstep
    drop swap 
; 

\ Unicode-friendly ACCEPT contibuted by Matthias Koch

: delchar ( addr len -- addr len )
    dup if d# 8 emit d# 32 emit d# 8 emit then

    begin
        dup 0= if exit then
        1- 2dup + c@
        h# C0 and h# 80 <>
      until
;

header accept
: accept
    tethered @ if d# 30 emit then
    
    >r d# 0  ( addr len R: maxlen )

    begin
        key    ( addr len key R: maxlen )
        
        d# 9 over= if drop d# 32 then
        d# 127 over= if drop d# 8 then
        
        dup d# 31 u>
        if
            over r@ u<
            if
                tethered @ 0= if dup emit then
                >r 2dup + r@ swap c! 1+ r>
            then
        then
        
        d# 8 over= if >r delchar r> then
          
        d# 10 over= swap d# 13 = or
    until
    
    rdrop nip
    space
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

header caligned
: caligned
    1+ d# -2 and
;

: >xt
    d# 2 +
    count +
    caligned
    uw@
;

header calign
: calign
    dp @
    caligned
    dp !
;

\ lsb 0 means non-immediate, return -1
\     1 means immediate,     return  1
: isimmediate ( wp -- -1 | 1 )
    uw@ d# 1 and 2* 1-
;

header sfind
: sfind
    forth uw@
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
        >r 2swap base @ ud*
        r> s>d d+ 2swap
        d# 1 /string
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

header execute
: execute
    >r
;

header source
: source
    sourceC 2@
;

: source! ( addr u -- ) \ set the source
    sourceC 2!
;

header source-id
: source-id
    sourceid @
;

\ From Forth200x - public domain

: isspace? ( c -- f )
    h# 21 u< ;

: isnotspace? ( c -- f )
    isspace? 0= ;

: xt-skip   ( addr1 n1 xt -- addr2 n2 ) \ gforth
    \ skip all characters satisfying xt ( c -- f )
    >r
    BEGIN
        over c@ r@ execute
        overand
    WHILE
        d# 1 /string
    REPEAT
    r> drop ;

header parse-name
: parse-name ( "name" -- c-addr u )
    source >in @ /string
    ['] isspace? xt-skip over >r
    ['] isnotspace? xt-skip ( end-word restlen r: start-word )
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
    ['] isnotdelim xt-skip
    2dup d# 1 min + source drop - >in !
    drop r> tuck -
;


header allot
: tallot
    dp +!
;

header ,
:noname
    here !
    d# 4 tallot
;

header w,
: w,
    here w!
    d# 2 tallot
;

header c,
: tc,
    here c!
    d# 1 tallot
;

: code,
    cp @ w!
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
    dup tc,
    bounds
    begin
        2dupxor
    while
        count tc,
    repeat
    2drop
;

: mkheader
    calign
    here lastword !
    forth @ w,
    parse-name
    s,
    calign
    cp @ w,
    cp @ thisxt !
    sync
;

header immediate
:noname
    lastword @
    dup uw@ d# 1 or
    swap w!
;

header ]
: t]
    d# 3 state !
;

header-imm [
: t[
    d# 0 state !
;

header :
:noname
    mkheader t]
;

header :noname
:noname
    calign cp @
    dup thisxt !
    d# 0 lastword !
    sync
    t]
;

: inline:
    r>
    dup uw@ code,
    d# 2 + >r
;

: prev
    cp @ d# -2 +
;

: (loopdone)  ( 0 -- )
    drop
    r> r> rO ! >r
;

: jumpable ( op -- f )
    dup h# e000 and h# 4000 =       \ is a call
    swap h# 1fff and 2* ['] (loopdone) <> and
;

header-imm exit
: texit
    cp @ thisxt @ <> if
        prev uw@ jumpable if
            prev
            uw@
            h# 4000 xor
            prev w!
            \ cp @ syncpt @ <> if
                inline: exit
            \ then
            exit
        then
    then
    inline: exit
;

header-imm ;
:noname
    attach
    texit
    t[
;

\ : ubranch   h# 0000 or tw, ;
\ : 0branch   h# 2000 or tw, ;

header-imm if
: tif
    cp @
    h# 2000 code,
;

header-imm ahead
:noname
    cp @
    h# 0000 code,
;

header-imm then
: tthen
    dup uw@
    cp @ 2/ or
    swap w!
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

: isreturn ( opcode -- f )
    h# e080 and
    h# 6080 =
;

: isliteral ( ptr -- f)
    dup uw@ h# 8000 and 0<>
    swap d# 2 + uw@ h# 608c = and
;

header compile,
: compile,
    dup uw@ isreturn if
        uw@ h# ff73 and
        code,
    else
        dup isliteral if
            uw@ code,
        else
            2/ h# 4000 or
            code,
        then
    then
;

header does>
:noname
    r> 2/
    lastword @
    >xt d# 2 +  \ ready to patch the RETURN
    w!
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
    leaves @
    begin
        dup
    while
        dup uw@ swap        ( next leafptr )
        cp @ 2/ swap w!
    repeat
    drop
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

header-imm leave
: leave
    inline: r>
    cp @
    leaves @ code,
    leaves !
;

header-imm ?do
:noname
    leaves @ d# 0 leaves !
    ['] (?do) compile,
    tif
        cp @
        leaves @ code,
        leaves !
    tthen
    tbegin
    inline: >r
;

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
    d# 10
;fallthru
: setbase
    base !
;

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
header over     :noname     over    ;
header nip      :noname     nip      ;
header @        :noname     @        ;
header io!      :noname     io!      ;
header io@      :noname     io@      ;
header rshift   :noname     rshift   ;
header lshift   :noname     lshift   ;
header-imm >r   :noname     inline: >r ;
header-imm r>   :noname     inline: r> ;
header-imm r@   :noname     inline: r@ noop ;

: jumptable ( u -- ) \ add u to the return address
    r> + >r ;

\   (doubleAlso) ( c-addr u -- x 1 | x x 2 )
\               If the string is legal, give a single or double cell number
\               and size of the number.

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
        d# 2 execute
    then
;

: -throw ( a b -- ) \ if a is nonzero, throw -b
    negate and throw
;

header-imm 2literal
: 2literal
    swap DOUBLE
header-imm literal
: tliteral
    dup 0< if
        invert tliteral
        inline: invert
    else
        dup h# ffff8000 and if
            dup d# 15 rshift tliteral
            d# 15 tliteral
            inline: lshift
            h# 7fff and tliteral
            inline: or
        else
            h# 8000 or code,
        then
    then
    
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
        ['] 2literal exit
    then
                            \ single number
    isvoid drop
    r> if negate then
: single
    ['] tliteral
;

: base((doubleAlso))
    base @ >r setbase
    ((doubleAlso))
    r> setbase
;

: is'c' ( caddr u -- f )
    d# 3 =
    over c@ [char] ' = and
    swap 1+ 1+ c@ [char] ' = and
;

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
        drop 1+ c@ single exit
    then
    ((doubleAlso))
;

: doubleAlso
    (doubleAlso) drop
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
    execute
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
    source-id 0= dup
    if
        tib dup d# 128 accept
        source!
        d# 0 >in !
    then
;

header evaluate
:noname
    source >r >r >in @ >r
    source-id >r d# -1 sourceid !
    source! d# 0 >in !
    interpret
    r> sourceid !
    r> >in ! r> r> source!
;

header quit
: quit
    begin
        refill drop
        interpret
        space
        [char] o emit
        [char] k emit
        cr
    again
;

: main
    decimal
    tethered off
    "cold" d# 4 sfind if
        execute
    else
        2drop
    then
    quit
;

meta
    link @ t,
    link @ t' forth t!
    there  t' dp t!
    tcp @  t' cp t!
target
