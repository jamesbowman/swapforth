
\   (doubleAlso) ( c-addr u -- x 1 | x x 2 )
\               If the string is legal, give a single or double cell number
\               and size of the number.
header 1+       : 1+        d# 1 + ;
header negate   : negate    invert 1+ ;
header 1-       : 1-        d# -1 + ;
header 0=       : 0=        d# 0 = ;
header cell+    : cell+     d# 2 + ;

header <>       : <>        = invert ; 
header 0<>      : 0<>       d# 0 <> ;
header >        : >         swap < ; 
header 0<       : 0<        d# 0 < ; 
header 0>       : 0>        d# 0 > ;
header u>       : u>        swap u< ; 

: off   ( a -- ) \ store 0 to a
    d# 0 swap
;fallthru
: _!    ( x a -- ) \ subroutine version of store
    !
;

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

header emit
: emit
    begin
        d# 1 uart-stat 
    until
    h# 1000 io!
;

header space
: space
    d# 32 emit
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

header execute
: execute
    >r
;

header @
: @
    h# 2000 or execute
;

header false    : false d# 0 ; 
header true     : true  d# -1 ; 
header rot      : rot   >r swap r> swap ; 
header -rot     : -rot  swap >r swap r> ; 
header tuck     : tuck  swap over ; 
header 2drop    : 2drop drop drop ; 
header ?dup     : ?dup  dup if dup then ;

header 2dup     : 2dup  over over ; 
header +!       : +!    tuck @ + swap _! ; 
header 2swap    : 2swap rot >r rot r> ;
header 2over    : 2over >r >r 2dup r> r> 2swap ;

header min      : min   2dup< if drop else nip then ;
header max      : max   2dup< if nip else drop then ;

header c@
: c@
    dup @ swap
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
    or r> _!
;

header count
: count
    dup 1+ swap c@
;

header bounds
: bounds ( a n -- a+n a )
    over+ swap
;

header type
: type
    bounds
    begin
        2dupxor
    while
        count emit
    repeat
    2drop
;

create base     $a ,
create forth    0 ,
create dp       0 ,         \ Data pointer, grows up
create lastword 0 ,
create thisxt   0 ,
\ create syncpt   0 ,
create sourceC  0 , 0 ,
create >in      0 ,
create state    0 ,
create rO       0 ,
create leaves   0 ,
create tethered 0 ,
create fineforoptimisation 0 ,
create tib      #128 allot

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
    forth @i
    begin
        dup
    while
        dup cell+
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
header here     : here      dp @i ;

header /string
: /string
    dup >r - swap r> + swap
; 

: 1/string
    d# 1
    /string
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
    DOUBLE DOUBLE
    >r
    d2*
    r@ d# 0 < if 
        scratch @i d# 0 d+ 
    then 
    r> 2*
;

header um*
: um*  ( u1 u2 -- ud ) 
    scratch _! 
    d# 0. rot
    mulstep mulstep mulstep mulstep
    drop 
; 

\ : mul32step ( u2 u1 -- u2 u1 )
\     DOUBLE DOUBLE
\     >r
\     2*
\     r@ d# 0 < if 
\         scratch @i +
\     then 
\     r> 2*
\ ;
\ 
\ header *
\ : *
\     scratch !
\     d# 0 swap
\     mul32step mul32step mul32step mul32step
\     drop
\ ;

header *
: *
    um* drop
;

\ see Hacker's Delight (2nd ed) 9-4 "Unsigned Long Division"

: divstep  \ ( y x z )
    DOUBLE DOUBLE
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
    drop swap 
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
        drop ;
    then
    lower swap lower xor
;

: sameword ( c-addr u wp -- c-addr u wp flag )
    2dup cell+ c@ = if
        3dup
        d# 3 + >r
        bounds
        begin
            2dupxor
        while
            dup c@ r@ c@ i<> if
                2drop rdrop false ;
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
    cell+
    count +
    aligned
;

header align
: align
    here
    aligned
    dp _!
;


header sfind
: sfind
    forth @i
    begin
        dup
    while
        sameword
        if 
            nip nip
            dup >xt
            swap        ( xt wp )
                        \ wp lsb 0 means non-immediate, return -1
                        \        1 means immediate,     return  1
            @ d# 1 and 2* 1-
            ;
        then
        nextword
    repeat
;

: digit? ( c -- u f )
   lower
   dup h# 39 > h# 100 and +
   dup h# 160 > h# 127 and - h# 30 -
   dup base @i u<
;

\ : ud* ( ud1 u -- ud2 ) \ ud2 is the product of ud1 and u
\     tuck * >r
\     um* r> +
\ ;

header >number
: >number ( ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
    begin
        dup
    while
        over c@ digit?
        0= if drop ; then
        >r 2swap base @i
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

header 2@
: 2@ \ ( a -- lo hi )
    dup cell+ @ swap @
;

header 2!
: 2! \ ( lo hi a -- )
    tuck _!
    cell+ _!
;

header source
: source
    sourceC 2@
;

: source! ( addr u -- ) \ set the source
    sourceC 2!
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
    source >in @i /string
    ['] isspace? xt-skip over >r
    ['] isnotspace?
;fallthru
: _parse
    xt-skip ( end-word restlen r: start-word )
    2dup d# 1 min + source drop - >in _!
    drop r>
    tuck -
;

: isnotdelim
    scratch @i <>
;

header parse
: parse ( "ccc<char" -- c-addr u )
    scratch _!
    source >in @i /string
    over >r
    ['] isnotdelim
    _parse
;

header allot
: tallot
    dp +!
;

header ,
: w,
    here _!
    d# 2 tallot
;

header c,
: c,
    here c!
    d# 1 tallot
;

\ : isreturn ( opcode -- f )
\     h# e080 and
\     h# 6080 =
\ ;
\ 
\ : isliteral ( ptr -- f)
\     dup @ h# 8000 and 0<>
\     swap cell+ @ h# 608c = and
\ ;
\ 
\ header compile,
\ : compile,
\     dup @ isreturn if
\         @ h# ff73 and
\         w,
\     else
\         dup isliteral if
\             @ w,
\         else
\             2/ h# 4000 or
\             w,
\         then
\     then
\ ;

header compile,
: compile,
    2/ h# 4000 or w,
;

: attach
    lastword @i ?dup if
        forth _!
    then
;

\ : sync
\     dp @i syncpt _!
\ ;

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
    align
;

: (sliteral)
    r>
    count
    2dup + aligned
    >r
;

header-imm sliteral
:noname
    ['] (sliteral) compile,
    s,
;

: mkheader
    align
    here lastword _!
    forth @i w,
    parse-name
    s,
    dp @i thisxt _!
    \ sync
;

header immediate
:noname
    lastword @i
    dup @ d# 1 or swap _!
;

header ]
: t]
    fineforoptimisation off  \  : --> No opcodes written yet - never recognize header bytes as opcodes !
    d# 3                      \ ] --> Something strange might just went on. Careful !
;fallthru
: state!
    state _!
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
    align dp @i
    dup thisxt _!
    lastword off
    \ sync
    t]
;

: (loopdone)  ( 0 -- )
    drop
    r> r> rO _! >r
;

\ : prev
\     dp @ d# -2 +
\ ;
\ 
\ : jumpable ( op -- f )
\     dup h# e000 and h# 4000 =       \ is a call
\     swap h# 1fff and 2* ['] (loopdone) <> and
\ ;
\ 
\ header-imm exit
\ : texit
\     dp @ thisxt @ <> if
\         prev @ jumpable if
\             prev
\             @
\             h# 4000 xor
\             prev !
\             \ dp @ syncpt @ <> if
\                 inline: exit
\             \ then
\             exit
\         then
\     then
\     inline: exit
\ ;

: prev
    dp @i d# 2 -
;

\ Do not handle ALU instructions for size reasons, as only negative literals and R-Stack cause ALUs to be compiled

header-imm exit
: texit
    fineforoptimisation @i
    if
      prev @ h# 4000 xor             
      dup h# e000 and
      if
        drop
      else
        prev _!
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

\ Represent forward branches in one word
\ using the high-3 bits for the branch type,
\ and low 13 bits for the address.
\ THEN does the work of extracting the pieces.

header-imm ahead
: tahead
    here h# 0000 w,
;

header-imm if
: tif
    here h# 2000 w,
;

header-imm then     ( addr -- )
: tthen
    here 2/
    swap +!
    \ sync
;

header-imm begin
: tbegin
    dp @i 2/
;

header-imm again
: tagain
    w,
;

header-imm until
: tuntil
    h# 2000 or w,
;

header does>
:noname
    r> 2/
    lastword @i
    >xt cell+  \ ready to patch the RETURN
    _!
;

header-imm recurse
:noname
    thisxt @i compile,
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
    r> rO @i >r >r
    over rO _!
    swap -
;

: do-common     \ common prefix for DO and ?DO
    leaves @i leaves off
    ['] (do) compile,
;

header-imm do
:noname
    do-common
: dotail
    tbegin
    inline: >r
;

header-imm leave
: leave
    inline: r>
: leave,
    dp @i
    leaves @i w,
    leaves _!
;

: (?do)  ( start-limit -- start-limit start=limit )
    d# 0 over=
;

header-imm ?do
:noname
    do-common
    ['] (?do) compile,
    tif leave, tthen
    dotail
;

\ Finish compiling DO..LOOP
\ resolve each LEAVE by walking the chain starting at 'leaves'
\ compile a call to (loopdone)

: resolveleaves
    leaves @i
    begin
        dup
    while
        dup @ swap        ( next leaveptr )
        here 2/
        swap _!
    repeat
    drop
    leaves _!
    ['] (loopdone) compile,
;

: (loopnext)
    d# 1 + d# 0 over=
;

header-imm loop
:noname
    inline: r>
    ['] (loopnext) compile,
    tuntil
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

header i
: i
    r>
    r@ rO @i +
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
    base _!
;

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
header io!      :noname     io!      ;
header io@      :noname     io@      ;
header depth    :noname     depth    ;
header-imm >r   :noname     inline: >r ;
header-imm r>   :noname     inline: r> ;
header-imm r@   :noname     inline: r@ ;
header cells    :noname     2*       ;
header char+    :noname     1+ ;
header chars    :noname     noop ;

: jumptable ( u -- ) \ add u to the return address
    r> + >r ;

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


: isvoid ( caddr u -- ) \ any char remains, throw -13
    nip 0<>
;fallthru
: -13throw ( a -- ) \ if a is nonzero, throw -13
    d# 13
;fallthru
: -throw ( a b -- ) \ if a is nonzero, throw -b
    negate and throw
;

header abort
: abort
    d# -1 throw
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
;fallthru
: return1
    d# 1
;

: base((doubleAlso))
    base @i >r setbase
    ((doubleAlso))
    r> setbase
;

: is' ( f caddr -- f' ) \ f remains true if caddr is '
    c@ [char] ' = and
;

: is'c' ( caddr u -- f )
    d# 3 =
    over is'
    swap d# 2 + is'
;

\   (doubleAlso) ( c-addr u -- x 1 | x x 2 )
\               If the string is legal, give a single or double cell number
\               and size of the number.

: (doubleAlso)
    [char] $ consume1 if
        d# 16 base((doubleAlso)) ;
    then
    [char] # consume1 if
        d# 10 base((doubleAlso)) ;
    then
    [char] % consume1 if
        d# 2 base((doubleAlso)) ;
    then
    2dup is'c' if
        drop 1+ c@ return1 ;
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
        h# 8000 or w,
    then
;

header-imm postpone
:noname
    parse-name sfind
    dup 0= -13throw
    0< if
        tliteral
        ['] compile,
    then
    compile,
;

header '
:noname
    parse-name
    sfind
    0= -13throw
;

header char
:noname
    parse-name drop c@
;

header-imm \
:noname
    sourceC @i >in _!
;

: doubleAlso,
    (doubleAlso)
    1- if
        swap tliteral
    then
    tliteral
;


: opticompile,  \ Classic compilation gives no pathological cases.
  compile,       \ Cannot handle this in compile, as some of the pathological cases use compile, themselves.
  true fineforoptimisation _!
;

\ Literals are fine for optimisation, too, but currently no optimisation cases handle literals.

: optiexecute   \ All pathological conditions are caused by immediate definitions.
  execute
  fineforoptimisation off
;

: dispatch
    jumptable ;fallthru
    jmp execute                 \      -1      0       non-immediate
    jmp doubleAlso              \      0       0       number
    jmp execute                 \      1       0       immediate

    jmp opticompile,            \      -1      2       non-immediate
    jmp doubleAlso,             \      0       2       number
    jmp optiexecute             \      1       2       immediate

: interpret
    begin
        parse-name
        dup
    while
        sfind
        state @i +
        1+ 2* dispatch
    repeat
    2drop
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
    tethered @i if d# 30 emit then
    
    >r d# 0  ( addr len R: maxlen )

    begin
        key    ( addr len key R: maxlen )
        
        d# 9 over= if drop d# 32 then
        d# 127 over= if drop d# 8 then
        
        dup d# 31 u>
        if
            over r@ u<
            if
                tethered @i 0= if dup emit then
                >r 2dup + r@ swap c! 1+ r>
            then
        then
        
        d# 8 over= if >r delchar r> then
          
        d# 10 over= swap d# 13 = or
    until
    
    rdrop nip
    space
;

header refill
: refill
    tib dup d# 128 accept
    source!
    true
;fallthru
: 0>in
    >in off
;

header evaluate
:noname
    source >r >r >in @i >r
    source! 0>in
    interpret
    r> >in _! r> r> source!
;

header quit
: quit
    begin
        refill drop
        interpret
            space
            [char] k
            [char] o 2emit
            cr
    again
;

: main
    cr
    decimal
    tethered off
    key> drop
    quit
;

meta
    link @ t' forth tw!
    there  t' dp tw!
target
