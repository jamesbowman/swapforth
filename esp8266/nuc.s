        .section        .irom0.text

// The CALL0 calling convention is:
//
//      a0      Return address
//      a1      Stack pointer
//      a2-a7   Function args, scratch
//      a8      scratch
//      a12-a15 Callee-saved

// So SwapForth assigns
//
//      a0      Return address
//      a1      RSP
//      a2      TOS
//      a3      DSP
//      a4-a8   scratch


        .set    forth_link,0
        .equ    INLINE,1
        .equ    IMMEDIATE,2

        .macro  header   fname,label,immediate=0
        .section        .irom0.text
        .p2align  2
        .long   forth_link + \immediate
        .set    forth_link,.-4
        .string "\fname"
        .p2align  2
\label:
        .endm

        .macro  prolog
        addi    a1,a1,-16
        s32i.n  a0,a1,0
        .endm

        .macro  epilog
        l32i.n  a0,a1,0
        addi    a1,a1,16
        ret.n
        .endm

        .macro  dup
        addi    a3,a3,-4
        s32i    a2,a3,0
        .endm

        .macro  lit     v
        dup
        movi    a2,\v
        .endm

        .macro  pop_a4
        l32i    $r1,$r27,0
        add     $r27,$r27,4
        .endm

// ====================   FORTH WORDS   =======================

// See p.598 of
//  Xtensa Instruction Set Architecture (ISA) Reference Manual
// which lists useful idioms

header  ".x",dotx     
header  "bye",bye
header  "emit",emit  
        movi    a5,0x60000000
1:
        l32i    a4,a5,0x1c      // wait until TX fifo not full
        extui   a4,a4,16,8
        beqi    a4,0x80,1b
        s32i    a2,a5,0         // transmit
        j       drop

header  "key",key 
        j       abort

header  "depth",depth
        dup
        movi    a4,(dstk-4)
        sub     a2,a4,a3
        srai    a2,a2,2
        ret

header  "base",base
        j       abort

header  ">in",to_in
        j       abort

header  "source",source
        j       abort

header  "source-id",source_id
        j       abort

header "2*",two_times,INLINE
        j       abort

header "2/",two_slash,INLINE
        j       abort

header "1+",one_plus,INLINE
        j       abort

header "1-",one_minus,INLINE
        j       abort

header "0=",zero_equals,INLINE
        j       abort

header "cell+",cell_plus,INLINE
        j       abort

header "cells",cells,INLINE
        j       abort

header "<>",not_equal,INLINE
        j       abort

header "=",equal,INLINE
        j       abort

header ">",greater,INLINE
        j       abort

header "<",less,INLINE
        j       abort

header "0<",less_than_zero,INLINE
        j       abort

header "0>",greater_than_zero,INLINE
        j       abort

header "0<>",not_equal_zero,INLINE
        j       abort

header "u<",unsigned_less,INLINE
        j       abort

header "u>",unsigned_greater,INLINE
        j       abort

header  "+",plus,INLINE
        j       abort

header  "s>d",s_to_d,INLINE
        j       abort

header  "d>s",d_to_s,INLINE
        j       abort

header  "m+",m_plus
        j       abort

header  "d+",d_plus
        j       abort

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
        j       abort

header  "negate",negate,INLINE
        j       abort

header  "invert",invert,INLINE
        j       abort

header  "and",and,INLINE
        j       abort

header  "or",or,INLINE
        j       abort

header  "xor",xor,INLINE
        j       abort

header  "lshift",lshift,INLINE
        j       abort

header  "rshift",rshift,INLINE
        j       abort

header  "abs",_abs,INLINE
        j       abort

header  "um*",u_m_multiply,INLINE
        j       abort

header  "*",multiply,INLINE
        j       abort

header  "/",divide
        j       abort

header  "mod",mod
        j       abort

header  "um/mod",u_m_slash_mod
        j       abort

header  "c@",c_fetch,INLINE
        j       abort

header  "c!",c_store,INLINE
        j       abort

header  "@",fetch,INLINE
        j       abort

header  "!",store,INLINE
        j       abort

header  "ul@",u_l_fetch,INLINE
        j       abort

header  "sl@",s_l_fetch,INLINE
        j       abort

header  "2@",two_fetch,INLINE
        j       abort

header  "2!",two_store,INLINE
        j       abort

header  "/string",slash_string
        j       abort

header  "swap",swap,INLINE
        j       abort

header  "over",over,INLINE
        j       abort

header "false",false,INLINE
        j       abort

header "true",true,INLINE
        j       abort

header "bl",_bl,INLINE
        j       abort

header "rot",rot,INLINE
        j       abort

header "noop",noop
        j       abort

header "-rot",minus_rot,INLINE
        j       abort

header "tuck",tuck  
        j       abort

header "?dup",question_dupe 
        j       abort

header "2dup",two_dup,INLINE
        j       abort

header "+!",plus_store,INLINE
        j       abort

header "2swap",two_swap,INLINE
        j       abort

header "2over",two_over,INLINE
        j       abort

header "min",min,INLINE
        j       abort

header "max",max,INLINE
        j       abort

header  "space",space
        j       abort

header  "cr",cr
        j       abort

header "count",count,INLINE
        j       abort

header "dup",dupe,INLINE
        j       abort

header "drop",drop,INLINE
        l32i    a2,a3,0
        addi    a3,a3,4
        ret.n

header  "nip",nip,INLINE
        j       abort

header "2drop",two_drop,INLINE
        j       abort

header "execute",execute
        j       abort

header "bounds",bounds,INLINE
        j       abort

header "type",type
        j       abort

header  "sfind",sfind
        j       abort

header  "words",words
        j       abort

header "accept",accept
        j       abort

header  "refill",refill
        j       abort

header  "parse-name",parse_name
        j       abort

header  ">number",to_number
        j       abort

header  "abort",abort
        j       abort

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
        j       abort

header  "state",state
        j       abort

header  "unused",unused
        j       abort

header  "aligned",aligned
        j       abort

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
        j       abort

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

        .p2align  2
xxx:
        .long   forth_link

.global swapforth
swapforth:
        prolog

        movi    a3,dstk

        lit     'a'
        lit     'b'
        lit     'c'
        call0   emit
        call0   emit
        call0   emit

        dup
        call0   depth
        epilog

        .section        .data
        .skip           512
dstk:
