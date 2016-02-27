// The CALL0 calling convention is:
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
#define CTX     a12     // context pointer
#define LPC     a13     // loop count
#define LPO     a14     // loop offset
#define TRUE    a15     // constant -1

        .set    ramhere,0

        .macro  allot   name size
        .equ    \name,ramhere
        .set    ramhere,ramhere+\size
        .endm

        allot   context_0,0
        allot   _dp,4           /* RAM data pointer */
        allot   _cp,4           /* Code pointer */
        allot   _forth,4        /* Dictionary pointer */
        allot   kpool,4         /* Constant pool */
        allot   aname,32        /* name buffer, used during dictionary search */
        allot   sourceA,4       /* tib+1 */
        allot   sourceC,4
        allot   _in,4           /* >IN */
        allot   _inwas,4        /* >IN at start of previous word */
        allot   recent,4        /* most recent CREATE */
        allot   thisxt,4        /* most recent xt */
        allot   attachpt,4      /* attach point for ; */
        allot   leaves,4*8      /* chain of LEAVE pointers */
        allot   leaveptr,4      /* Current LEAVE */
        allot   delim,4
        allot   _source_id,4
        allot   _state,4
        allot   _base,4
        allot   _tethered,4
        allot   oburn,4         /* burn offset */

        allot   _dsp,4
        allot   _lpc,4
        allot   _lpo,4
        allot   _rsp,4
        allot   _rdepth,4
        allot   _pc,4
        allot   _rstk,(4*32)

        allot   tib,256         /* terminal input buffer */
        allot   burn,1024       /* flash burn area */

        .if 0
        allot   cwl,4           /* Compilation word list */
        allot   wordlists,4     /* All word lists */
        allot   nsearch,4       /* Number of word lists in searchlist */
        allot   searchlist,4*16 /* search list */
        allot   context_1,0
        allot   forth,8         /* Forth word list */
        allot   internal,8      /* Internal word list */
        allot   handler,4       /* exception handler */
        .endif

        .set    forth_link,0
        .equ    INLINE,2
        .equ    IMMEDIATE,1

        .macro  noheader label
        .section        .irom0.text
        .p2align  2
\label:
        .endm

        .macro  header   fname,label,immediate=0
        .section        .irom0.text
        .p2align  2
        .long   forth_link + (\immediate ^ 1)
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

        // prolog, epilog 
        // are the entry/exit sequences for non-leaf words

        .macro  prolog
        addi    RSP,RSP,-4
        s32i    a0,RSP,0
        .endm

        .macro  epilog
        l32i    a0,RSP,0
        addi    RSP,RSP,4
        ret
        .endm

        .macro  tail    d
        l32i.n  a0,RSP,0
        addi    RSP,RSP,4
        j       \d
        .endm

        // prologL, epilogL are
        // as above but also preserving the C callee-saved
        // registers a12-15
        //
        .macro  prologL
        addi    RSP,RSP,-32
        s32i    a0,RSP,0
        s32i    LPC,RSP,4
        s32i    LPO,RSP,8
        s32i    a15,RSP,12
        s32i    CTX,RSP,16
        .endm

        .macro  epilogL
        l32i    a0,RSP,0
        l32i    LPC,RSP,4
        l32i    LPO,RSP,8
        l32i    a15,RSP,12
        l32i    CTX,RSP,16
        addi    RSP,RSP,32
        ret
        .endm

        .macro  tailL   d
        l32i.n  a0,RSP,0
        l32i    LPC,RSP,4
        l32i    LPO,RSP,8
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

        .macro  lita    o
        dup
        addi    TOS,CTX,\o
        .endm

        .macro  ctxvar  o
        dup
        l32i    TOS,CTX,\o
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

        .macro  _dropN  n
        l32i    TOS,DSP,4*(\n-1)
        addi    DSP,DSP,4*\n
        .endm

        .macro  _drop
        _dropN  1
        .endm

        .macro  tosX0
        mov     X0,TOS
        _drop
        .endm

        .macro  to_r
        addi    RSP,RSP,-4
        s32i    TOS,RSP,0
        _drop
        .endm

        .macro  r_at
        dup
        l32i.n  TOS,RSP,0
        .endm

        .macro  r_from
        r_at
        addi    RSP,RSP,4
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
        b\op    TOS,X0,1f
        movi    TOS,0
        ret
1:
        movi    TOS,-1
        ret
        .endm

// 
// How DO...LOOP is implemented
// 
// Uses two registers:
//    LPC is the counter; it starts negative and counts up. When it reaches 0, loop exits
//    LPO is the offset. It is set up at loop start so that I can be computed from (LPC+LPO)
// 
// So when DO we have ( limit start ) on the stack so need to compute:
//      LPC = start - limit
//      LPO = limit
// 
// E.g. for "13 3 DO"
//      LPC = -10
//      LPO = 13
// 
// So the loop runs:
//      LPC     -10 -9 -8 -7 -6 -5 -4 -3 -2 -1
//      I         3  4  5  6  7  8  9 10 11 12
// 
// +LOOP must detect when LPC transitions from -ve to +ve. If the increment is -ve, then
// the sense of this transition is reversed.
//
// 

        .macro  _do
        addi    RSP,RSP,-8
        s32i    LPC,RSP,0
        s32i    LPO,RSP,4

        l32i    LPO,DSP,0       // TOS: start, LPO: limit
        sub     LPC,TOS,LPO
        _dropN  2
        .endm

        .macro  _qdo
        addi    RSP,RSP,-8
        s32i    LPC,RSP,0
        s32i    LPO,RSP,4

        l32i    LPO,DSP,0       // TOS: start, LPO: limit
        sub     LPC,TOS,LPO
        _dropN  1
        mov     TOS,LPC
        .endm

        .macro  _unloop
        l32i    LPC,RSP,0
        l32i    LPO,RSP,4
        addi    RSP,RSP,8
        .endm

        .macro  _i
        dup
        add     TOS,LPC,LPO
        .endm


// ====================   FORTH WORDS   =======================

// See p.598 of
//  Xtensa Instruction Set Architecture (ISA) Reference Manual
// which lists useful idioms

        .section        .irom0.text

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
hex2:
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

header  ".x2",dotx2
        prolog
        j       hex2

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
        prolog
        c       suspend
        c       drop
        epilog

header  "depth",depth
        dup
        movi    X0,(dstk-4)
        sub     TOS,X0,DSP
        srai    TOS,TOS,2
        ret

header  "base",base
        lita    _base
        ret

header  ">in",to_in
        lita    _in
        ret

header  "source",source
        lita    sourceA
        j       two_fetch

header  "source-id",source_id
        ctxvar  _source_id
        ret

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
        beqz    TOS,1f
        srai    TOS,TOS,31
        xor     TOS,TOS,TRUE
1:
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
        l32i    X1,DSP,4
        bne     TOS,X1,d_false
        l32i    X0,DSP,0
        l32i    X2,DSP,8
        bne     X0,X2,d_false
d_true:
        movi    TOS,-1
        addi    DSP,DSP,12
        ret
d_false:
        movi    TOS,0
        addi    DSP,DSP,12
        ret

header  "du<",d_u_less
        l32i    X1,DSP,4
        bltu    TOS,X1,d_false
        bne     X1,TOS,d_true
        l32i    X0,DSP,0
        l32i    X2,DSP,8
        bltu    X2,X0,d_true
        j       d_false

header  "d<",d_less
        l32i    X1,DSP,4
        blt     TOS,X1,d_false
        bne     X1,TOS,d_true
        l32i    X0,DSP,0
        l32i    X2,DSP,8
        bltu    X2,X0,d_true
        j       d_false

header  "d0<",d_less_than_zero
        srai    TOS,TOS,31
        j       nip

header  "dnegate",d_negate
        prolog
        c       invert
        c       swap
        c       invert
        c       swap
        lit     1
        tail    m_plus

header  "d-",d_minus
        prolog
        c       d_negate
        tail    d_plus

header  "d2*",d_two_times,INLINE
        l32i    X0,DSP,0
        ssai    32-1                    // setup for left funnel shift
        src     TOS,TOS,X0
        slli    X0,X0,1
        s32i    X0,DSP,0
        ret

header  "d2/",d_two_slash,INLINE
        l32i    X0,DSP,0
        ssai    1                    // setup for right funnel shift
        src     X0,TOS,X0
        srai    TOS,TOS,1
        s32i    X0,DSP,0
        ret

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

header  "um/mod",u_m_slash_mod
        l32i    X2,DSP,0
        l32i    X3,DSP,4                // X2:X3 is the dividend
                                        // TOS is the divisor
        movi    X0,32
        ssai    32-1                    // setup for left funnel shift
0:
        // Handle large X2 case. After shift, (X2 >= 2**32), so certainly greater than TOS
        bltz    X2,3f
        src     X2,X2,X3
        slli    X3,X3,1
        bltu    X2,TOS,1f
2:
        sub     X2,X2,TOS
        addi    X3,X3,1
1:
        addi    X0,X0,-1
        bnez    X0,0b

        addi    DSP,DSP,4
        s32i    X2,DSP,0
        mov     TOS,X3
        ret

3:
        src     X2,X2,X3
        slli    X3,X3,1
        j       2b

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
        l32i    TOS,DSP,12
        dup
        l32i    TOS,DSP,12
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
        _drop
        ret

header  "nip",nip,INLINE
        addi    DSP,DSP,4
        ret

header "2drop",two_drop,INLINE
        _dropN  2
        ret

header "execute",execute
        mov     X0,TOS
        _drop
        jx      X0

header "bounds",bounds,INLINE
        l32i    X0,DSP,0
        add     TOS,TOS,X0
        s32i    TOS,DSP,0
        mov     TOS,X0
        ret

// : within    over - >r - r> u< ;
header "within",within,INLINE
        l32i    X0,DSP,4
        l32i    X1,DSP,0
        addi    DSP,DSP,8
        // So now have: X0 X1 TOS
        //              v  lo hi
        sub     TOS,TOS,X1      // TOS is hi-lo
        sub     X0,X0,X1        // X0 is v-lo
        bltu    X0,TOS,1f
        movi    TOS,0
        ret
1:
        movi    TOS,-1
        ret

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

header  "tolower",tolower
        prolog
        dup
        lit     'A'
        lit     'Z'+1
        c       within
        lit     'a'-'A'
        c       and
        tail    plus

noheader case_equal
        prolog
        c       tolower
        c       swap
        c       tolower
        tail    equal
        
toaname:        // ( caddr u -- ) store string in aname, padded with zeroes
        prolog
        dup
        lita    aname
        c       c_store

        lita    aname+1
        lit     31
        lit     0
        c       fill

        lita    aname+1
        c       swap
        c       cmove

        lita    aname
        c       count
        c       bounds
        _do
1:
        _i
        c       c_fetch
        c       tolower
        _i
        c       c_store

        addi    LPC,LPC,1
        bnez    LPC,1b
        _unloop
        epilog

// SFIND
//         ( c-addr u -- c-addr u 0 | xt 1 | xt -1 )
// 
//         Find the definition named in the string at c-addr. If the
//         definition is not found, return c-addr and zero. If the definition
//         is found, return its execution token xt. If the definition is
//         immediate, also return one (1), otherwise also return minus-one
//         (-1).

        .p2align 2
compares:
        .long   0
        .long   cmp4
        .long   cmp8
        .long   cmp12
        .long   cmp16
        .long   cmp20
        .long   cmp24
        .long   cmp28
        .long   cmp32

header  "sfind",sfind
        prolog
        dup
        addi    TOS,TOS,1
        c       aligned
        movi    X0,compares
        add     TOS,X0,TOS
        l32i    TOS,TOS,0
        to_r

        c       two_dup
        c       toaname

        r_from
        mov     X7,TOS
        _drop
        lita    _forth
trynext:
        c       nextword
        beqz    TOS,1f
        jx      X7
cmp32:
        l32i    X0,CTX,aname
        l32i    X1,TOS,4
        bne     X0,X1,trynext
cmp28:
        l32i    X0,CTX,aname
        l32i    X1,TOS,4
        bne     X0,X1,trynext
cmp24:
        l32i    X0,CTX,aname
        l32i    X1,TOS,4
        bne     X0,X1,trynext
cmp20:
        l32i    X0,CTX,aname
        l32i    X1,TOS,4
        bne     X0,X1,trynext
cmp16:
        l32i    X0,CTX,aname
        l32i    X1,TOS,4
        bne     X0,X1,trynext
cmp12:
        l32i    X0,CTX,aname
        l32i    X1,TOS,4
        bne     X0,X1,trynext
cmp8:
        l32i    X0,CTX,aname+4
        l32i    X1,TOS,8
        bne     X0,X1,trynext
cmp4:
        l32i    X0,CTX,aname
        l32i    X1,TOS,4
        bne     X0,X1,trynext

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
        c       negate
1:
        epilog

header  "words",words
        prolog
        lita    _forth
2:      c       nextword
        beqz    TOS,1f
        dup
        c       cell_plus

        l32i    X1,TOS,0
        s32i    X1,CTX,aname+0
        l32i    X1,TOS,4
        s32i    X1,CTX,aname+4
        l32i    X1,TOS,8
        s32i    X1,CTX,aname+8
        l32i    X1,TOS,12
        s32i    X1,CTX,aname+12
        l32i    X1,TOS,16
        s32i    X1,CTX,aname+16
        l32i    X1,TOS,20
        s32i    X1,CTX,aname+20
        l32i    X1,TOS,24
        s32i    X1,CTX,aname+24
        l32i    X1,TOS,28
        s32i    X1,CTX,aname+28
        c       drop

        lita    aname
        c       count
        c       type
        c       space

        j       2b
1:
        tail    drop

header "accept",accept  // ( c-addr +n1 -- +n2 )
        prolog
        lit     0x1e            // tethered
        c       emit

        c       drop
        c       dupe
0:
        c       key
        movi    X0,13
        beq     TOS,X0,1f
        c       over
        c       c_store
        c       one_plus
        j       0b
1:
        c       drop
        c       swap
        tail    minus

header  "refill",refill
        prolog
        l32i    X0,CTX,_source_id
        bnez    X0,false

        lita    tib
        c       dupe
        lit     128
        c       accept
        lita    sourceA
        c       two_store
        lit     0
        lita    _in
        c       store
        c       true
1:      epilog

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
        ctxvar  _in
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
        ctxvar  _base
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
        ctxvar  _base

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
        prolog
        c       parse_name
        c       sfind
        tosX0
        beqz    X0,abort
        bgez    X0,1f
        c       literal
        lit     compile_comma
1:
        tail    compile_comma

isnotdelim:
        ctxvar  delim
        j       not_equal

header  "parse",parse
        prolog
        lita    delim
        c       store
        c       source
        ctxvar  _in
        c       slash_string

    // over >r
        c       over
        to_r
    // ['] isnotdelim xt-skip
        lit     isnotdelim
        c       xt_skip

    // 2dup d# 1 min + source drop - >in !
        c       two_dup
        lit     1
        c       min
        c       plus
        c       source
        c       drop
        c       minus
        c       to_in
        c       store
    // drop r> tuck -

        c       drop
        r_from
        c       tuck
        tail    minus

header  "throw",throw
        beqz    TOS,drop
        j       abort

header  "evaluate",evaluate
        prolog
        c       source
        to_r
        to_r
        ctxvar  _in
        to_r
        ctxvar  _source_id
        to_r
        c       true
        lita    _source_id
        c       store
        
        lita    sourceA
        c       two_store
        c       false
        lita    _in
        c       store

        c       interpret

        r_from
        lita    _source_id
        c       store
        r_from
        lita    _in
        c       store
        r_from
        r_from
        lita    sourceA
        tail    two_store

header  "here",here
        ctxvar  _dp
        ret

header  "dp",dp
        lita    _dp
        ret

header  "chere",chere
        j       abort

header  "cp",cp
        lita    _cp
        ret

header  "forth",forth
        lita    _forth
        ret

header  "state",state
        lita    _state
        ret

header  "unused",unused
        j       abort

header  "aligned",aligned
        addi    TOS,TOS,3
        srli    TOS,TOS,2
        slli    TOS,TOS,2
        ret

header  "align",align
        l32i    X0,CTX,_dp
        addi    X0,X0,3
        srli    X0,X0,2
        slli    X0,X0,2
        s32i    X0,CTX,_dp
        ret

header  "allot",allot
        lita    _dp
        j       plus_store

header  ",",comma
        l32i    X0,CTX,_dp
        s32i    TOS,X0,0
        addi    X0,X0,4
        s32i    X0,CTX,_dp
        _drop
        ret

header  "c,",c_comma
        l32i    X0,CTX,_dp
        s8i     TOS,X0,0
        addi    X0,X0,1
        s32i    X0,CTX,_dp
        _drop
        ret

noheader createstub
        epilog

noheader docreate
        dup
        l32i    TOS,a0,0
        l32i    X0,TOS,-4
        jx      X0

header  "create",create
        prolog
        c       align

        l32i    X0,CTX,_dp
        s32i    X0,CTX,recent

        lit     createstub
        c       comma

        c       mkhdr
        lit     s_prolog
        c       code_s_comma
        lit     docreate
        c       compile_comma
        c       here
        c       code_comma
        c       doburn
        epilog

header  "s,",s_comma
        j       abort

header  ">r",to_r,IMMEDIATE
        lit     s_to_r
        j       code_s_comma

header  "r>",r_from,IMMEDIATE
        lit     s_r_from
        j       code_s_comma

header  "r@",r_at,IMMEDIATE
        lit     s_r_at
        j       code_s_comma

header  "2>r",two_to_r,IMMEDIATE
        j       abort

header  "2r>",two_r_from,IMMEDIATE
        j       abort

header  "2r@",two_r_at
        j       abort

atburn:
        ctxvar  oburn
        lita    burn
        j       plus

header  "code.,",code_comma
        prolog
        c       atburn
        c       store
        lit     4
        lita    oburn
        tail    plus_store

header  "code.,",code_c_comma
        prolog
        c       atburn
        c       c_store
        lit     1
        lita    oburn
        tail    plus_store

header  "code.24,",code_24_comma
        prolog
        dup
        c       code_c_comma

        lit     8
        c       rshift
        dup
        c       code_c_comma

        lit     8
        c       rshift
        tail    code_c_comma

header  "code.s,",code_s_comma
        prolog
        c       count
1:
        beqz    TOS,2f
        c       over
        c       c_fetch
        c       code_c_comma
        lit     1
        c       slash_string
        j       1b
2:      tail    two_drop

header  ":noname",colon_noname
        prolog
        c       right_bracket

        c       false
        lita    attachpt
        c       store

        ctxvar  _cp
        dup
        lita    thisxt
        c       store

        lit     s_prolog
        tail    code_s_comma

noheader mkhdr
        prolog
        ctxvar  _cp
        lita    attachpt
        c       store

        c       parse_name
        beqz    TOS,abort

        ctxvar  _forth
        addi    TOS,TOS,1       // default is non-immediate
        c       code_comma

        c       tuck
        c       toaname
        c       one_plus
        c       aligned         // ( n )
        dup

        lita    aname
        c       atburn
        c       rot             // ( aname burn@ n )
        c       cmove
        lita    oburn
        tail    plus_store      // advance burn pointer

header  ":",colon
        prolog
        c       mkhdr
        c       right_bracket

        ctxvar  _cp
        ctxvar  oburn
        c       plus
        lita    thisxt
        c       store

        lit     s_prolog
        tail    code_s_comma

header  "flashbase",flashbase
        lit     0x40200000
        ret

doburn:
        prolog

        ctxvar  oburn
        c       aligned
        lita    oburn
        c       store

        l32i    X0,CTX,attachpt
        beqz    X0,1f
        s32i    X0,CTX,_forth
1:

        ctxvar  _cp
        movi    X0,0x40200000
        sub     TOS,TOS,X0
        lita    burn
        ctxvar  oburn
        c       _spi_flash_write
        c       throw

        ctxvar  oburn
        lita    _cp
        c       plus_store

        c       false
        lita    oburn
        tail    store

header  ";",semi_colon,IMMEDIATE
        prolog
        c       exit
        c       doburn
        tail    left_bracket

header  "exit",exit,IMMEDIATE
        lit     s_epilog
        j       code_s_comma

header  "immediate",immediate
        prolog
        ctxvar  _forth
        l32i    TOS,TOS,0
        srli    TOS,TOS,1       // Clear bit 0
        slli    TOS,TOS,1
        s32i    TOS,CTX,aname
        _drop

        ctxvar  _forth
        movi    X0,0x40200000
        sub     TOS,TOS,X0
        lita    aname
        lit     4
        c       _spi_flash_write
        tail    throw

header  "does>",does
        l32i    X0,CTX,recent
        s32i    a0,X0,0
        epilog

header  "[",left_bracket,IMMEDIATE
        movi    X0,0
        s32i    X0,CTX,_state
        ret

header  "]",right_bracket
        movi    X0,3
        s32i    X0,CTX,_state
        ret

// ====================   LITERALS   ==========================

noheader k_1
        dup
        movi    TOS,1
        ret

noheader k_2
        dup
        movi    TOS,2
        ret

noheader k_3
        dup
        movi    TOS,3
        ret

noheader k_4
        dup
        movi    TOS,4
        ret

        .p2align 2
        .long   true    // -1
fastconsts:
        .long   false   // 0
        .long   k_1
        .long   k_2
        .long   k_3
        .long   k_4

header  "literal",literal,IMMEDIATE
        prolog

        dup
        lit     -1
        lit     5
        c       within
        tosX0
        beqz    X0,1f

        movi    X0,fastconsts
        addx4   TOS,TOS,X0
        l32i    TOS,TOS,0
        tail    compile_comma

1:
        // Now search through kpool, stopping on a match or on FFFFFFFF
        s32i    TOS,CTX,aname
        mov     X0,TOS
        l32i    TOS,CTX,kpool
2:
        l32i    X1,TOS,0
        beq     X1,X0,4f
        beqi    X1,-1,3f

        addi    TOS,TOS,4
        j       2b

3:      // no match found, assign slot at TOS

        dup
        movi    X0,0x40200000
        sub     TOS,TOS,X0
        lita    aname
        lit     4
        c       _spi_flash_write
        c       throw

4:      // match found at TOS

        lit     s_dup
        c       code_s_comma

        srli    TOS,TOS,2
        ctxvar  _cp
        ctxvar  oburn
        c       plus
        addi    TOS,TOS,3
        srli    TOS,TOS,2
        c       minus
        slli    TOS,TOS,8
        addi    TOS,TOS,0x21    // l32r a2,
        tail    code_24_comma

header  "compile,",compile_comma
        prolog
        ctxvar  _cp
        ctxvar  oburn
        c       plus
        srli    TOS,TOS,2
        slli    TOS,TOS,2
        addi    TOS,TOS,4
        c       minus
        lit     2
        c       rshift
        lit     6
        c       lshift
        addi    TOS,TOS,0x05
        tail    code_24_comma

header  "2literal",two_literal,IMMEDIATE
        prolog
        c       swap
        c       literal
        tail    literal

header  "cmove",cmove
        l32i    X0,DSP,0
        l32i    X1,DSP,4
        add     TOS,TOS,X0
        // Move bytes from X1 to X0 until X0 reaches TOS
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
        l32i    X0,DSP,0
        l32i    X1,DSP,4
        add     X0,X0,TOS
        add     TOS,TOS,X1
        // Move bytes from TOS to X0 while TOS>=X1
        j       2f
1:
        l8ui    X2,TOS,0
        s8i     X2,X0,0
2:
        addi    X0,X0,-1
        addi    TOS,TOS,-1
        bgeu    TOS,X1,1b
        j       three_drop

header  "fill",fill
        l32i    X0,DSP,0
        l32i    X1,DSP,4
        add     X0,X0,X1
        // Fill X1 with TOS until X1 reaches X0
        j       2f
1:
        s8i     TOS,X1,0
        addi    X1,X1,1
2:
        bne     X1,X0,1b
        j       three_drop

header  "begin",begin,IMMEDIATE
        j       atburn

header  "ahead",ahead,IMMEDIATE
        prolog
        c       begin
        lit     0x000006
        tail    code_24_comma

header  "if",if,IMMEDIATE
        prolog
        lit     s_tosX0
        c       code_s_comma
        c       begin
        lit     0x000416
        tail    code_24_comma

header  "then",then,IMMEDIATE
        prolog
        dup
        addi    TOS,TOS,4
        c       begin
        c       swap
        c       minus
        tail    patch

// patch ( ptr offset )
// patch OFFSET into jump/branch instruction at byte-aligned PTR
// Byte at PTR determines the instruction pattern:
//
// 06:    "J" instruction, so left-shift 6
// else:  branch instruction, so left-shift 12
//

patch:
        l32i    X0,DSP,0   // X0:ptr TOS:insn

        l8ui    X1,X0,0
        beqi    X1,0x06,patch_j
        slli    TOS,TOS,12
        j       or24
patch_j:
        slli    TOS,TOS,6
or24:
        or      X1,X1,TOS
        s8i     X1,X0,0

        l8ui    X1,X0,1
        srli    TOS,TOS,8
        or      X1,X1,TOS
        s8i     X1,X0,1

        l8ui    X1,X0,2
        srli    TOS,TOS,8
        or      X1,X1,TOS
        s8i     X1,X0,2

        _dropN  2
        ret

header  "again",again,IMMEDIATE
        prolog
        c       begin
        addi    TOS,TOS,4
        c       minus
        lit     6
        c       lshift
        addi    TOS,TOS,0x06
        tail    code_24_comma

header  "until",until,IMMEDIATE
        prolog
        lit     s_tosX0
        c       code_s_comma

        c       begin
        addi    TOS,TOS,4
        c       minus
        slli    TOS,TOS,12
        lit     0x000416
        c       or
        tail    code_24_comma

header  "recurse",recurse,IMMEDIATE
        ctxvar  thisxt
        j       compile_comma

noheader push_leave
        l32i    X0,CTX,leaveptr
        s32i    TOS,X0,0
        addi    X0,X0,4
        s32i    X0,CTX,leaveptr
        j       drop

noheader pop_leave
        l32i    X0,CTX,leaveptr
        dup
        addi    X0,X0,-4
        l32i    TOS,X0,0
        s32i    X0,CTX,leaveptr
        ret

header  "do",do,IMMEDIATE
        prolog
        lit     0
        c       push_leave
        lit     s_do
        c       code_s_comma
        tail    begin

header  "?do",question_do,IMMEDIATE
        prolog

        lit     0
        c       push_leave

        lit     s_qdo
        c       code_s_comma
        c       if
        c       push_leave

        tail    begin

header  "leave",leave,IMMEDIATE
        prolog
        c       ahead
        tail    push_leave

header  "loop",loop,IMMEDIATE
        prolog
        lit     s_loop
        c       code_s_comma

        c       begin
        addi    TOS,TOS,4
        c       minus
        slli    TOS,TOS,12
        lit     0x000d56                // bnez a13 ...
        c       or
        c       code_24_comma
loop_common:
        c       pop_leave
        beqz    TOS,1f
        c       then
        j       loop_common
1:
        _drop
        tail    unloop

noheader do_plus_loop
        // When LPC transitions from -ve to +ve
        srai    X0,TOS,31               // increment sign
        xor     X1,LPC,X0               // X1 old LPC
        add     LPC,LPC,TOS
        xor     X0,LPC,X0               // X0 new LPC
        _drop
        ret

header  "+loop",plus_loop,IMMEDIATE
        prolog
        lit     do_plus_loop
        c       compile_comma

        c       begin
        addi    TOS,TOS,4
        c       minus
        slli    TOS,TOS,16
        lit     0x00b457                // bgeu X0,X1, ...
        c       or
        c       code_24_comma
        j       loop_common

header  "unloop",unloop,IMMEDIATE
        lit     s_unloop
        j       code_s_comma

header  "i",i,IMMEDIATE
        lit     s_i
        j       code_s_comma

header  "j",j
        dup
        l32i    TOS,RSP,0
        l32i    X0,RSP,4
        add     TOS,TOS,X0
        ret

header  "decimal",decimal
        movi    X0,10
        s32i    X0,CTX,_base
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

// ====================   NUMBERS   ===========================

// : isvoid ( caddr u -- ) \ any char remains, abort
isvoid:
        addi    DSP,DSP,4
        tosX0
        bnez    X0,nosuchword
        ret

nosuchword:
        lit     'N'
        c       emit
        lit     'O'
        c       emit
        c       space
        lit     'W'
        c       emit
        c       cr
        c       space
        lita    aname
        c       count
        c       type
        c       cr

        lit     0x1e
        c       emit
1:      
        j       1b

// : consume1 ( caddr u ch -- caddr' u' f )
//     >r over c@ r> =
//     over 0<> and
//     dup>r d# 1 and /string r>
// ;
consume1:
        prolog
        to_r
        c       over
        c       c_fetch
        r_from
        c       equal

        c       over
        c       not_equal_zero
        c       and

        dup
        to_r
        c       negate
        c       slash_string
        r_from
        epilog

doubleAlso2:
        prolog
        lit     0
        dup
        c       two_swap
        lit     '-'
        c       consume1
        to_r
        c       to_number
        lit     '.'
        c       consume1
        tosX0
        beqz    X0,1f
        c       isvoid
        r_from
        tosX0
        beqz    X0,2f
        c       d_negate
2:
        lit     2
        epilog

1:
        c       isvoid
        c       drop
        r_from
        tosX0
        beqz    X0,3f
        c       negate
3:
        lit     1
        epilog

doubleAlso1:
        prolog
        // Handle 'X' here
        bnei    TOS,3,1f
        l32i    X0,DSP,0
        movi    X2,0x27                 // ascii '
        l8ui    X1,X0,0
        bne     X1,X2,1f
        l8ui    X1,X0,2
        bne     X1,X2,1f
        // matches 'X'. Return ( X 1 )
        _drop
        l8ui    TOS,X0,1
        lit     1
        epilog
1:
        lit     '$'                     // hex
        c       consume1
        movi    X1,16
        tosX0
        bnez    X0,inbase
        lit     '#'                     // decimal
        c       consume1
        tosX0
        movi    X1,10
        bnez    X0,inbase
        lit     '%'                     // binary
        c       consume1
        tosX0
        movi    X1,2
        bnez    X0,inbase
        tail    doubleAlso2

inbase:                                 // conversion in base X1
        dup
        l32i    TOS,CTX,_base
        s32i    X1,CTX,_base
        to_r
        c       doubleAlso2
        r_from
        c       base
        tail    store

doubleAlso:
        prolog
        c       doubleAlso1
        tail    drop

doubleAlso_comma:
        prolog
        c       doubleAlso1
        tosX0
        beqi    X0,1,1f
        c       swap
        c       literal
1:
        tail    literal

        .p2align        2

        .long   execute
dispatch:
        .long   doubleAlso
        .long   execute
        .long   compile_comma
        .long   doubleAlso_comma
        .long   execute

interpret:
        prolog
0:
        c       parse_name
        beqz    TOS,1f
        c       sfind                   // -1 0 +1
        l32i    X0,CTX,_state           // -1 0 +1 +2 +3 +4
        add     TOS,TOS,X0
        movi    X0,dispatch
        addx4   TOS,TOS,X0
        l32i    TOS,TOS,0
        c       execute
        j       0b
1:      c       two_drop
        epilog

// ====================   ESP SYSTEM INTERFACE   ==============

// Common calling subroutines. Named for number of
// arguments/return values:
//
//      c_common_X_Y
//
// takes X arguments and returns Y values
//

c_common_3_1:
        l32i    X0,DSP,4
        l32i    X1,DSP,0
        mov     X2,TOS
        _dropN  2
        j       c_common_x_1

c_common_2_1:
        l32i    X0,DSP,0
        mov     X1,TOS
        _dropN  1
        j       c_common_x_1

c_common_0_1:
        dup
        j       c_common_x_1

c_common_1_1:
        mov     X0,TOS
c_common_x_1:
        addi    RSP,RSP,-16
        s32i    DSP,RSP,4
        s32i    a0,RSP,0

        mov     a2,X0
        mov     a3,X1
        mov     a4,X2
        mov     a5,X3
        mov     a6,X4

        callx0  X6

        l32i    a0,RSP,0
        l32i    DSP,RSP,4
        addi    RSP,RSP,16
        ret

header  "us@",us_fetch
        movi    X6,system_get_time
        j       c_common_0_1

header  "spi_flash_write",_spi_flash_write  // ( byte-offset source len )
        movi    X6,spi_flash_write
        j       c_common_3_1

header  "spi_flash_erase_sector",_spi_flash_erase_sector  // ( sector )
        movi    X6,spi_flash_erase_sector
        j       c_common_1_1

header  "ms",ms
        addi    RSP,RSP,-16
        s32i    a0,RSP,0
        s32i    DSP,RSP,4
        mov     a3,a2
        movi    a2,some_timer
        movi    a4,0
        movi    a5,1
        movi    a0,ets_timer_arm_new
        callx0  a0
        l32i    a0,RSP,0
        l32i    DSP,RSP,4
        addi    RSP,RSP,16
        _drop
        j       suspend

noheader suspend
        s32i    a0,CTX,_pc
        dup
        s32i    DSP,CTX,_dsp
        mov     a4,a1
        l32i    a1,CTX,_rsp
        sub     a5,a1,a4
        s32i    a5,CTX,_rdepth
        // Preserve the Rstack by copying from a4..a1 to _rstk
        addi    a5,CTX,_rstk
        j       2f
1:
        l32i    a6,a4,0
        s32i    a6,a5,0
        addi    a4,a4,4
        addi    a5,a5,4
2:      bne     a4,a1,1b

        epilogL

header  "quit",quit
        prolog
1:
        c       refill
        c       drop
        c       interpret
        c       space
        lit     'o'
        c       emit
        lit     'k'
        c       emit
        c       cr
        j       1b
1:      epilog

        .p2align  2
.global swapforth
swapforth:
        prologL
        movi    CTX,_ctx
        s32i    a1,CTX,_rsp

        movi    DSP,dstk
        movi    TRUE,-1

        c       decimal

        addi    X0,CTX,leaves
        s32i    X0,CTX,leaveptr

        lit     64
1:
        dup
        c       _spi_flash_erase_sector
        _drop
        addi    TOS,TOS,1
        movi    X0,96
        bne     TOS,X0,1b
        _drop

        l32i    X0,CTX,_cp
        s32i    X0,CTX,kpool
        addi    X0,X0,(4*256)
        s32i    X0,CTX,_cp

        c       cr
        c       cr
        j       quit

1:
        c       refill
        c       dotx
        ctxvar  _rdepth
        c       dotx
        j       1b


        lit     ssss
        lit     80
        lita    sourceA
        c       two_store

        lit     0
        lita    _in
        c       store

        c       interpret
        c       cr

        lit     0x947
        to_r

1:
        c       refill

        c       source
        c       type
        j       1b

1:
        c       key
        c       dotx
        j       1b

        c       cr
        r_from
        dup
        c       dotx
        c       cr
        c       one_plus
        to_r

        // lit     4000
        // c       ms
        c       suspend

        j       1b

        .p2align  2
.global swapforth2
swapforth2:
        prologL
        mov     X0,a3
        movi    CTX,_ctx
        s32i    a1,CTX,_rsp

        l32i    DSP,CTX,_dsp
        movi    TRUE,-1

        // Stage incoming arguments (a2, a3) on the stack
        addi    DSP,DSP,-4
        s32i    X0,DSP,0                // ( par sig )

        l32i    a4,CTX,_rdepth
        sub     a1,a1,a4
        addi    a5,CTX,_rstk
        add     a4,a5,a4
        // Restore the Rstack by copying from _rstk+4 to r1
        // So copy a5..a4 to a1 up
        mov     a7,a1
        j       2f
1:
        l32i    a6,a5,0
        s32i    a6,a7,0
        addi    a5,a5,4
        addi    a7,a7,4
2:      bne     a4,a5,1b

        l32i    a0,CTX,_pc
        jx      a0

        .section        .data

s_prolog:
        .byte   2f-1f
1:      prolog
2:

s_epilog:
        .byte   2f-1f
1:      epilog
2:

s_tosX0:
        .byte   2f-1f
1:      tosX0
2:

s_dup:
        .byte   2f-1f
1:      dup
2:

s_do:
        .byte   2f-1f
1:      _do
2:

s_qdo:
        .byte   2f-1f
1:      _qdo
2:

s_loop:
        .byte   2f-1f
1:      addi    LPC,LPC,1
2:

s_unloop:
        .byte   2f-1f
1:      _unloop
2:

s_i:
        .byte   2f-1f
1:      _i
2:

s_to_r:
        .byte   2f-1f
1:      to_r
2:

s_r_from:
        .byte   2f-1f
1:      r_from
2:

s_r_at:
        .byte   2f-1f
1:      r_at
2:

        .p2align        2
_ctx:   .long           dseg
        .long           0x40240000      // CP
        .long           forth_link
        .skip           ramhere-12

ssss:   
        # .ascii          "us@ 1+ 1- us@ swap - .x"
        .ascii          "$123456789. 2dup .x .x cr dnegate .x .x"
        .ascii          "                                                                                "

        .p2align        2
        .skip           512
dstk:

        .section        .bss
dseg:   .skip           16384
