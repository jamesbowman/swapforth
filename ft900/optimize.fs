variable optimizer
true optimizer !

get-order wordlist swap 1+ set-order definitions

: 2array
    create 2* cells allot
    does>  swap 2* cells +
;

defer docall    ' compile, cell+ is docall
defer doliteral ' literal  cell+ is doliteral
: doif
    [ ' (if) 2 cells + compile, ]
;

5 2array peep
variable nact 0 nact !

: stackword  ( xt -- f )
    false            ( xt false )
    over ['] >r = or
    over ['] r> = or
    over ['] r@ = or
    over ['] 2>r = or
    over ['] 2r> = or
    over ['] 2r@ = or
    over ['] j = or
    over ['] unloop = or
    nip
;

: caninline  ( xt -- f )
    cell+ pm@ $a0000000 =
;

: consume   \ remove the oldest entry in the peep
    1 peep 0 peep 6 cells move
    -1 nact +!
;

: cmpword  ( xt -- f )
    false            ( xt false )
    over ['] =      = or
    over ['] <>     = or
    over ['] >      = or
    over ['] <      = or
    nip
;

: dojmpc  ( dst xt -- )
    case
    ['] =   of [ also assembler ] nz    [ previous ] endof
    ['] <>  of [ also assembler ] z     [ previous ] endof
    ['] >   of [ also assembler ] lte   [ previous ] endof
    ['] <   of [ also assembler ] gte   [ previous ] endof
    endcase
    [ also assembler ] jmpc, [ previous ]
;

\ Matching keeps a matchptr into the peephole buffer, and
\ the current match status on the top of stack
\ After a match sequence, e.g.
\
\    m: <lit> <comparison-word> <if>
\
\ the match status is on top of the stack.
\
\ Many match-words save an argument for later use in a value:
\
\ <lit>     %lit, %prevlit
\ <*-word>  %word
\ <if>      %label

0 value matchptr
0 value %prevlit
0 value %lit
0 value %word
0 value %label

: m:
    0 peep to matchptr
    0 nact @ peep !     \ 0 entry to prevent any match
    true
;

: matchup ( f1 f2 -- f3 )  \ continue to next match, f3 if f1 and f2
    matchptr 2 cells + to matchptr
    and
;

: pat ( xt -- u )
    pm@ 27 rshift
;

: <lit>  ( f -- f )
    %lit to %prevlit
    matchptr 2@
    ['] doliteral = if
        dup to %lit
        -524288 524288 within
    else
        drop
        matchptr @ ['] docall =
        if
            matchptr cell+ @ >r
            r@ pm@ ['] depth pm@ =
            r@ cell+ pat 12 = and       \ ldk
            r@ cell+ cell+ pat 20 = and \ return
            r> cell+ pm@ $fffff and to %lit
        else
            false
        then
    then
    matchup
;

: <lit0>
    <lit>
    %lit 0= and
;

: <any-word>  ( f -- f )
    matchptr 2@
    swap to %word
    ['] docall =
    matchup
;

: <nonstack-word>  ( f -- f )
    <any-word>
    %word stackword 0= and
;

: <2fold-word>
    <any-word>
    %word case
        ['] and     of true endof
        ['] lshift  of true endof
        ['] rshift  of true endof
        ['] +       of true endof
        ['] -       of true endof
        ['] *       of true endof
                       false swap
    endcase
    and
;

: <inline-word>  ( f -- f )
    <any-word>
    %word caninline and
;

: <exit>  ( f -- f )
    matchptr 2@
    $a0000000 ['] pm, d=
    matchup
;

: <if>  ( f -- f )
    matchptr 2@
    swap to %label
    ['] doif =
    matchup
;

: <cmp>
    <any-word>
    %word cmpword and
;

: a-word  ( f xt -- f )      \ match a specific word xt
    ['] docall matchptr 2@ d=
    matchup
;

: <and>     ['] and  a-word ;
: <0=>      ['] 0=   a-word ;
: <dup>     ['] dup  a-word ;
: <over>    ['] over a-word ;
: <drop>    ['] drop a-word ;
: <swap>    ['] swap a-word ;
: <c!>      ['] c!   a-word ;
: <!>       ['] !   a-word ;
: <i>       ['] i    a-word ;
: <->       ['] -    a-word ;
: <>r>      ['] >r   a-word ;
: <r@>      ['] r@   a-word ;
: <dwrite>  ['] digitalWrite    a-word ;

: <=>
    matchptr 2@
    ['] = ['] docall d=
    matchup
;

: <+>
    matchptr 2@
    ['] + ['] docall d=
    matchup
;

: matched
    matchptr 0 peep - 3 rshift
    0 do
        consume
    loop
;

: rimm ( x -- )
    dup -512 512 within if
        [ also assembler ] # [ previous ]
    else
        [ also assembler ] r1 ldk,  r1 [ previous ]
    then
;

: pinmask  ( -- bitpos reg port )
    %lit 31 and 32 or
    %lit 5 rshift 20 +
    %lit 5 rshift cells $10084 +
;

: lit-dwrite  \ compile 3 instructions to write TOS to a GPIO
    [ also assembler ]
    pinmask >r >r
    # r0 r1 ldl,
    r1 r@ r@ bins,
    r> r> sta,
    [ previous ]
;

: litcmp,
    %lit rimm [ also assembler ] r0 cmp,  [ previous ]
;

: shift
    optimizer @ if
        m: <nonstack-word> <exit>
        if
            %word [ also assembler ] jmp, [ previous ]
            matched exit
        then

        m: <inline-word>
        if
            %word pm@ pm,
            matched exit
        then

        m: <lit> <cmp> <if>
        if
            litcmp,
            ['] drop docall
            %label %word dojmpc
            matched exit
        then

        m: <dup> <lit> <cmp> <if>
        if
            litcmp,
            %label %word dojmpc
            matched exit
        then

        m: <lit> <over> <=> <if>
        if
            litcmp,
            [ also assembler ] %label nz jmpc, [ previous ]
            matched exit
        then

        m: <lit> <and> <0=> <if>
        if
            %lit rimm [ also assembler ] r0 tst, [ previous ]
            ['] drop docall
            [ also assembler ] %label nz jmpc, [ previous ]
            matched exit
        then

        m: <dup> <0=> <if>
        if
            [ also assembler ] 0 # r0 cmp, [ previous ]
            [ also assembler ] %label nz jmpc, [ previous ]
            matched exit
        then

        m: <dup> <if>
        if
            [ also assembler ] 0 # r0 cmp, [ previous ]
            [ also assembler ] %label z jmpc, [ previous ]
            matched exit
        then

        m: <cmp> <if>
        if
            ['] cmp_cc docall
            %label %word dojmpc
            matched exit
        then

        m: <lit> <any-word>
        if
            %word case
            ['] and     of %lit rimm [ also assembler ] r0 r0 and,  [ previous ] matched exit endof
            ['] lshift  of %lit rimm [ also assembler ] r0 r0 ashl, [ previous ] matched exit endof
            ['] rshift  of %lit rimm [ also assembler ] r0 r0 lshr, [ previous ] matched exit endof
            ['] +       of %lit rimm [ also assembler ] r0 r0 add,  [ previous ] matched exit endof
            ['] -       of %lit rimm [ also assembler ] r0 r0 sub,  [ previous ] matched exit endof
            ['] *       of %lit rimm [ also assembler ] r0 r0 mul,  [ previous ] matched exit endof
            ['] c@      of
                            ['] dup docall
                            %lit [ also assembler ] r0 lda.b, [ previous ]
                            matched exit
                        endof
            ['] @       of
                            ['] dup docall
                            %lit [ also assembler ] r0 lda, [ previous ]
                            matched exit
                        endof
            ['] !       of
                            [ also assembler ] r0 %lit sta, [ previous ]
                            ['] drop docall
                            matched exit
                        endof
            ['] c!      of
                            [ also assembler ] r0 %lit sta.b, [ previous ]
                            ['] drop docall
                            matched exit
                        endof
            endcase
        then

        m: <dup> <>r>
        m: <>r> <r@> or
        if
            [ also assembler ] r0 push, [ previous ]
            matched exit
        then

        m: <over> <+>
        if
            [ also assembler ]
            0 dsp r1 ldi,
            r1 r0 r0 add,
            [ previous ]
            matched exit
        then

        m: <lit0> <swap> <c!>
        if
            [ also assembler ] r0 0 r25 sti.b, [ previous ]
            ['] drop docall
            matched exit
        then

        m: <i> <->
        if
            [ also assembler ]
            r29 r28 r1 add,
            r1 r0 r0 sub,
            [ previous ]
            matched exit
        then

        m: <i> <+>
        if
            [ also assembler ]
            r29 r28 r1 add,
            r1 r0 r0 add,
            [ previous ]
            matched exit
        then

        m: <lit> <lit> <dwrite>
        if
            [ also assembler ]
            \ pin is in %lit, value is %prevlit
            pinmask >r >r
            %prevlit 9 lshift or
            # r@ r@ bins,
            r> r> sta,
            [ previous ]
            matched exit
        then

        m: <lit> <dwrite>
        if
            lit-dwrite
            ['] drop docall
            matched exit
        then

        m: <dup> <lit> <dwrite>
        if
            lit-dwrite
            matched exit
        then

        m: <lit> <lit> <2fold-word>
        if
            %prevlit %lit
            %word execute
            doliteral
            matched exit
        then

        m: <lit> <lit> <c!>
        if
            [ also assembler ]
            %prevlit r1 ldk,
            r1 %lit sta.b,
            [ previous ]
            matched exit
        then

        m: <lit> <lit> <!>
        if
            [ also assembler ]
            %prevlit r1 ldk,
            r1 %lit sta,
            [ previous ]
            matched exit
        then

        m: <lit0>
        if
            ['] false docall
            matched exit
        then

        m: <lit> <lit>
        if
            [ also assembler ]
            %prevlit r1 ldk,
            %lit r2 ldk,
            [ previous ]
            ['] 2lit docall
            matched exit
        then

        m: <drop> <lit>
        if
            [ also assembler ] %lit r0 ldk, [ previous ]
            matched exit
        then
    then

    nact @ if
        0 peep 2@ execute
        consume
    then
;

: append ( arg xt -- )
    nact @ 4 = if
        shift
    then
    nact @ peep 2!
    1 nact +!
;

: flush
    begin
        nact @
    while
        shift
    repeat
;

\ : action?
\     hex
\     nact @ 0 ?do
\         cr i . i peep 2@ .xt u.
\     loop
\ ;

\ Careful here. Change compilation vectors all in one fell swoop
\ to avoid compiling with a partial set.

:noname
    flush
; ' sync 
:noname
    ['] pm, append
; ' code,
:noname
    ['] docall append
; ' compile,
:noname
    ['] doliteral append
; ' literal
:noname
    ['] doif    append
; ' (if)
defer!
defer! defer! defer! defer!

depth throw
\ : x = if cr then ; see x
\ : x > if cr then ; see x
\ : x 77 = if cr then ; see x
\ : FIB ( n -- n' ) DUP 1 > IF DUP 1- RECURSE  SWAP 2-  RECURSE  + THEN ;
\ : x 3 [ m: <lit> . %lit .
\ : x bl [ m: <lit> cr . %lit .
\ : x bl = if cr then ; see x
\ : x 0 7 digitalWrite ; see x
\ bye

previous definitions
