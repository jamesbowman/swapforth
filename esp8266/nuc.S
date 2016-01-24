        .section        .irom0.text

// The CALL0 c   ing convention is:
//
//      a0      Return address
//      a1      Stack pointer
//      a2-a7   Function args, scratch
//      a8      scratch
//      a12-a15 Callee-saved

// So SwapForth assigns

#define RTOS    a0      // return address
#define RSP     a1      // return stack pointer
#define TOS     a2      // top of data stack
#define DSP     a3      // data stack pointer
#define X0      a4      // temp reg
#define X1      a5      // temp reg
#define X2      a6      // temp reg
#define X3      a7      // temp reg
#define X4      a8      // temp reg
#define X5      a9      // temp reg
#define X6      a10     // temp reg
#define X7      a11     // temp reg
#define X8      a12     // temp reg
#define TRUE    a15     // constant -1

        .set    forth_link,0
        .equ    INLINE,1
        .equ    IMMEDIATE,2

        .macro  header   fname,label,immediate=0
        .section        .irom0.text
        .p2align  2
        .long   forth_link + \immediate
        .set    forth_link,.-4
        .byte   1f-.-1
        .ascii  "\fname"
1:
        .p2align  2
\label:
        .endm

        .macro  c       d
        call0   \d
        .endm

        .macro  prolog
        addi    RSP,RSP,-16
        s32i.n  a0,RSP,0
        .endm

        .macro  epilog
        l32i.n  a0,RSP,0
        addi    RSP,RSP,16
        ret
        .endm

        .macro  tail    d
        l32i.n  a0,RSP,0
        addi    RSP,RSP,16
        j       \d
        .endm

        .macro  dup
        addi    DSP,DSP,-4
        s32i    TOS,DSP,0
        .endm

        .macro  lit     v
        dup
        movi    TOS,\v
        .endm

        .macro  popX0
        l32i    X0,DSP,0
        addi    DSP,DSP,4
        .endm

        .macro  binop   op
        popX0
        \op     TOS,X0,TOS
        ret
        .endm

        .macro  _drop
        l32i    TOS,DSP,0
        addi    DSP,DSP,4
        .endm

        .macro  tosX0
        mov     X0,TOS
        _drop
        .endm

        .macro  to_r
        addi    RSP,RSP,-16
        s32i    TOS,RSP,0
        _drop
        .endm

        .macro  r_at
        dup
        l32i.n  TOS,RSP,0
        .endm

        .macro  r_from
        r_at
        addi    RSP,RSP,16
        .endm

        .macro  cmpop   op
        popX0
        b\op    X0,TOS,1f
        movi    TOS,0
        ret
1:
        movi    TOS,-1
        ret
        .endm

        .macro  icmpop  op
        popX0
        b\op    X0,TOS,1f
        movi    TOS,-1
        ret
1:
        movi    TOS,0
        ret
        .endm

// ====================   FORTH WORDS   =======================

// See p.598 of
//  Xtensa Instruction Set Architecture (ISA) Reference Manual
// which lists useful idioms

header  ".x",dotx
        prolog
        dup
        extui   TOS,TOS,28,4
        c       hex1
        dup
        extui   TOS,TOS,24,4
        c       hex1
        dup
        extui   TOS,TOS,20,4
        c       hex1
        dup
        extui   TOS,TOS,16,4
        c       hex1
        dup
        extui   TOS,TOS,12,4
        c       hex1
        dup
        extui   TOS,TOS,8,4
        c       hex1
        dup
        extui   TOS,TOS,4,4
        c       hex1
        extui   TOS,TOS,0,4
        c       hex1
        c       space
        epilog
hex1:
        blti    TOS,10,2f
        addi    TOS,TOS,'A'-'0'-10
2:      addi    TOS,TOS,'0'
        j       emit

header  "bye",bye
        j       abort
header  "emit",emit
        movi    X1,0x60000000
1:
        l32i    X0,X1,0x1c      // wait until TX fifo not full
        extui   X0,X0,16,8
        beqi    X0,0x80,1b
        s32i    TOS,X1,0         // transmit
        j       drop

header  "key",key
        j       abort

header  "depth",depth
        dup
        movi    X0,(dstk-4)
        sub     TOS,X0,DSP
        srai    TOS,TOS,2
        ret

header  "base",base
        lit     _base
        ret

header  ">in",to_in
        lit     _in
        ret

header  "source",source
        lit     _source
        j       two_fetch

header  "source-id",source_id
        j       abort

header "2*",two_times,INLINE
        add     TOS,TOS,TOS
        ret

header "2/",two_slash,INLINE
        srai    TOS,TOS,1
        ret

header "1+",one_plus,INLINE
        addi    TOS,TOS,1
        ret

header "1-",one_minus,INLINE
        addi    TOS,TOS,-1
        ret

header "0=",zero_equals,INLINE
        movnez  TOS,TRUE,TOS
        xor     TOS,TOS,TRUE
        ret

header "cell+",cell_plus,INLINE
        addi    TOS,TOS,4
        ret

header "cells",cells,INLINE
        slli    TOS,TOS,2
        ret

header "<>",not_equal,INLINE
        cmpop   ne

header "=",equal,INLINE
        cmpop   eq

header ">",greater,INLINE
        icmpop  lt

header "<",less,INLINE
        cmpop   lt

header "0<",less_than_zero,INLINE
        srai    TOS,TOS,31
        ret

header "0>",greater_than_zero,INLINE
        neg     TOS,TOS
        ret

header "0<>",not_equal_zero,INLINE
        movnez  TOS,TRUE,TOS
        ret

header "u<",unsigned_less,INLINE
        cmpop   ltu

header "u>",unsigned_greater,INLINE
        icmpop  ltu

header  "+",plus,INLINE
        binop   add

header  "s>d",s_to_d,INLINE
        dup
        srai    TOS,TOS,31
        ret

header  "d>s",d_to_s,INLINE
        j       drop

header  "m+",m_plus
        prolog
        c       s_to_d
        tail    d_plus

header  "d+",d_plus
        l32i    X0,DSP,0
        l32i    X1,DSP,4
        l32i    X2,DSP,8

        add     X0,X0,X2
        add     TOS,TOS,X1
        bgeu    X0,X2,1f
        addi    TOS,TOS,1
1:
        addi    DSP,DSP,8
        s32i    X0,DSP,0
        ret

header  "d=",d_equal
        j       abort

header  "du<",d_u_less
        j       abort

header  "d<",d_less
        j       abort

header  "d0<",d_less_than_zero
        j       abort

header  "dnegate",d_negate
        j       abort

header  "d-",d_minus
        j       abort

header  "d2*",d_two_times,INLINE
        j       abort

header  "d2/",d_two_slash,INLINE
        j       abort

header  "-",minus,INLINE
        binop   sub

header  "negate",negate,INLINE
        neg     TOS,TOS
        ret

header  "invert",invert,INLINE
        xor     TOS,TOS,TRUE
        ret

header  "and",and,INLINE
        binop   and

header  "or",or,INLINE
        binop   or

header  "xor",xor,INLINE
        binop   xor

header  "lshift",lshift,INLINE
        popX0
        ssl     TOS
        sll     TOS,X0
        ret

header  "rshift",rshift,INLINE
        popX0
        ssr     TOS
        srl     TOS,X0
        ret

header  "abs",_abs,INLINE
        abs     TOS,TOS
        ret

header  "um*",u_m_multiply,INLINE
        l32i    X0,DSP,0
        extui   X1,TOS,16,16
        extui   X2,X0,16,16
        mul16u  X3,TOS,X0               // lo part
        mul16u  X4,X1,X0
        mul16u  X5,TOS,X2
        mul16u  TOS,X1,X2               // hi part
        add     X5,X5,X4                // mid part
        bgeu    X5,X4,1f                // mid carry into hi
        movi    X4,0x10000
        add     TOS,TOS,X4
1:
        extui   X4,X5,16,16
        add     TOS,TOS,X4
        slli    X5,X5,16
        add     X3,X3,X5
        bgeu    X3,X5,1f
        addi    TOS,TOS,1
1:
        s32i    X3,DSP,0
        ret

header  "*",multiply,INLINE
        binop   mull

header  "/",divide
        j       abort

header  "mod",mod
        j       abort

header  "um/mod",u_m_slash_mod
        j       abort

header  "c@",c_fetch,INLINE
        l8ui    TOS,TOS,0
        ret

header  "c!",c_store,INLINE
        l32i    X0,DSP,0
        s8i     X0,TOS,0
        j       two_drop

header  "@",fetch,INLINE
        l32i    TOS,TOS,0
        ret

header  "!",store,INLINE
        l32i    X0,DSP,0
        s32i    X0,TOS,0
        j       two_drop

header  "2@",two_fetch,INLINE
        l32i    X0,TOS,4
        l32i    TOS,TOS,0
        addi    DSP,DSP,-4
        s32i    X0,DSP,0
        ret

header  "2!",two_store,INLINE
        l32i    X0,DSP,0
        s32i    X0,TOS,0
        l32i    X0,DSP,4
        s32i    X0,TOS,4

        l32i    TOS,DSP,8
        addi    DSP,DSP,12
        ret

header  "/string",slash_string
        prolog
        mov     X0,TOS
        c       drop
        l32i    X1,DSP,0
        add     X1,X1,X0
        s32i    X1,DSP,0
        sub     TOS,TOS,X0
        epilog

header  "swap",swap,INLINE
        l32i    X0,DSP,0
        s32i    TOS,DSP,0
        mov     TOS,X0
        ret

header  "over",over,INLINE
        dup
        l32i    TOS,DSP,4
        ret

header "false",false,INLINE
        lit     0
        ret

header "true",true,INLINE
        lit     -1
        ret

header "bl",_bl,INLINE
        lit     ' '
        ret

header "rot",rot,INLINE
        l32i    X0,DSP,0
        s32i    TOS,DSP,0
        l32i    TOS,DSP,4
        s32i    X0,DSP,4
        ret

header "noop",noop
        ret

header "-rot",minus_rot,INLINE
        l32i    X0,DSP,0
        l32i    X1,DSP,4

        s32i    TOS,DSP,4
        s32i    X1,DSP,0
        mov     TOS,X0
        ret

header "tuck",tuck
        prolog
        c       swap
        c       over
        epilog

header "?dup",question_dupe
        beqz    TOS,1f
        dup
1:      ret

header "2dup",two_dup,INLINE
        prolog
        c       over
        tail    over

header "+!",plus_store,INLINE
        l32i    X0,DSP,0
        l32i    X1,TOS,0
        add     X1,X1,X0
        s32i    X1,TOS,0
        j       two_drop

header "2swap",two_swap,INLINE
        // rot >r rot r>
        prolog
        c       rot
        to_r
        c       rot
        r_from
        epilog

header "2over",two_over,INLINE
        dup
        l32i    TOS,DSP,8
        dup
        l32i    TOS,DSP,8
        ret

header "min",min,INLINE
        popX0
        blt     TOS,X0,1f
        mov     TOS,X0
1:      ret

header "max",max,INLINE
        popX0
        bge     TOS,X0,1f
        mov     TOS,X0
1:      ret

header  "space",space
        lit     ' '
        j       emit

header  "cr",cr
        prolog
        lit     '\r'
        c       emit
        lit     '\n'
        c       emit
        epilog

header "count",count,INLINE
        mov     X0,TOS
        addi    TOS,TOS,1
        dup
        l8ui    TOS,X0,0
        ret

header "dup",dupe,INLINE
        dup
        ret

header "drop",drop,INLINE
        l32i    TOS,DSP,0
        addi    DSP,DSP,4
        ret

header  "nip",nip,INLINE
        addi    DSP,DSP,4
        ret

header "2drop",two_drop,INLINE
        l32i    TOS,DSP,4
        addi    DSP,DSP,8
        ret

header "execute",execute
        mov     X0,TOS
        _drop
        jx      X0

header "bounds",bounds,INLINE
        j       abort

header "type",type
        prolog
1:      beqz    TOS,2f
        c       over
        c       c_fetch
        c       emit
        lit     1
        c       slash_string
        j       1b
2:      c       two_drop
        epilog

// ( addr -- addr' ) advance to next word in dictionary
nextword:
        l32i    TOS,TOS,0
        movi    X0,~3
        and     TOS,TOS,X0
        ret

// SFIND
//         ( c-addr u -- c-addr u 0 | xt 1 | xt -1 )
// 
//         Find the definition named in the string at c-addr. If the
//         definition is not found, return c-addr and zero. If the definition
//         is found, return its execution token xt. If the definition is
//         immediate, also return one (1), otherwise also return minus-one
//         (-1).

header  "sfind",sfind
        prolog
        dup
        lit     _wbuf
        c       c_store

        c       two_dup
        lit     _wbuf+1
        c       swap
        c       cmove

        lit     _forth
2:
        c       nextword
        beqz    TOS,1f
        movi    X0,_wbuf
        l32i    X0,X0,0
        l32i    X1,TOS,4
        bne     X0,X1,2b

        c       nip
        c       nip
        dup
        // TOS is address of word. Go to XT
        l32i    X0,TOS,4
        extui   X0,X0,0,8
        addi    X0,X0,5
        add     TOS,TOS,X0
        c       aligned
        c       swap
        l32i    TOS,TOS,0
        extui   TOS,TOS,0,1     // immediate: 1, otherwise 0
        add     TOS,TOS,TOS     // immediate: 2, otherwise 0
        addi    TOS,TOS,-1      // immediate: 1, otherwise -1

1:
        epilog

header  "words",words
        prolog
        lit     _forth
2:      c       nextword
        beqz    TOS,1f
        dup
        c       cell_plus
        movi    X0,_wbuf

        l32i    X1,TOS,0
        s32i    X1,X0,0
        l32i    X1,TOS,4
        s32i    X1,X0,4
        l32i    X1,TOS,8
        s32i    X1,X0,8
        l32i    X1,TOS,12
        s32i    X1,X0,12
        l32i    X1,TOS,16
        s32i    X1,X0,16
        l32i    X1,TOS,20
        s32i    X1,X0,20
        l32i    X1,TOS,24
        s32i    X1,X0,24
        l32i    X1,TOS,28
        s32i    X1,X0,28
        c       drop

        lit     _wbuf
        c       count
        c       type
        c       space

        j       2b
1:
        tail    drop

header "accept",accept
        j       abort

header  "refill",refill
        j       abort

// \ From Forth200x - public domain
// 
// : isspace? ( c -- f )
//     h# 21 u< ;

isspace:
        lit     0x21
        j       unsigned_less

// 
// : isnotspace? ( c -- f )
//     isspace? 0= ;

isnotspace:
        prolog
        c       isspace
        tail    zero_equals
// 
// : xt-skip   ( addr1 n1 xt -- addr2 n2 ) \ gforth
//     \ skip all characters satisfying xt ( c -- f )
//     >r
//     BEGIN
//         over c@ r@ execute
//         overand
//     WHILE
//         d# 1 /string
//     REPEAT
//     r> drop ;

xt_skip:
        prolog
        to_r
0:
        c       over
        c       c_fetch
        r_at
        c       execute
        c       over
        c       and
        tosX0
        beqz    X0,1f
        lit     1
        c       slash_string
        j       0b
1:
        r_from
        tail    drop
// 
// header parse-name
// : parse-name ( "name" -- c-addr u )
//     source >in @ /string
//     ['] isspace? xt-skip over >r
//     ['] isnotspace? xt-skip ( end-word restlen r: start-word )
//     2dup d# 1 min + source drop - >in !
//     drop r> tuck -
// ;

header  "parse-name",parse_name
        prolog
        c       source
        c       to_in
        c       fetch
        c       slash_string
        lit     isspace
        c       xt_skip
        c       over
        to_r
        lit     isnotspace
        c       xt_skip
        c       two_dup
        lit     1
        c       min
        c       plus
        c       source
        c       drop
        c       minus
        c       to_in
        c       store
        c       drop
        r_from
        c       tuck
        c       minus
        epilog

// : digit? ( c -- u f )
//    lower
//    dup h# 39 > h# 100 and +
//    dup h# 160 > h# 127 and - h# 30 -
//    dup base @i u<
// ;
isdigit:
        prolog
        movi    X0,'A'
        movi    X1,'Z'+1
        blt     TOS,X0,1f
        bge     TOS,X1,1f
        addi    TOS,TOS,0x20
1:
        c       dupe
        lit     0x39
        c       greater
        lit     0x100
        c       and
        c       plus

        c       dupe
        lit     0x160
        c       greater
        lit     0x127
        c       and
        c       minus
        lit     0x30
        c       minus

        c       dupe
        c       base
        c       fetch
        tail    unsigned_less

// : >number ( ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
//     begin
//         dup
//     while
//         over c@ digit?
//         0= if drop ; then
//         >r 2swap base @i
//         \ ud*
//         tuck * >r um* r> +
//         r> m+ 2swap
//         1/string
//     repeat
// ;
header  ">number",to_number
        prolog
0:
        beqz    TOS,1f

        c       over
        c       c_fetch
        c       isdigit

        tosX0
        bnez    X0,2f
        tail    drop
2:

        to_r
        c       two_swap
        c       base
        c       fetch

        c       tuck
        c       multiply
        to_r
        c       u_m_multiply
        r_from
        c       plus

        r_from

        c       m_plus
        c       two_swap

        lit     1
        c       slash_string
        j       0b
1:
        epilog


header  "abort",abort
        c       cr
        lit     'A'
        c       emit
        lit     'B'
        c       emit
        lit     'O'
        c       emit
        lit     'R'
        c       emit
        lit     'T'
        c       emit
        c       cr

1:
        j       1b

header  "postpone",postpone,IMMEDIATE
        j       abort

header  "parse",parse
        j       abort

header  "throw",throw
        j       abort

header  "evaluate",evaluate
        j       abort

header  "here",here
        j       abort

header  "dp",dp
        j       abort

header  "chere",chere
        j       abort

header  "cp",cp
        j       abort

header  "forth",forth
        lit     _forth
        ret

header  "state",state
        j       abort

header  "unused",unused
        j       abort

header  "aligned",aligned
        addi    TOS,TOS,3
        srli    TOS,TOS,2
        slli    TOS,TOS,2
        ret

header  ",",comma
        j       abort

header  "c,",c_comma
        j       abort

header  "s,",s_comma
        j       abort

header  ">r",to_r,IMMEDIATE
        j       abort

header  "2>r",two_to_r,IMMEDIATE
        j       abort

header  "r>",r_from,IMMEDIATE
        j       abort

header  "2r>",two_r_from,IMMEDIATE
        j       abort

header  "r@",r_at,IMMEDIATE
        j       abort

header  "2r@",two_r_at
        j       abort

header  "code.,",code_comma
        j       abort

header  "code.c,",code_c_comma
        j       abort

header  "code.s,",code_s_comma
        j       abort

header  ":noname",colon_noname
        j       abort

header  ":",colon
        j       abort

header  ";",semi_colon,IMMEDIATE
        j       abort

header  "exit",exit,IMMEDIATE
        j       abort

header  "immediate",immediate
        j       abort

header  "noinline",noinline
        j       abort

header  "does>",does
        j       abort

header  "[",left_bracket,IMMEDIATE
        j       abort

header  "]",right_bracket
        j       abort

header  "literal",literal,IMMEDIATE
        j       abort

header  "compile,",compile_comma
        j       abort

header  "2literal",two_literal,IMMEDIATE
        j       abort

header  "cmove",cmove
        l32i    X0,DSP,0
        l32i    X1,DSP,4
        add     TOS,TOS,X0
        // Now bytes from X1 to X0 until X0 reaches TOS
        j       2f
1:
        l8ui    X2,X1,0
        s8i     X2,X0,0
        addi    X0,X0,1
        addi    X1,X1,1
2:
        bne     TOS,X0,1b
three_drop:
        l32i    TOS,DSP,8
        addi    DSP,DSP,12
        ret

header  "cmove>",cmove_up
        j       abort

header  "fill",fill
        j       abort

header  "begin",begin,IMMEDIATE
        j       abort

header  "ahead",ahead,IMMEDIATE
        j       abort

header  "if",if,IMMEDIATE
        j       abort

header  "then",then,IMMEDIATE
        j       abort

header  "again",again,IMMEDIATE
        j       abort

header  "until",until,IMMEDIATE
        j       abort

header  "recurse",recurse,IMMEDIATE
        j       abort

header  "do",do,IMMEDIATE
        j       abort

header  "?do",question_do,IMMEDIATE
        j       abort

header  "leave",leave,IMMEDIATE
        j       abort

header  "loop",loop,IMMEDIATE
        j       abort

header  "+loop",plus_loop,IMMEDIATE
        j       abort

header  "unloop",unloop,IMMEDIATE
        j       abort

header  "i",i,IMMEDIATE
        j       abort

header  "j",j
        j       abort

header  "decimal",decimal
        movi    X0,10
        movi    X1,_base
        s32i    X0,X1,0
        ret

snap:
        c       cr
        c       depth
        c       dotx
        c       space
        j       2f
1:
        c       dotx
2:
        c       depth
        tosX0
        bnez    X0,1b
3:
        j       3b

        .p2align        2
        .long   execute
dispatch:
        .long   snap
        .long   execute

interpret:
        prolog
0:
        c       parse_name
        beqz    TOS,1f
        c       sfind
        c       cells
        lit     dispatch
        c       plus
        c       fetch
        c       execute
        j       0b
1:      c       two_drop
        epilog

        .p2align  2
.global swapforth
swapforth:
        prolog
        s32i    a15,a1,4                // {

        movi    DSP,dstk
        movi    TRUE,-1

        c       decimal
        c       cr
        c       cr

        lit     0
        lit     0
        lit     nnnn
        lit     17
        c       to_number
        c       dotx
        c       dotx
        c       dotx
        c       dotx

        lit     ssss
        lit     14
        lit     _source
        c       two_store

        lit     0
        lit     _in
        c       store

        c       interpret

        c       depth
        l32i    a15,a1,4                // }
        epilog

        .section        .data
_base:  .long   0
_forth: .long   forth_link
_in:    .skip   4
_source:
        .skip   8
_wbuf:  .skip   32

ssss:   .string         "words cr 12345"
tttt:
nnnn:   .string         "1234567812345678."
        .p2align        2
        .skip           512
dstk:
