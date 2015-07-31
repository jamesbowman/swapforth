\ #######   ASSEMBLER   #######################################

\ Based on "Build Your Own (Cross-) Assembler....in Forth"
\ by Brad Rodriguez
\
\ http://www.bradrodriguez.com/papers/tcjassem.txt

\ PUBLICWORDS

: assembler ( -- ) \ Replace the first word list in the search order with the ASSEMBLER word list
    get-order nip
    [ wordlist ] literal swap
    set-order
;

: code ( "<spaces>name" -- ) \ begin the definition of an assembly word
    :
    also assembler
    postpone [
;

: codenoname ( -- xt ) \ the assembly equivalent of \word{:NONAME}
    :noname
    also assembler
    postpone [
;

: ;code ( -- ) \ the assembly equivalent of \word{DOES>}
    postpone does>
    sync
    also assembler
    postpone [
; immediate

: end-code ( -- ) \ end an assembly definition
    smudge
    previous
;

also assembler definitions

: r0   0 ;
: r1   1 ;
: r2   2 ;
: r3   3 ;
: r4   4 ;
: r5   5 ;
: r6   6 ;
: r7   7 ;
: r8   8 ;
: r9   9 ;
: r10 10 ;
: r11 11 ;
: r12 12 ;
: r13 13 ;
: r14 14 ;
: r15 15 ;
: r16 16 ;
: r17 17 ;
: r18 18 ;
: r19 19 ;
: r20 20 ;
: r21 21 ;
: r22 22 ;
: r23 23 ;
: r24 24 ;
: r25 25 ;
: r26 26 ;
: dsp 27 ;
: r28 28 ;
: r29 29 ;
: cc  30 ;
: sp  31 ;

: pat,    27 lshift or pm, ;

: field
  create ,
  does>
    @       ( fv x pos )    \ shift fv to pos, merge with x 
    rot swap lshift or
;

4 field R_2
15 field R_1
20 field Rd
22 field Cb
20 field Cr
19 field Cv
18 field Bt

: Pa
    >r 2/ 2/ r> or
;

: AA
    swap $1ffff and or
;

: K8
    swap $ff and or
;

: #
    1023 and
    1024 or
;

: dw.b
;

: dw.s
    [ 1 25 lshift ] literal xor
;

: dw.l
    [ 2 25 lshift ] literal xor
;

: aluop,
    dw.l
    Rd R_1 R_2
    8 pat,
;

: cmpop,
    dw.l
    cc swap Rd
    R_1 R_2     11 pat,
;

: ffuop,
    dw.l
    Rd R_1 R_2
    30 pat,
;

: ffuop.b,
    dw.b
    Rd R_1 R_2
    30 pat,
;

: ffuop2,
    dw.l
    Rd R_1
    30 pat,
;

: toc,    0 Bt Cv Cr Cb Pa    0 pat, ;
: toci,   0 Bt Cv Cr Cb Pa   1 pat, ;

: cond  ( Cb Cv )
    create , ,
    does> 2@ 2 swap
;
    
5 1 cond gt
4 1 cond gte
4 0 cond lt
5 0 cond lte
6 1 cond a
1 0 cond ae
6 0 cond be
1 1 cond b
0 0 cond nz
0 1 cond z
1 0 cond nc
1 1 cond c
2 0 cond no
2 1 cond o
3 0 cond ns
3 1 cond s
: uncond    \ unconditional jump/call
    0 3 0
;

: add,      0 aluop, ;
: ror,      1 aluop, ;
: sub,      2 aluop, ;
: ldl,      3 aluop, ;
: and,      4 aluop, ;
: or,       5 aluop, ;
: xor,      6 aluop, ;
: xnor,     7 aluop, ;
: ashl,     8 aluop, ;
: lshr,     9 aluop, ;
: ashr,     10 aluop, ;
: bins,     11 aluop, ;
: bexts     12 aluop, ;
: bextu     13 aluop, ;
: flip      14 aluop, ;

: addcc,    0 cmpop, ;
: cmp,      2 cmpop, ;
: tst,      4 cmpop, ;
: btst,     12 cmpop, ;

: udiv,     0 ffuop, ;
: umod,     1 ffuop, ;
: div,      2 ffuop, ;
: mod,      3 ffuop, ;
: strcmp,   4 ffuop, ;
: memcpy,   5 ffuop, ;
: strlen,   6 ffuop2, ;
: memset,   7 ffuop, ;
: mul,      8 ffuop, ;
: muluh,    9 ffuop, ;
: stpcpy,   10 ffuop2, ;
: streamin, 12  ffuop, ;
: streamin.b, 12  ffuop.b, ;
: streamini, 13  ffuop, ;
: streamout, 14  ffuop, ;
: streamout.b, 14  ffuop.b, ;
: streamouti, 15  ffuop, ;

: return,   0 20 pat, ;

: jmpc,     0 toc, ;
: jmp,      uncond jmpc, ;
: callc,    1 toc, ;
: call,     uncond callc, ;
: jmpic,    0 toci, ;
: jmpi,     uncond jmpic, ;
: callic,   1 toci, ;
: calli,    uncond callic, ;

: push,     0 R_1 dw.l 16 pat, ;
: pop,      0 Rd  dw.l 17 pat, ;
: ldk,      swap $fffff and Rd  dw.l 12 pat, ;
: lda,      swap $1ffff and Rd  dw.l 24 pat, ;
: lda.b,    swap $1ffff and Rd  dw.b 24 pat, ;
: ldi,      0 Rd R_1 K8         dw.l 21 pat, ;
: ldi.b,    0 Rd R_1 K8         dw.b 21 pat, ;
: sti,      0 R_1 K8 Rd         dw.l 22 pat, ;
: sti.b,    0 R_1 K8 Rd         dw.b 22 pat, ;
: sta,      0 AA Rd             dw.l 23 pat, ;
: sta.b,    0 AA Rd             dw.b 23 pat, ;

\ These are not actual opcodes, but useful

: move,     0 # -rot add, ;
: inc,      1 # swap dup add, ;
: dec,      1 # swap dup sub, ;

: notcc     1 xor ;

: begin     pmhere ;
: again     jmp, ;
: until     notcc jmpc, ;
: ahead
    pmhere
    0 jmp,
;

: if       ( cb cr cv -- )
    pmhere >r
    >r 0 -rot r>    \ branch target
    notcc jmpc,
    r>
;

: then     ( a -- )
    pmhere 2 rshift
    swap
    tuck pm@ + swap pm!
;

: else
    ahead
    swap
    then
;

: while
      if
      swap
;

: repeat
     again
     then
;

previous definitions

marker testing-assembler

    code smoke
        ' dup call,
        r5 r6 r7 ror,
        $aa00 0 3 0 0  toc,
        $100 jmp,
        $200 call,
        $300 z jmpc,
        13 # r0 r0 add,
        r11 r7 cmp,
        r10 push,
        r11 pop,
        13 # r0 r0 udiv,
        begin
            4 # r1 r2 streamout, 
        nz until
        ae if
            r1 r2 r3 sub,
        else
            r1 r2 r3 xor,
        then
        
        begin
            100 # r1 cmp,
        lt while
            1 # r1 r1 add,
        repeat

        return,
    end-code

    code 17*    ( u0 -- u1 ) \ multiply by 17
        4 # r0 r1 ashl,
        r1 r0 r0 add,
        return,
    end-code

    t{ 100 17* -> 1700 }t

    code 17**   ( u0 -- u1 ) \ raise 17 to power of u0
        r0 r2 move,
        1 r0 ldk,
        begin
            0 # r2 cmp,
        nz while
            ' 17* call,
            r2 dec,
        repeat
        return,
    end-code

    t{ 0 17** -> 1 }t
    t{ 1 17** -> 17 }t
    t{ 7 17** -> 410338673 }t

    \ Use ;code to make a counter constructor
    : counter
        create ,
        ;code
              0 r0 r1 ldi,
            1 # r1 r1 add,
              r0 0 r1 sti,
                r1 r0 move,
                      return,
    end-code

    T{ 100 counter a -> }T
    T{ 200 counter b -> }T
    T{ a a a -> 101 102 103 }T
    T{ b b b -> 201 202 203 }T
    T{ a b -> 104 204 }T
        
testing-assembler
