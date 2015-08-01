# r0            TOS
# r1..r15       scratch
# r20           GPIO shadow
# r21           GPIO shadow
# r22           GPIO shadow
# r24
# r25           constant 0
# r26           FSP
# r27           DSP
# r28           do/loop counter
# r29           do/loop offset
# r30           cc
# r31           RSP

        .equ    PM_UNLOCK,      0x1fc80
        .equ    PM_ADDR,        0x1fc84
        .equ    PM_DATA,        0x1fc88

        .section        .text
        .equ    FSTACK_TOP,     0xf8fc
        .equ    DSTACK_TOP,     0xfcfc
.global _start
_start:

        jmp     0x3fffc
        jmp     0 /* ft900_watchdog */
        jmp     interrupt_0
        jmp     interrupt_1
        jmp     interrupt_2
        jmp     interrupt_3
        jmp     interrupt_4
        jmp     interrupt_5
        jmp     interrupt_6
        jmp     interrupt_7
        jmp     interrupt_8
        jmp     interrupt_9
        jmp     interrupt_10
        jmp     interrupt_11
        jmp     interrupt_12
        jmp     interrupt_13
        jmp     interrupt_14
        jmp     interrupt_15
        jmp     interrupt_16
        jmp     interrupt_17
        jmp     interrupt_18
        jmp     interrupt_19
        jmp     interrupt_20
        jmp     interrupt_21
        jmp     interrupt_22
        jmp     interrupt_23
        jmp     interrupt_24
        jmp     interrupt_25
        jmp     interrupt_26
        jmp     interrupt_27
        jmp     interrupt_28
        jmp     interrupt_29
        jmp     interrupt_30
        jmp     interrupt_31
        jmp     0x3fff8

        jmp     codestart

        /*
         Macro to construct the interrupt stub code.
         it just saves r0, loads r0 with the int vector
         and branches to interrupt_common.
        */

        .macro  inth i=0
interrupt_\i:
        push    $r0
        ldk     $r0,noop
        jmp     interrupt_common
        .endm

        inth    0
        inth    1
        inth    2
        inth    3
        inth    4
        inth    5
        inth    6
        inth    7
        inth    8
        inth    9
        inth    10
        inth    11
        inth    12
        inth    13
        inth    14
        inth    15
        inth    16
        inth    17
        inth    18
        inth    19
        inth    20
        inth    21
        inth    22
        inth    23
        inth    24
        inth    25
        inth    26
        inth    27
        inth    28
        inth    29
        inth    30
        inth    31
        inth    32

        /* On entry: r0, already saved, holds the handler function */
interrupt_common:
        push    $r1    /* { */
        push    $r2    /* { */
        push    $r3    /* { */
        push    $r4    /* { */
        push    $r5    /* { */
        push    $r6    /* { */
        push    $r7    /* { */
        push    $r8    /* { */
        push    $r9    /* { */
        push    $r10   /* { */
        push    $r11   /* { */
        push    $r12   /* { */
        push    $r13   /* { */
        push    $r14   /* { */
        push    $r15   /* { */

        push    $r27    /* { */
        push    $cc    /* { */

        calli   $r0

        pop     $cc    /* } */
        pop     $r27    /* } */

        pop     $r15   /* } */
        pop     $r14   /* } */
        pop     $r13   /* } */
        pop     $r12   /* } */
        pop     $r11   /* } */
        pop     $r10   /* } */
        pop     $r9    /* } */
        pop     $r8    /* } */
        pop     $r7    /* } */
        pop     $r6    /* } */
        pop     $r5    /* } */
        pop     $r4    /* } */
        pop     $r3    /* } */
        pop     $r2    /* } */
        pop     $r1    /* } */
        pop     $r0    /* } matching push in interrupt_0-31 above */
        reti

       /* Null function for unassigned interrupt to point at */
nullvector:
        return

        .equ    sys_regclkcfg    , 0x10008 
        .equ    sys_regmsc0cfg_b2, 0x1001a 
        .equ    sys_regmsc0cfg_b3, 0x1001b 

        .equ    sys_regpad48     , 0x1004c 
        .equ    sys_regpad49     , 0x1004d 
        .equ    sys_regpad50     , 0x1004e 
        .equ    sys_regpad51     , 0x1004f 
        .equ    sys_regpad52     , 0x10050 
        .equ    sys_regpad53     , 0x10051 
        .equ    sys_regpad54     , 0x10052 
        .equ    sys_regpad55     , 0x10053 

        .equ    uart1_rhr        , 0x10320 
        .equ    uart1_thr        , 0x10320 
        .equ    uart1_ier        , 0x10321 
        .equ    uart1_isr_reg    , 0x10322 
        .equ    uart1_fcr        , 0x10322 
        .equ    uart1_lcr        , 0x10323 
        .equ    uart1_mcr        , 0x10324 
        .equ    uart1_lsr        , 0x10325 
        .equ    uart1_icr        , 0x10325 
        .equ    uart1_msr        , 0x10326 
        .equ    uart1_spr        , 0x10327 
        .equ    uart1_dll        , 0x10320 
        .equ    uart1_dlm        , 0x10321 

        .macro  snap    reg
        move    $r0,\reg
        call    dot
stophere:
        jmp     stophere
        .endm

        .macro  lit v=0
        call    dupe
        ldk     $r0,\v
        .endm

        .macro  litm v=0
        call    dupe
        lpm     $r0,\v
        .endm

        .set    forth_link,0
        .set    internal_link,0

        .macro  fheader  fname,immediate=0
        .section        .text
        .align  2
        .long   0xe0000000 + forth_link + \immediate
        .set    forth_link,.-4
        .string "\fname"
        .align  2
        .endm

        .macro  header  fname,aname,immediate=0
        fheader "\fname",\immediate
\aname :
        .endm

        .macro  iheader fname,aname,immediate=0
        .section        .text
        .align  2
        .long   0xe0000000 + internal_link + \immediate
        .set    internal_link,.-4
        .string "\fname"
        .align  2
        .endm

        .macro  _dup
        sub     $r27,$r27,4
        sti     $r27,0,$r0
        .endm

        .macro  _drop
        ldi     $r0,$r27,0
        add     $r27,$r27,4
        .endm

        .macro  _2drop
        ldi     $r0,$r27,4
        add     $r27,$r27,8
        .endm

        .macro  _r1_n
        ldi     $r1,$r27,0
        add     $r27,$r27,4
        .endm

        .equ    source_spec_size, 16

        .macro  push_source_spec
        lda     $r1,_source_id
        push    $r1
        lda     $r1,sourceA
        push    $r1
        lda     $r1,sourceC
        push    $r1
        lda     $r1,_in
        push    $r1
        .endm

        .macro  pop_source_spec
        pop     $r1
        sta     _in,$r1
        pop     $r1
        sta     sourceC,$r1
        pop     $r1
        sta     sourceA,$r1
        pop     $r1
        sta     _source_id,$r1
        .endm

# Lower-case the text in aname
lower_aname:
        ldk     $r1,aname
lower_aname_0:
        ldi.b   $r2,$r1,0
        cmp     $r2,'A'
        jmpc    b,lower_aname_1
        cmp     $r2,'Z'
        jmpc    a,lower_aname_1
        add     $r2,$r2,'a'-'A'
        sti.b   $r1,0,$r2
lower_aname_1:
        add     $r1,$r1,1
        cmp     $r1,aname+32
        jmpc    nz,lower_aname_0
        return

mkheader:      /*               ( <spaces>name -- ) */
        call    _parse_word
       /* XXX - should check for zero string here */

        call    lower_aname
        lda     $r4,cwl        /* $r4 -> cwl */
        ldi     $r1,$r4,4      /* $r1 -> previous word */
        lda     $r2,pmdp       /* $r2 -> new header */
        sti     $r4,4,$r2

        sta     PM_ADDR,$r2    /* start writing */
        lpm     $r2,store-8    /* the very first header is the link mask */
        or      $r1,$r1,$r2
        sta     PM_DATA,$r1    /* write link */

        add     $r3,$r3,4
        and     $r3,$r3,~3

        ldk     $r2,aname
        ldk     $r1,PM_DATA
        streamout $r1,$r2,$r3  /* write name */

        lda     $r2,pmdp
        add     $r2,$r2,4
        add     $r2,$r2,$r3
        sta     pmdp,$r2
        sta     thisxt,$r2
        return

push_r1:
        _dup
        move    $r0,$r1
        return

#######   ANS CORE   #################################################

header  "!",store
        ldi     $r1,$r27,0
        sti     $r0,0,$r1
        _2drop
        return



fheader "*"
        _r1_n
        mul     $r0,$r0,$r1
        return



header  "+",plus
        _r1_n
        add     $r0,$r0,$r1
        return

fheader "allot"
        call    __dp
        jmp     plus_store

header  "+!",plus_store
        ldi     $r1,$r27,0
        ldi     $r2,$r0,0
        add     $r2,$r2,$r1
        sti     $r0,0,$r2
        jmp     two_drop

header  "(+loop)",do_plus_loop
        addcc   $r28,$r0
        ashr    $r1,$r0,31
        xor     $cc,$cc,$r1
        add     $r28,$r28,$r0
        _drop
        return

fheader "+loop",1
        lit     do_plus_loop
        call    compile_comma

        lshr    $r0,$r0,2
        lpm     $r1,_template_jnc
        or      $r0,$r0,$r1
        call    code_comma

        jmp     loop_clean

header  ",",comma
        _dup
        lda     $r0,dp
        add     $r1,$r0,4
        sta     dp,$r1
        jmp     store

header  "pm,",pm_comma
        call    pmhere
        add     $r1,$r0,4
        sta     pmdp,$r1
        jmp     pm_store


header  "code,",code_comma
        jmp     pm_comma

header  "sync",sync
        return

header  "-",minus
        _r1_n
        sub     $r0,$r1,$r0
        return


header "/",slash
        _r1_n
        div     $r0,$r1,$r0
        return

header "/mod",slash_mod
        ldi     $r1,$r27,0
        mod     $r2,$r1,$r0
        sti     $r27,0,$r2
        div     $r0,$r1,$r0
        return

fheader "0<"
        ashr    $r0,$r0,31
        return

fheader "0="
        cmp     $r0,0
        bexts   $r0,$r30,(1<<5)|0
        return

fheader "1+"
        add     $r0,$r0,1
        return

header  "1-",one_minus
        sub     $r0,$r0,1
        return

header  "2!",two_store
        ldi     $r1,$r27,0
        sti     $r0,0,$r1
        ldi     $r1,$r27,4
        sti     $r0,4,$r1
        ldi     $r0,$r27,8
        add     $r27,$r27,12
        return

fheader "2*"
        ashl    $r0,$r0,1
        return

fheader "2/"
        ashr    $r0,$r0,1
        return

header  "2@",two_fetch
        ldi     $r1,$r0,4
        ldi     $r0,$r0,0
        sub     $r27,$r27,4
        sti     $r27,0,$r1
        return

header "2drop",two_drop
        _2drop
        return

header  "2dup",two_dupe
        ldi     $r1,$r27,0
        sub     $r27,$r27,8
        sti     $r27,4,$r0
        sti     $r27,0,$r1
        return

fheader "2over"
        ldi     $r1,$r27,8
        call    push_r1
        ldi     $r1,$r27,8
        jmp     push_r1

header  "2swap",two_swap
        exi     $r0,$r27,4
        ldi     $r1,$r27,0
        exi     $r1,$r27,8
        sti     $r27,0,$r1
        return

header  "2lit",two_lit         /* Push (r1,r2). For optimizer. */
        sub     $r27,$r27,8
        sti     $r27,4,$r0
        sti     $r27,0,$r1
        move    $r0,$r2
        return
        
fheader ":"
        call    mkheader
        lda     $r1,thisxt
        sub     $r1,$r1,4
        sta     tosmudge,$r1
        call    smudge
        jmp     right_bracket

header  "smudge",smudge                /* Flip the top bit of the first char of this name */
        lda     $r1,tosmudge
        lpmi    $r2,$r1,0
        xor     $r2,$r2,-1
        sta     PM_ADDR,$r1
        sta     PM_DATA,$r2
        return

header  ";",semicolon,1
        call    smudge
        call    exit
        jmp     left_bracket

fheader "<"
        _r1_n
        cmp     $r0,$r1
        bexts   $r0,$r30,(1<<5)|5
        return


header  "=",equal
        _r1_n
        cmp     $r0,$r1
        bexts   $r0,$r30,(1<<5)|0
        return

header  "cmp_cc",cmp_cc
        ldi     $r1,$r27,0
        cmp     $r1,$r0                /* note order: ( a b ) is compared (a,b) */
        _2drop
        return

fheader ">"
        _r1_n
        cmp     $r1,$r0
        bexts   $r0,$r30,(1<<5)|5
        return


fheader ">body"
       /* "literal" compiles a dupe then "ldk". Extract the field of the "ldk" */
        lpmi    $r0,$r0,4
        ldk     $r1,0x3ffff
        and     $r0,$r0,$r1
        return

header  ">number",to_number
        ldi     $r1,$r27,0              /* $r1 is caddr */
        ldi     $r2,$r27,4              /* $r2:$r3 is the accumulator */
        ldi     $r3,$r27,8
        lda     $r4,_base              /* $r4 is base */

to_number_0:
        cmp     $r0,0
        jmpc    z,to_number_2

        ldi.b   $r6,$r1,0

        cmp     $r6,'a'
        ldk     $r7,-'a'+10
        jmpc    ae,to_number_1

        cmp     $r6,'A'
        ldk     $r7,-'A'+10
        jmpc    ae,to_number_1

        cmp     $r6,'9'
        jmpc    a,to_number_2
        ldk     $r7,-'0'+0
to_number_1:
        add     $r6,$r6,$r7
        cmp     $r6,$r4
        jmpc    ae,to_number_2

        muluh   $r5,$r3,$r4            /* $r2:$r3 *= $r4 */
        mul     $r3,$r3,$r4
        mul     $r2,$r2,$r4
        add     $r2,$r2,$r5

        addcc   $r3,$r6
        add     $r3,$r3,$r6
        bextu   $r6,$r30,(1 << 5) | 1
        add     $r2,$r2,$r6

        add     $r1,$r1,1
        sub     $r0,$r0,1

        jmp     to_number_0

to_number_2:
        sti     $r27,0,$r1
        sti     $r27,4,$r2
        sti     $r27,8,$r3
        return

header  ">r",to_r
        pop     $r1
        push    $r0
        _drop
        jmpi    $r1

header  "?dup",question_dupe
        cmp     $r0,0
        jmpc    nz,dupe
        return

header  "@",fetch
        ldi     $r0,$r0,0
        return

header  "ul@",u_l_fetch
        ldi     $r0,$r0,0
        return


fheader "abs"
        cmp     $r0,0
        jmpc    lt,negate
        return

fheader "tethered"
        lit     _tethered
        return

        .macro   ifteth       label
        lda     $cc,_tethered
        jmpx    0,$cc,0,\label
        .endm

header  "accept",accept
        ifteth  1f
        lit     0x1e
        call    emit
1:
        push    $r28
        ldk     $r28,0

accept_1:
        call    key
        cmp     $r0,'\r'
        jmpc    z,accept_2

        cmp     $r0,8
        jmpc    z,accept_backspace
        cmp     $r0,0x7f
        jmpc    nz,accept_3
accept_backspace:
        call    drop
        cmp     $r28,0
        jmpc    z,accept_1
        lit     8
        call    emit
        call    space
        lit     8
        call    emit
        sub     $r28,$r28,1
        jmp     accept_1
accept_3:
        cmp     $r0,'\n'
        jmpc    nz,accept_4
        call    drop
        jmp     accept_1
accept_4:
        ldi     $r1,$r27,4
        add     $r1,$r1,$r28
        sti.b   $r1,0,$r0
        ifteth  1f
        call    drop
        jmp     2f
1:      call    emit
2:      add     $r28,$r28,1
        jmp     accept_1
accept_2:
        call    two_drop
        move    $r0,$r28
        pop     $r28

        return

header  "align",align
        lda     $r1,dp
        add     $r1,$r1,3
        and     $r1,$r1,~3
        sta     dp,$r1
        return

fheader "aligned"
        add     $r0,$r0,3
        and     $r0,$r0,~3
        return

fheader "and"
        _r1_n
        and     $r0,$r0,$r1
        return

fheader "base"
        lit     _base
        return

header  "begin",begin,1
        call    check_compiling
        call    sync
        lda     $r1,pmdp
        jmp     push_r1

check_compiling:               /* Throw -14 if interpreting */
        lda     $r1,_state
        cmp     $r1,0
        ldk     $r1,-14
        jmpc    z,throw_r1
        return
throw_r1:
        call    push_r1
        jmp     throw


header  "c!",c_store
        ldi     $r1,$r27,0
        sti.b   $r0,0,$r1
        _2drop
        return

header  "c,",c_comma
        _dup
        lda     $r0,dp
        add     $r1,$r0,1
        sta     dp,$r1
        jmp     c_store

header  "c@",c_fetch
        ldi.b   $r0,$r0,0
        return

header  "uw@",uw_fetch
        ldi.s   $r0,$r0,0
        return

header  "w@",w_fetch
        ldi.s   $r0,$r0,0
        bexts   $r0,$r0,0
        return

header  "w!",w_store
        ldi     $r1,$r27,0
        sti.s   $r0,0,$r1
        _2drop
        return

header  "w,",w_comma
        _dup
        lda     $r0,dp
        add     $r1,$r0,2
        sta     dp,$r1
        jmp     w_store

fheader "cell+"
        add     $r0,$r0,4
        return

fheader "cells"
        ashl    $r0,$r0,2
        return

header  "count",count
        add     $r1,$r0,1
        add     $r27,$r27,-4
        sti     $r27,0,$r1
        ldi.b   $r0,$r0,0
        return

header  "cr",cr
        lit     '\r'
        call    emit
        lit     '\n'
        jmp     emit

fheader "create"
        call    mkheader
        call    align
        _dup
        lda     $r0,dp
        call    literal
        call    sync
        lda     $r1,pmdp
        sta     recent,$r1
        jmp     exit

header  "decimal",decimal
        ldk     $r1,10
        sta     _base,$r1
        return

header  "depth",depth
        call    dupe
        ldk     $r0,DSTACK_TOP-4
        sub     $r0,$r0,$r27
        lshr    $r0,$r0,2
        return

/*
 * How DO...LOOP is implemented
 *
 * Uses two registers:
 *    $r28 is the counter; it starts negative and counts up. When it reaches 0, loop exits
 *    $r29 is the offset. It is set up at loop start so that I can be computed from ($r28+$r29)
 *
 * So when DO we have ( limit start ) on the stack so need to compute:
 *      $r28 = start - limit
 *      $r29 = limit
 *
 * E.g. for "13 3 DO"
 *      $r28 = -10
 *      $r29 = 13
 *
 * So the loop runs:
 *      $28     -10 -9 -8 -7 -6 -5 -4 -3 -2 -1
 *      I         3  4  5  6  7  8  9 10 11 12
 *
 */

dodo:
        pop     $r1
        push    $r28
        push    $r29
                                       /* $r0 is start */
        ldi     $r29,$r27,0             /* $r29 is limit */
        cmp     $r0,$r29               /* compare for ?DO */
        sub     $r28,$r0,$r29
        _2drop
        jmpi    $r1

header  "do0cmp",do0cmp
        cmp     $r0,0
        _drop
        return
        
fheader "do",1
        ldk     $r1,0
        sta     leaves,$r1

        lit     dodo
        call    compile_comma
        jmp     begin

header  "does>",does
        lda     $r1,recent
        sta     PM_ADDR,$r1
        pop     $r1                    /* $r1 is the DOES code address */
        lshr    $r1,$r1,2
        lpm     $r2,_template_jmp
        or      $r1,$r1,$r2
        sta     PM_DATA,$r1
        return

header  "drop",drop
        ldi     $r0,$r27,0
        add     $r27,$r27,4
        return

header  "dup",dupe
        _dup
        return


fheader "evaluate"
        push_source_spec

        call    tosource
        sta     _in,$r25
        ldk     $r1,-1
        sta     _source_id,$r1

        call    interpret

        pop_source_spec
        return

header  "execute",execute
        move    $r1,$r0
        _drop
        jmpi    $r1

header  "exit",exit,1
        _dup
        lpm     $r0,_template_return
        call    code_comma
        jmp     sync

header  "fill",fill
        ldi     $r1,$r27,4
        ldi     $r2,$r27,0
        or      $cc,$r0,$r1
        or      $cc,$cc,$r2
        jmpx    0,$cc,1,1f
        memset.s $r1,$r0,$r2
        jmp     9f
1:      memset.b $r1,$r0,$r2
9:      ldi     $r0,$r27,8
        add     $r27,$r27,12
        return


header  "here",here
        _dup
        lda     $r0,dp
        return

header  "noop",noop
        nop
        return

header  "atomic-swap",atomic_swap
        ldi     $r1,$r27,0
        exi.b   $r1,$r0,0
        move    $r0,$r1
        jmp     nip

header  "dp",__dp
        _dup
        ldk     $r0,dp
        return

header  "pmdp",__pmdp
        _dup
        ldk     $r0,pmdp
        return


fheader "i"
        _dup
        add     $r0,$r28,$r29
        return

header  "(if)",paren_if_paren
        call    sync
        jmp     1f
1:      
        litm    call_do0cmp
        call    pm_comma
        lpm     $r1,_template_jz
        lshr    $r0,$r0,2
        or      $r0,$r0,$r1
        jmp     pm_comma
call_do0cmp:    call    do0cmp

fheader "if",1
        call    check_compiling
        call    false
        call    paren_if_paren
forward:                               /* forward ref to the just-compiled jmp */
        call    sync
        lda     $r1,pmdp
        sub     $r1,$r1,4
        jmp     push_r1

fheader "immediate"
       /* dict @ dup pm@ 1 or swap pm! */
        call    dupe
        lda     $r0,cwl
        ldi     $r0,$r0,4
        call    dupe
        lpmi    $r0,$r0,0
        or      $r0,$r0,1
        call    swap
        jmp     pm_store

header  "invert",invert
        xor     $r0,$r0,-1
        return

fheader "j"
        ldi     $r1,$sp,4
        ldi     $r2,$sp,8
        add     $r1,$r1,$r2
        jmp     push_r1


header  "leave",leave,1
        call    sync
        lda     $r1,leaves
        lda     $r2,pmdp
        sta     leaves,$r2

        ashr    $r1,$r1,2
        lpm     $r2,_template_jmp
        or      $r1,$r1,$r2
        call    push_r1
        call    code_comma
        jmp     sync

header  "literal",literal,1
        jmp     1f
1:      litm    cdupe
        call    pm_comma
set_r0:
       /* when r0 is outside -100000 to fffff, shift right 10, recurse, then use ldl */
        ldk     $r2,-0x80000
        cmp     $r0,$r2
        jmpc    lt,1f
        ldk     $r2,0x7ffff
        cmp     $r0,$r2
        jmpc    gt,1f

        ashl    $r0,$r0,12
        lshr    $r0,$r0,12
        lpm     $r1,_template_ldk_r0
        or      $r0,$r0,$r1
        jmp     pm_comma

cdupe:
1:      call    dupe
        ashr    $r0,$r0,10
        call    set_r0
        ldk     $r2,0x3ff
        and     $r0,$r0,$r2
        ashl    $r0,$r0,4
        lpm     $r1,_template_ldl_r0
        or      $r0,$r0,$r1
        jmp     pm_comma

fheader "loop",1
        lpm     $r1,_template_inc28
        call    push_r1
        call    code_comma

        lshr    $r0,$r0,2
        lpm     $r1,_template_j28m
        or      $r0,$r0,$r1
        call    code_comma

loop_clean:
        call    sync
        lda     $r1,leaves
loop_0:
        cmp     $r1,0
        jmpc    z,loop_1
        lpmi    $r2,$r1,0
        ldk     $r3,0x3ffff
        and     $r2,$r2,$r3
        ashl    $r2,$r2,2
        push    $r2

        call    push_r1
        call    then
        pop     $r1
        jmp     loop_0
loop_1:

        lit     unloop
        jmp     compile_comma
        
fheader "lshift"
        _r1_n
        ashl    $r0,$r1,$r0
        return

fheader "m*"
        ldi     $r1,$r27,0

        mul     $r2,$r0,$r1
        sti     $r27,0,$r2

        muluh   $r2,$r0,$r1

        ashr    $r3,$r0,31
        and     $r3,$r3,$r1
        sub     $r2,$r2,$r3

        ashr    $r3,$r1,31
        and     $r3,$r3,$r0
        sub     $r0,$r2,$r3

        return

fheader "max"
        ldi     $r1,$r27,0
        cmp     $r1,$r0
        jmpc    gt,drop
        jmp     nip

fheader "min"
        ldi     $r1,$r27,0
        cmp     $r1,$r0
        jmpc    lt,drop
        jmp     nip

fheader "mod"
        _r1_n
        mod     $r0,$r1,$r0
        return

fheader "umod"
        _r1_n
        umod    $r0,$r1,$r0
        return


header  "negate",negate
        sub     $r0,$r25,$r0
        return

fheader "or"
        _r1_n
        or      $r0,$r0,$r1
        return

header  "over",over
        _dup
        ldi     $r0,$r27,4
        return

header  "postpone",postpone,1
        call    parse_name
        call    sfind
        cmp     $r0,1
        _drop
        jmpc    z,_postpone_immed

        call    literal
        lit     compile_comma
_postpone_immed:
        jmp     compile_comma

header  "r>",r_from
        pop     $r1
        _dup
        pop     $r0
        jmpi    $r1

header  "r@",r_fetch
        _dup
        ldi     $r0,$sp,4
        return

header  "recurse",recurse,1
        _dup
        lda     $r0,thisxt
        jmp     compile_comma


header  "rot",rot
        exi     $r0,$r27,0
        exi     $r0,$r27,4
        return

fheader "rshift"
        _r1_n
        lshr    $r0,$r1,$r0
        return


fheader "s>d"
        _dup
        ashr    $r0,$r0,31
        return


header  "space",space
        lit     ' '
        jmp     emit


fheader "state"
        lit     _state
        return

header  "swap",swap
        exi     $r0,$r27,0
        return

header  "then",then,1
        call    check_compiling
        call    sync
        lda     $r1,pmdp
        lshr    $r1,$r1,2
        lpmi    $r2,$r0,0
        ldk     $r3,~0xffff
        and     $r2,$r2,$r3
        or      $r1,$r1,$r2
        sta     PM_ADDR,$r0
        sta     PM_DATA,$r1
        jmp     drop

# header  "type",type
        

fheader "u<"
        _r1_n
        cmp     $r0,$r1
        bexts   $r0,$r30,(1<<5)|6
        return

header "um*",u_m_star
        ldi     $r1,$r27,0
        mul     $r2,$r0,$r1
        muluh   $r0,$r0,$r1
        sti     $r27,0,$r2
        return

header "um/mod",u_m_slash_mod
        ldi     $r2,$r27,0
        ldi     $r3,$r27,4              /* $r2:$r3 is the dividend */
                                       /* $r0 is the divisor */
        push    $r28
        ldk     $r28,-32
u_m_slash_mod_0:
        lshr    $r4,$r3,31
        ashl    $r3,$r3,1
        cmp     $r2,0
        ashl    $r2,$r2,1
        or      $r2,$r2,$r4
       /* large $r2 case. $r2 is 0x1xxxxxxxx after shifting, so certainly greater than $r0 */
        jmpc    lt,u_m_slash_mod_2

        cmp     $r2,$r0
        jmpc    b,u_m_slash_mod_1
u_m_slash_mod_2:
        sub     $r2,$r2,$r0
        add     $r3,$r3,1
u_m_slash_mod_1:
        add     $r28,$r28,1
        cmp     $r28,0
        jmpc    nz,u_m_slash_mod_0
        pop     $r28

        add     $r27,$r27,4
        sti     $r27,0,$r2
        move    $r0,$r3
        return

header  "unloop",unloop
        pop     $r1
        pop     $r29
        pop     $r28
        jmpi    $r1

header  "until",until,1
        call    check_compiling
        jmp     paren_if_paren


fheader "xor"
        _r1_n
        xor     $r0,$r0,$r1
        return

header  "[",left_bracket,1
        sta     _state,$r25
        return


header "]",right_bracket
        ldk     $r1,3
        sta     _state,$r1
        return

#######   ANS CORE EXT   #############################################


header  "0<>",zero_notequal
        cmp     $r0,0
        bexts   $r0,$r30,(1<<5)|0
        xor     $r0,$r0,-1
        return

fheader "0>"
        cmp     $r0,0
        bexts   $r0,$r30,(1<<5)|5
        return

fheader "2>r"
        pop     $r2
        ldi     $r1,$r27,0
        push    $r1
        push    $r0
        _2drop
        jmpi    $r2

fheader "2r>"
        pop     $r3
        pop     $r2
        pop     $r1
        push    $r3
        jmp     two_lit

fheader "2r@"
        ldi     $r1,$sp,8
        ldi     $r2,$sp,4
        jmp     two_lit

_dummy: .long   0

header  ":noname",colon_noname
        ldk     $r1,_dummy             /* So that ';' will unsmudge nothing */
        sta     tosmudge,$r1
        lda     $r1,pmdp
        sta     thisxt,$r1
        call    push_r1
        jmp     right_bracket

fheader "<>"
        _r1_n
        cmp     $r0,$r1
        bexts   $r0,$r30,(1<<5)|0
        xor     $r0,$r0,-1
        return

header  "?do",question_do,1
        lit     dodo
        call    compile_comma

        call    sync
        lda     $r1,pmdp
        sta     leaves,$r1
        call    false
        call    jz_comma
        jmp     begin

header  "again",again,1
        call    check_compiling
        jmp     jmp_comma


header  "compile,",compile_comma
        jmp     1f
1:      lshr    $r0,$r0,2
        lpm     $r1,_template_call
        or      $r0,$r0,$r1
        jmp     pm_comma


header  "false",false
        _dup
        ldk     $r0,0
        return

header  "nip",nip
        add     $r27,$r27,4
        return

header  "parse",parse
        move    $r4,$r0
        lda     $r0,_in
        lda     $r1,sourceA
        add     $r0,$r0,$r1
        _dup

        ldk     $r0,-1
        lda     $r2,_in
        lda     $r3,sourceC
       /* r0 is count */
       /* r1 is sourceA */
       /* r2 is >in */
       /* r4 is char */
parse_0:
        add     $r0,$r0,1
        cmp     $r3,$r2
        jmpc    z,parse_1
        add     $r5,$r1,$r2
        ldi.b   $r5,$r5,0
        add     $r2,$r2,1
        cmp     $r4,$r5
        jmpc    nz,parse_0
parse_1:
        sta     _in,$r2
        return

fheader "pick"
        ashl    $r0,$r0,2
        add     $r0,$r0,$r27
        ldi     $r0,$r0,0
        return
        
fheader "query"

header  "refill",refill
        lda     $r1,_source_id /* When the input source is a string from EVALUATE, return false */
        cmp     $r1,-1
        jmpc    z,false

        lit     tib
        lit     256
        call    accept
        sta     sourceC,$r0
        call    drop
        sta     _in,$r25
        jmp     true


header  "roll",roll
        ashl    $r1,$r0,2
        _drop
        add     $r1,$r1,$r27
        move    $r2,$r27
        jmp     2f
1:      exi     $r0,$r2,0
        add     $r2,$r2,4
2:      cmp     $r1,$r2
        jmpc    nz,1b
        return


header "(source-id)",paren_source_id_paren
        lit     _source_id
        return


header  "true",true
        _dup
        ldk     $r0,-1
        return


fheader "u>"
        _r1_n
        cmp     $r1,$r0
        bexts   $r0,$r30,(1<<5)|6
        return

fheader "unused"
        call    dupe
        ldk     $r0,DSTACK_TOP-256
        lda     $r1,dp
        sub     $r0,$r0,$r1
        return

#######   DOUBLE AND DOUBLE EXT   ####################################

# header  "2constant",two_constant

header  "2literal",two_literal,1
        call    swap
        call    literal
        jmp     literal

header  "2rot",two_rote        /* ( x1 x2 x3 x4 x5 x6 -- x3 x4 x5 x6 x1 x2 ) */
                               /*   16 12  8  4  0       16 12  8  4  0 */
        exi     $r0,$r27,4
        exi     $r0,$r27,12

        ldi     $r1,$r27,0
        exi     $r1,$r27,8
        exi     $r1,$r27,16
        sti     $r27,0,$r1
        return
        
# header  "2variable",two_variable

header  "d+",d_plus
                               /* $r0: ud2.hi */
        ldi     $r1,$r27,0      /* $r1: ud2.lo */
        ldi     $r2,$r27,4      /* $r2: ud1.hi */
        ldi     $r3,$r27,8      /* $r3: ud1.lo */
        addcc   $r1,$r3
        bextu   $r4,$cc,(1<<5)|1
        add     $r1,$r1,$r3
        add     $r0,$r0,$r2
        add     $r0,$r0,$r4
        add     $r27,$r27,8
        sti     $r27,0,$r1
        return

header  "d-",d_minus
        call    d_negate
        jmp     d_plus

# header  "d.",d_dot
# header  "d.r",d_dot_r

header  "d0<",d_zero_less
        add     $r27,$r27,4
        ashr    $r0,$r0,31
        return

header  "d0=",d_zero_equals
        _r1_n
        or      $r0,$r0,$r1
        cmp     $r0,0
        bexts   $r0,$r30,(1<<5)|0
        return
        
header  "d2*",d_two_star
        ldi     $r1,$r27,0
        lshr    $r2,$r1,31
        ashl    $r0,$r0,1
        ashl    $r1,$r1,1
        or      $r0,$r0,$r2
        sti     $r27,0,$r1
        return

header  "d2/",d_two_slash
        ldi     $r1,$r27,0
        ashl    $r2,$r0,31
        ashr    $r0,$r0,1
        lshr    $r1,$r1,1
        or      $r1,$r1,$r2
        sti     $r27,0,$r1
        return

header  "d<",d_less_than
                                /* $r0: ud2.hi */
        ldi     $r2,$r27,4      /* $r2: ud1.hi */
        cmp     $r0,$r2
        jmpc    nz,1f
        ldi     $r1,$r27,0      /* $r1: ud2.lo */
        ldi     $r3,$r27,8      /* $r3: ud1.lo */
        cmp     $r1,$r3
        add     $r27,$r27,12
        bexts   $r0,$cc,(1<<5)|6
        return
1:
        add     $r27,$r27,12
        bexts   $r0,$cc,(1<<5)|5
        return

header  "d=",d_equals
        ldi     $r2,$r27,4      /* $r2: ud1.hi */
        xor     $r0,$r0,$r2
        ldi     $r1,$r27,0      /* $r1: ud2.lo */
        ldi     $r3,$r27,8      /* $r3: ud1.lo */
        xor     $r1,$r1,$r3
        or      $r0,$r0,$r1
        cmp     $r0,0
        add     $r27,$r27,12
        bexts   $r0,$cc,(1<<5)|0
        return

header  "d>s",d_to_s
        jmp     drop

header  "dabs",d_abs
        cmp     $r0,0
        jmpc    lt,d_negate
        return

header  "dnegate",d_negate
        ldi     $r1,$r27,0
        xor     $r0,$r0,-1
        xor     $r1,$r1,-1
        add     $r1,$r1,1
        cmp     $r1,0
        jmpc    nz,d_negate_1
        add     $r0,$r0,1
d_negate_1:
        sti     $r27,0,$r1
        return

header  "du<",d_u_less         /* ( ud1 ud2 -- flag ) */
                               /* $r0: ud2.hi */
        ldi     $r2,$r27,4      /* $r2: ud1.hi */
        cmp     $r2,$r0
        jmpc    nz,known$
        ldi     $r1,$r27,0      /* $r1: ud2.lo */
        ldi     $r3,$r27,8      /* $r3: ud1.lo */
        cmp     $r3,$r1
known$:
        add     $r27,$r27,12
        bexts   $r0,$cc,(1<<5)|1
        return

# header  "m*/",m_star_slash

#######   ANS TOOLS AND TOOLS EXT   ##################################

header  "ahead",ahead,1
        call    check_compiling
        call    false
        call    jmp_comma
        jmp     forward

#######   EXCEPTION   ################################################

header  "catch",catch  /* ( xt -- exception# | 0 ) */
        push_source_spec
        push    $r27
        lda     $r1,handler
        push    $r1
        sta     handler,$sp
        call    execute
        pop     $r1
        sta     handler,$r1
        pop     $r1
        add     $sp,$sp,source_spec_size
        jmp     false

header  "throw",throw
        cmp     $r0,0
        jmpc    z,drop
        lda     $sp,handler
        pop     $r1
        sta     handler,$r1
        pop     $r27
        pop_source_spec
        return

header  "ithrow",ithrow        /* THROW from an interrupt handler */
        ldk     $r1,throw
        push    $r1
        reti

#######   STRING   ###################################################

header  "/string",slash_string
        move    $r2,$r0
        _drop
        sub     $r0,$r0,$r2
        ldi     $r1,$r27,0
        add     $r1,$r1,$r2
        sti     $r27,0,$r1
        return

header  "cmove",cmove
        ldi     $r1,$r27,4
        ldi     $r2,$r27,0
        memcpy.b $r2,$r1,$r0
        ldi     $r0,$r27,8
        add     $r27,$r27,12
        return

header  "cmove>",cmove_up
        ldi     $r1,$r27,4      /*  */
        add     $r1,$r1,$r0    /* $r1: srcptr */
        ldi     $r2,$r27,0      /* $r2: dst */
        add     $r3,$r2,$r0    /* $r3: dstptr */
        jmp     cmove_up_1

cmove_up_0:
        sub     $r1,$r1,1
        sub     $r3,$r3,1
        ldi.b   $r4,$r1,0
        sti.b   $r3,0,$r4
cmove_up_1:
        cmp     $r2,$r3
        jmpc    nz,cmove_up_0

        ldi     $r0,$r27,8
        add     $r27,$r27,12
        return

header  "compare",compare
       /* ( c-addr1 u1 c-addr2 u2 -- n ) */
                               /* $r0: u2 */
        ldi     $r1,$r27,0      /* $r1: addr2 */
        ldi     $r2,$r27,4      /* $r2: u1 */
        ldi     $r3,$r27,8      /* $r3: addr1 */
        add     $r27,$r27,12

        cmp     $r0,$r2
        jmpc    z,2f
        jmpc    b,1f

       /* u2 is larger */
        add     $r2,$r2,$r3
        ldk     $r0,-1
        jmp     4f

1:
        add     $r2,$r0,$r3
        ldk     $r0,1
        jmp     4f

2:
        add     $r2,$r0,$r3
        ldk     $r0,0
        jmp     4f

3:
        ldi.b   $r4,$r1,0
        ldi.b   $r5,$r3,0
        cmp     $r5,$r4
        jmpc    nz,5f
        add     $r1,$r1,1
        add     $r3,$r3,1

4:
        cmp     $r2,$r3
        jmpc    nz,3b
        return

5:
        sub     $r0,$r5,$r4
        ashr    $r0,$r0,31
        or      $r0,$r0,1
        return

        .macro  tolower r
        cmp     \r,'z'
        jmpc    gt,9f
        cmp     \r,'a'
        jmpc    lt,9f
        add     \r,\r,'A'-'a'
9:
        .endm

header  "icompare",icompare
       /* ( c-addr1 u1 c-addr2 u2 -- n ) */
                               /* $r0: u2 */
        ldi     $r1,$r27,0      /* $r1: addr2 */
        ldi     $r2,$r27,4      /* $r2: u1 */
        ldi     $r3,$r27,8      /* $r3: addr1 */
        add     $r27,$r27,12

        cmp     $r0,$r2
        jmpc    z,2f
        jmpc    b,1f

       /* u2 is larger */
        add     $r2,$r2,$r3
        ldk     $r0,-1
        jmp     4f

1:
        add     $r2,$r0,$r3
        ldk     $r0,1
        jmp     4f

2:
        add     $r2,$r0,$r3
        ldk     $r0,0
        jmp     4f

3:
        ldi.b   $r4,$r1,0
        ldi.b   $r5,$r3,0
        tolower $r4
        tolower $r5
        cmp     $r5,$r4
        jmpc    nz,5f
        add     $r1,$r1,1
        add     $r3,$r3,1

4:
        cmp     $r2,$r3
        jmpc    nz,3b
        return

5:
        sub     $r0,$r5,$r4
        ashr    $r0,$r0,31
        or      $r0,$r0,1
        return

# header  "search",search
#        /* ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 flag ) */
#                                /* $r0: u2 */
#         ldi     $r1,$r27,0      /* $r1: addr2 */
#         ldi     $r2,$r27,4      /* $r2: u1 */
#         ldi     $r3,$r27,8      /* $r3: addr1 */
#         add     $r27,$r27,4
# 
#         cmp     $r0,0
#         jmpc    z,search_find
# 
# search_0:
#         move    $r4,$r1        /* r4,r5 is bounds */
#         add     $r5,$r1,$r0
#         move    $r6,$r3        /* r6 */
# 
#                                /* compare from (r4..r5) against r6.. */
# search_1:
#         ldi.b   $r7,$r4,0
#         ldi.b   $r8,$r6,0
#         cmp.b   $r7,$r8
#         jmpc    nz,search_bump
#         add     $r4,$r4,1
#         add     $r6,$r6,1
#         cmp     $r4,$r5
#         jmpc    nz,search_1
# 
# search_find:
#         sti     $r27,0,$r2
#         sti     $r27,4,$r3
#         ldk     $r0,-1
#         return
# 
# 
# search_bump:
#         sub     $r2,$r2,1
#         add     $r3,$r3,1
#         cmp     $r2,0
#         jmpc    nz,search_0
#                                /* not found */
#         ldk     $r0,0
#         return

#######   ASSEMBLER   ################################################

_template_jmp:          jmp     0
_template_call:         call    0
_template_return:       return
_template_ldk_r0:       ldk     $r0,0
_template_ldl_r0:       ldl     $r0,$r0,0
_template_jz:           jmpc    z,0
_template_inc28:        add     $r28,$r28,1
_template_j28m:         jmpx    31,$r28,1,0
_template_jnc:          jmpc    nc,0

jmp_comma:
        lshr    $r0,$r0,2
        lpm     $r1,_template_jmp
        or      $r0,$r0,$r1
        jmp     code_comma

jz_comma:
        lshr    $r0,$r0,2
        lpm     $r1,_template_jz
        or      $r0,$r0,$r1
        jmp     code_comma

#######   UART   #####################################################

header  "setpad",setpad        /* ( u n -- )  Set chip pad n to function u */
        ldk     $r1,0x1001c
        add     $r0,$r0,$r1
        ldi     $r1,$r27,0
        sti.b   $r0,0,$r1
        jmp     two_drop

orbang:
        ldi     $r1,$r27,0
        ldi     $r2,$r0,0
        or      $r1,$r1,$r2
        sti     $r0,0,$r1
        jmp     two_drop

uart.idx:
        lit     uart1_spr
        call    c_store
        lit     uart1_icr
        jmp     c_store

        .equ    CPR,    1
        .equ    TCR,    2

uart.start:
        lit     0x0010
        lit     sys_regclkcfg
        call    orbang

        lit     0x08
        lit     CPR
        call    uart.idx
        lit     4
        lit     TCR
        call    uart.idx

       /* Enable pad for UART bit [7:6] */
        lit     0xc0
        lit     48
        call    setpad

        lit     0xc0
        lit     49
        call    setpad

        lit     0x28
        lit     sys_regmsc0cfg_b2
        call    c_store

        lit     0x83
        lit     uart1_lcr
        call    c_store

        lit     217 / 8
       /* lit     195 / 8 */
        lit     uart1_dll
        call    c_store

        lit     0
        lit     uart1_dlm
        call    c_store

        lit     0x03
        lit     uart1_lcr
        call    c_store

        lit     0x00
        lit     uart1_fcr
        call    c_store

        lit     0x02
        lit     uart1_mcr
        jmp     c_store

header  "uart-emit",uart_emit
        lda.b   $r1,0x10325
        tst.b   $r1,(1<<5)
        jmpc    z,uart_emit
        sta.b   0x10320,$r0
        jmp     drop

header  "uart-key",uart_key
        _dup
key_1:
        lda.b   $r1,0x10325
        tst.b   $r1,(1<<0)
        jmpc    z,key_1
        lda.b   $r0,0x10320
        return

#######   CHARACTER I/O   ############################################

default_emit:
        jmp     uart_emit

header  "emit",emit
        jmp     uart_emit

header  "key",key
        jmp     uart_key

header  ".x",hex8
        call    dupe
        lshr    $r0,$r0,16
        call    hex4
hex4:
        call    dupe
        lshr    $r0,$r0,8
        call    hex2
hex2:
        call    dupe
        lshr    $r0,$r0,4
        call    digit
digit:
        and     $r0,$r0,15
        cmp     $r0,10
        ldk     $r1,'0'
        jmpc    lt,hex1a
        ldk     $r1,'a'-10
hex1a:  add     $r0,$r0,$r1
        jmp     emit

# header  ".s",dot_s
#         lit     '<'
#         call    emit
#         call    depth
#         call    hex2
#         lit     '>'
#         call    emit
#         call    space
# dot_s_body:
#         call    depth
#         cmp     $r0,0
#         jmpc    z,drop
# 
#         call    drop
#         push    $r0
#         call    drop
# 
#         call    dot_s_body
# 
#         call    dupe
#         pop     $r0
# 
#         call    dupe
#         jmp     dot

#######   FT900   ####################################################

header  "digitalwrite",digitalWrite    /* ( val pin -- ) */
        ldi     $r1,$r27,0

        tst     $r0,0x20
        jmpc    nz,1f

        or      $r0,$r0,1<<5           /* $r0 is the bitfield spec for bins */

        ldl     $r1,$r1,$r0
        bins    $r20,$r20,$r1
        sta     0x10084,$r20
        _2drop
        return

1:     /* For GPIO32-63, $r0 is *already* bitfield spec! */
        ldl     $r1,$r1,$r0
        bins    $r21,$r21,$r1
        sta     0x10088,$r21
        _2drop
        return

header  "digitalread",digitalRead    /* ( pin -- val ) */
        tst     $r0,0x60
        jmpc    nz,1f

        or      $r0,$r0,1<<5           /* $r0 is the bitfield spec for bexts */
        lda     $r1,0x10084
        bexts   $r0,$r1,$r0
        return

1:      tst     $r0,0x40
        jmpc    nz,2f
        /* For GPIO32-63, $r0 is *already* bitfield spec! */
        lda     $r1,0x10088
        bexts   $r0,$r1,$r0
        return

2:      /* For GPIO64+, flip r0 bits 5+6 */
        xor     $r0,$r0,0x60           /* $r0 is the bitfield spec for bexts */
        lda     $r1,0x1008c
        bexts   $r0,$r1,$r0
        return


fheader  "streamin"             # ( dst ioddr n -- )
        ldi     $r1,$r27,0
        ldi     $r2,$r27,4
        streamin.l $r2,$r1,$r0
        ldi     $r0,$r27,8
        add     $r27,$r27,12
        return

fheader  "streamin.b"           # ( dst ioddr n -- )
        ldi     $r1,$r27,0
        ldi     $r2,$r27,4
        streamin.b $r2,$r1,$r0
        ldi     $r0,$r27,8
        add     $r27,$r27,12
        return

fheader  "streamout"
        ldi     $r1,$r27,0
        ldi     $r2,$r27,4
        streamout.l $r2,$r1,$r0
        ldi     $r0,$r27,8
        add     $r27,$r27,12
        return

fheader  "streamout.b"
        ldi     $r1,$r27,0
        ldi     $r2,$r27,4
        streamout.b $r2,$r1,$r0
        ldi     $r0,$r27,8
        add     $r27,$r27,12
        return

header  "flip",_flip
        _r1_n
        flip    $r0,$r1,$r0
        return

#######   PROGRAM MEMORY   ###########################################

pm_cold:
        lpm     $r1,magic
        sta     PM_UNLOCK,$r1
        return
magic: .long   0x1337f7d1

header  "pm!", pm_store
        ldi     $r1,$r27,0
        sta     PM_ADDR,$r0
        sta     PM_DATA,$r1
        _2drop
        return

header  "pm@", pm_fetch
        lpmi    $r0,$r0,0
        return

header  "pmc@", pm_c_fetch
        lpmi.b  $r0,$r0,0
        return

fheader "words"
        call    false

words_a:
        call    cr
        call    dupe
        ashl    $r0,$r0,2
        ldi     $r0,$r0,searchlist
        ldi     $r0,$r0,4
        jmp     words_2

words_0:
        call    dupe
        lpmi    $r1,$r0,0
        add     $r0,$r0,4

        # was once useful to mark immediate words with $...
        # tst     $r1,1
        # jmpc    z,emitword
        # lit     '$'
        # call    emit
        jmp     emitword
words_1:
        call    emit
        add     $r0,$r0,1
emitword:
        call    dupe
        lpmi.b  $r0,$r0,0
        cmp     $r0,0
        jmpc    nz,words_1
        call    space
        call    two_drop

        lpmi    $r0,$r0,0
        ldk     $r1,0x3ffff
        ashl    $r1,$r1,2
        and     $r0,$r0,$r1
words_2:
        cmp     $r0,0
        jmpc    nz,words_0

        call    drop

        add     $r0,$r0,1
        lda     $r1,nsearch
        cmp     $r0,$r1
        jmpc    lt,words_a
        jmp     drop

# DEFER! ( xt2 xt1 -- ) CORE-EXT
#
# Set the word xt1 to execute xt2.
#
header  "defer!",defer_store
        call    swap
        lshr    $r0,$r0,2
        lpm     $r1,_template_jmp
        or      $r0,$r0,$r1
        call    swap

        jmp     pm_store

#######   SEARCH   ###################################################

iheader "ctx",internal_context
        lit     context_0
        lit     context_1-context_0
        return

iheader  "_wl",_wl
        lit     wordlists
        return

header  "forth-wordlist",forth_wordlist
        lit     forth
        return

header  "internal-wordlist",internal_wordlist
        lit     internal
        return

header  "get-order",get_order
        _dup
        lda     $r0,nsearch
        ashl    $r1,$r0,2
        sub     $r27,$r27,$r1
        ldk     $r2,searchlist
        memcpy.l $r27,$r2,$r1
        return

header  "set-order",set_order
        sta     nsearch,$r0
        ashl    $r1,$r0,2
        ldk     $r2,searchlist
        memcpy  $r2,$r27,$r1
        add     $r27,$r27,$r1
        jmp     drop

header  "get-current",get_current
        _dup
        lda     $r0,cwl
        return

header  "set-current",set_current
        sta     cwl,$r0
        jmp     drop

header  "definitions",definitions
        lda     $r1,searchlist
        sta     cwl,$r1
        return

header  "search-wordlist",search_wordlist

        move    $r9,$r0
        _drop

        move    $r3,$r0
        ldk     $r1,aname
        add     $r1,$r1,$r0
        sti     $r1,0,$r25

        ldk     $r2,aname
        ldi     $r1,$r27,0
        memcpy.b $r2,$r1,$r0

        call    lower_aname

        call    lookup
        cmp     $r9,0
        jmpc    nz,search_wordlist_1
        call    two_drop
        jmp     false

search_wordlist_1:
        and     $r1,$r1,~3
        sti     $r27,0,$r1
        lpmi    $r0,$r9,0
        and     $r0,$r0,1      /* 0 -> -1, 1 -> 1 */
        cmp     $r0,1
        jmpc    z,search_wordlist_2
        ldk     $r0,-1
search_wordlist_2:
        return

header  "source",source
        _dup
        lda     $r0,sourceA
        _dup
        lda     $r0,sourceC
        return

header  "tosource",tosource
        sta     sourceC,$r0
        call    drop
        sta     sourceA,$r0
        jmp     drop

fheader ">in"
        lit     _in
        return

fheader ">inwas"
        lit     _inwas
        return

#######   FLOAT   ####################################################

fheader "fdup"
        ldi     $r2,$r26,0
fpush:                                  # Push $r2 on the fp-stack
        sub     $r26,$r26,4
        sti     $r26,0,$r2
        return

fheader "fdrop"
        add     $r26,$r26,4
        return

fheader "fswap"
        ldi     $r1,$r26,0
        exi     $r1,$r26,4
        sti     $r26,0,$r1
        return

fheader "f0<"
        _dup
        ldi     $r0,$r26,0
        add     $r26,$r26,4
        bexts   $r0,$r0,(1<<5)|31
        return

header  "f<",f_less
        _dup
        ldi     $r1,$r26,0
        ldi     $r0,$r26,4
        add     $r26,$r26,8

        call    __cmpsf2_       # -1 0 1
        ashr    $r0,$r0,31      # 0 0 -1
        return

fheader "fabs"
        ldi     $r1,$r26,0
        bins    $r1,$r1,(1<<5)|31
        sti     $r26,0,$r1
        return

header  "(fliteral)",_fliteral
        pop     $r1
        lpmi    $r2,$r1,0
        add     $r1,$r1,4
        sub     $r26,$r26,4
        sti     $r26,0,$r2
        jmpi    $r1

header  "fliteral",fliteral,1
        lit     _fliteral
        call    compile_comma
        call    sync
        call    f_from
        call    pm_comma
        jmp     sync

fheader  "fdepth"
        call    dupe
        ldk     $r0,FSTACK_TOP
        sub     $r0,$r0,$r26
        ashr    $r0,$r0,2
        return

header  "s>f",s_to_f
        call    __floatsisf
_to_f:
        sub     $r26,$r26,4
        sti     $r26,0,$r0
        jmp     drop

header  "us>f",us_to_f
        call    __floatunsisf
        jmp     _to_f

header  "f>",f_from
        call    dupe
        ldi     $r0,$r26,0
        add     $r26,$r26,4
        return

header  ">f",to_f
        jmp     _to_f

header  "fnegate",f_negate
        ldi     $r1,$r26,0
        bins    $r2,$r25,-512|(1<<5)|31  # r2 = 80000000
        xor     $r1,$r1,$r2
        sti     $r26,0,$r1
        return

header  "f+",f_plus
        push    $r0
        ldi     $r1,$r26,0
        ldi     $r0,$r26,4

        call    __addsf3
_f2:                                    # handle result of 2-ary operator
        add     $r26,$r26,4
        sti     $r26,0,$r0
        pop     $r0
        return

header  "f-",f_minus
        push    $r0
        ldi     $r1,$r26,0
        ldi     $r0,$r26,4
        call    __subsf3
        jmp     _f2

header  "f*",f_mul
        push    $r0
        ldi     $r1,$r26,0
        ldi     $r0,$r26,4
        call    __mulsf3
        jmp     _f2

header  "f/",f_div
        push    $r0
        ldi     $r1,$r26,0
        ldi     $r0,$r26,4
        call    __divsf3
        jmp     _f2

        .include "float.s"

header  "f>d",f_to_d
        sub     $r27,$r27,8
        sti     $r27,4,$r0

        ldi     $cc,$r26,0
        add     $r26,$r26,4

        jmpx    31,$cc,0,0f

        call    0f
        jmp     d_negate

0:
        ashl    $r2,$cc,8               # mantissa left-justified in r2...
        bins    $r2,$r2,-512|(1 << 5)|31 # ...with implied bit set
        bextu   $r3,$cc,(8<<5)|23       # exponent in r3

        # exponent      lo                      hi
        # --------      --                      --
        # <127          0                       0
        # 127           m>>31                   0
        # ...
        # 158           m>>0                    0
        # 159           m<<1                    m>>31
        # ...
        # 189           m<<31                   m>>1
        # 190           --------  overflow  --------
        #
        # So a little algebra gives three cases:
        #
        # exponent      lo                      hi
        # --------      --                      --
        # <127          0                       0
        # 127 .. 158    m>>(158-e)              0
        # 159 .. 189    m<<(e-158)              m>>(190-e)
        # >=190         --------  overflow  --------

        cmp     $r3,127
        jmpc    gte,1f
        ldk     $r1,0                   # lo
        ldk     $r0,0                   # hi
        jmp     3f

1:      cmp     $r3,158
        jmpc    gt,2f

        ldk     $r4,158                 # 
        sub     $r4,$r4,$r3
        lshr    $r1,$r2,$r4             # lo
        ldk     $r0,0                   # hi
        jmp     3f

2:      sub     $r4,$r3,158
        ashl    $r1,$r2,$r4             # lo
        ldk     $r4,190
        sub     $r4,$r4,$r3
        lshr    $r0,$r2,$r4
3:
        sti     $r27,0,$r1
        return

#######   SYSTEM VARIABLES   #########################################

        .section        .bss

        .set    ramhere,0

        .macro  allot   name size
        .equ    \name,ramhere
        .set    ramhere,ramhere+\size
        .endm

        allot   guardian,4     /*  */
        allot   context_0,0
        allot   dp,4           /* RAM data pointer */
        allot   pmdp,4         /* PM data pointer */
        allot   cwl,4          /* Compilation word list */
        allot   wordlists,4    /* All word lists */
        allot   nsearch,4      /* Number of word lists in searchlist */
        allot   searchlist,4*16/* search list */
        allot   context_1,0
        allot   forth,8        /* Forth word list */
        allot   internal,8     /* Internal word list */
        allot   handler,4      /* exception handler */
        allot   aname,32       /* name buffer, used during dictionary search */
        allot   tib,256        /* terminal input buffer */
        allot   sourceA,4      /* tib+1 */
        allot   sourceC,4       #
        allot   _in,4          /* >IN */
        allot   _inwas,4       /* >IN at start of previous word */
        allot   recent,4       /* most recent CREATE */
        allot   thisxt,4       /* most recent xt */
        allot   tosmudge,4     /* smudge point, usually xt-4 */
        allot   leaves,4       /* chain of LEAVE pointers */
        allot   _source_id,4
        allot   _state,4
        allot   _base,4
        allot   _tethered,4

__end:
        .section        .text

#######   OUTER INTERPRETER   ########################################

header  "report",report        /* ( u -- 0 ) describe error u */
        jmp     drop

# QUIT implementation based on ANS A.9

header  "quit",quit
        ldk     $sp,0xfffc

        sta     _source_id,$r25

        call    left_bracket

quit_0:
        lit     repl
        call    catch
        cmp     $r0,0
        jmpc    z,quit_ok

        call    report
        jmp     quit

repl:
        lit     tib
        call    dupe
        lit     256
        call    accept
        call    tosource

        call    space

        sta     _in,$r25
        jmp     interpret

quit_ok:
        call    drop
        call    space
        lit     'o'
        call    emit
        lit     'k'
        call    emit
        call    cr
        jmp     quit_0

header  "hook-number",hook_number
        lit     -13                    /* undefined word ( ANS spec. section 9.3.5 ) */
        call    throw

isvoid:
        call    nip
        call    do0cmp
        jmpc    z,1f
        call    two_drop
        call    hook_number
        pop     $r1
        pop     $r1
1:      return

# consume1  ( caddr u -- caddr' u' )
# if string starts with $r2, bump character and return NZ

consume1:
        ldi     $r3,$r27,0
        ldi.b   $r1,$r3,0
        cmp.b   $r2,$r1
        jmpc    z,1f
0:
        cmp     $r0,$r0                 # Set Z
        return
1:
        cmp     $r0,0
        jmpc    z,0b
        sub     $r0,$r0,1
        add     $r3,$r3,1
        sti     $r27,0,$r3
        return

doubleAlso2:
        lit     0
        lit     0
        call    two_swap
        ldk     $r2,'-'
        call    consume1
        push    $cc
        call    to_number
        ldk     $r2,'.'
        call    consume1
        jmpc    z,1f
        call    isvoid
        pop     $cc
        callc   nz,d_negate
        lit     two_literal
        return
1:
        call    isvoid
        _drop
        pop     $cc
        callc   nz,negate
        lit     literal
        return

# Set BASE to $r2, call doubleAlso2, restore BASE
baseDoubleAlso2:
        lda     $r1,_base
        push    $r1
        sta     _base,$r2
        lit     doubleAlso2
        call    catch
        pop     $r1
        sta     _base,$r1
        jmp     throw

doubleAlso1:
        ldk     $r2,'$'
        call    consume1
        ldk     $r2,16
        jmpc    nz,baseDoubleAlso2

        ldk     $r2,'#'
        call    consume1
        ldk     $r2,10
        jmpc    nz,baseDoubleAlso2

        ldk     $r2,'%'
        call    consume1
        ldk     $r2,2
        jmpc    nz,baseDoubleAlso2

        cmp     $r0,3
        jmpc    nz,doubleAlso2
        ldi     $r1,$r27,0
        ldi.b   $r2,$r1,0
        cmp     $r2,'\''
        jmpc    nz,doubleAlso2
        ldi.b   $r2,$r1,2
        cmp     $r2,'\''
        jmpc    nz,doubleAlso2

        call    drop
        ldi.b   $r0,$r0,1
        lit     literal
        return

doubleAlso:
        call    doubleAlso1
        jmp     drop

doubleAlso_comma:
        call    doubleAlso1
        jmp     execute

dispatch:
        jmp     execute                 #      -1      0       non-immediate
        jmp     doubleAlso              #      0       0       number
        jmp     execute                 #      1       0       immediate

        jmp     compile_comma           #      -1      2       non-immediate
        jmp     doubleAlso_comma        #      0       2       number
        jmp     execute                 #      1       2       immediate
        
guardian:
        .long   0x70617773

header  "interpret",interpret
        lda     $r1,_in
        sta     _inwas,$r1
        call    parse_name
        cmp     $r0,0
        jmpc    z,two_drop

        call    sfind
        lda     $r1,_state
        add     $r0,$r0,$r1
        ashl    $r0,$r0,2
        ldk     $r1,(dispatch+4)
        add     $r0,$r0,$r1
        call    execute

        ldk     $r1,DSTACK_TOP
        cmp     $r27,$r1
        ldk     $r1,-4                 /* stack underflow */
        jmpc    a,throw_r1
        jmp     interpret

        lda     $r1,0
        lpm     $r2,guardian
        cmp     $r1,$r2
        ldk     $r1,-9                 /* memory error */
        jmpc    nz,throw_r1

        jmp     interpret

/*
 *      PARSE-NAME  ( <spaces>name -- c-addr u )

 * Skip leading spaces and parse name delimited by a space. c-addr
 * is the address within the input buffer and u is the length of the
 * selected string. If the parse area is empty, the resulting string has
 * a zero length.
 */

header  "parse-name",parse_name
        call    _skipspaces
        _dup
        lda     $r1,_in
        lda     $r0,sourceA
        add     $r0,$r0,$r1
        call    _parse_word
        _dup
        move    $r0,$r3
        return

_skipspaces:
        lda     $r1,_in
        lda     $r4,sourceC
_skipspaces_0:
        cmp     $r1,$r4
        jmpc    z,_skipspaces_finish
        lda     $r3,sourceA
        add     $r3,$r3,$r1
        ldi.b   $r2,$r3,0
        cmp     $r2,' '
        jmpc    a,_skipspaces_finish
        add     $r1,$r1,1
        jmp     _skipspaces_0
_skipspaces_finish:
        sta     _in,$r1
        return

_parse_word:
        /* Scan the current input buffer for a word
         * $r3 is length, and word copied into aname
         * if end of buffer, $r3 is zero.
         */

        call    _skipspaces

        ldk     $r3,0                  /* Current ptr into aname */
        ldk     $r2,aname
        memset  $r2,$r25,32
        lda     $r4,sourceC

_parse_word_loop:
        lda     $r1,_in
        cmp     $r1,$r4
        jmpc    z,_parse_word_finish

        lda     $r5,sourceA
        add     $r5,$r5,$r1
        ldi.b   $r2,$r5,0
        add     $r1,$r1,1
        sta     _in,$r1

        cmp     $r2,' '
        jmpc    be,_parse_word_finish

       /* append non-blank to aname */
        sti.b   $r3,aname,$r2
        add     $r3,$r3,1
        jmp     _parse_word_loop

_parse_word_finish:
        return

/*

SFIND
        ( c-addr u -- c-addr u 0 | xt 1 | xt -1 )

        Find the definition named in the string at c-addr. If the
        definition is not found, return c-addr and zero. If the definition
        is found, return its execution token xt. If the definition is
        immediate, also return one (1), otherwise also return minus-one
        (-1).

*/
header  "sfind",sfind

        move    $r3,$r0
        ldk     $r1,aname
        add     $r1,$r1,$r0
        sti     $r1,0,$r25

        ldk     $r2,aname
        ldi     $r1,$r27,0
        memcpy.b $r2,$r1,$r0

        call    lower_aname

        ldk     $r2,0          /* $r2 counts through search order */
sfind_0:
        push    $r2
        push    $r3
        ashl    $r2,$r2,2
        ldi     $r9,$r2,searchlist
        call    lookup
        pop     $r3
        pop     $r2
        cmp     $r9,0
        jmpc    nz,sfind_1

        add     $r2,$r2,1      /* try next wordlist */
        lda     $r4,nsearch
        cmp     $r2,$r4
        jmpc    lt,sfind_0

        jmp     false
sfind_1:
        and     $r1,$r1,~3
        sti     $r27,0,$r1
        lpmi    $r0,$r9,0
        and     $r0,$r0,1      /* 0 -> -1, 1 -> 1 */
        cmp     $r0,1
        jmpc    z,sfind_2
        ldk     $r0,-1
sfind_2:
        return

lookup:
       /* On entry: */
       /*       $r9     word list to search */
       /*       a word of length $r3 at aname, 0x00 padded */
       /* On exit:  */
       /*       $r13    padded length (in bytes) */
       /*       $r9     found word's link, or zero */
       /*       $r1     found word's xt (if $r9 is nonzero) */

        add     $r13,$r3,4
        and     $r13,$r13,~3

        lda     $r1,aname+0
        lda     $r2,aname+4
        lda     $r3,aname+8
        lda     $r4,aname+12
        lda     $r5,aname+16
        lda     $r6,aname+20
        lda     $r7,aname+24
        lda     $r8,aname+28

        ldi     $r9,$r9,4
        ldk     $r15,0x3ffff
        ashl    $r15,$r15,2

       /* $r12 is comparison code */
        mul     $r14,$r13,3            /* 3 instructions for each compare */
        ldk     $r12,compare_0
        sub     $r12,$r12,$r14
        jmp     lookup_1
nomatch:
        lpmi    $r9,$r9,0
        and     $r9,$r9,$r15
lookup_1:
        cmp     $r9,0
        jmpic    nz,$r12
endsearch:
        return

compare_8:
        lpmi    $r10,$r9,32
        cmp     $r10,$r8
        jmpc    nz,nomatch
compare_7:
        lpmi    $r10,$r9,28
        cmp     $r10,$r7
        jmpc    nz,nomatch
compare_6:
        lpmi    $r10,$r9,24
        cmp     $r10,$r6
        jmpc    nz,nomatch
compare_5:
        lpmi    $r10,$r9,20
        cmp     $r10,$r5
        jmpc    nz,nomatch
compare_4:
        lpmi    $r10,$r9,16
        cmp     $r10,$r4
        jmpc    nz,nomatch
compare_3:
        lpmi    $r10,$r9,12
        cmp     $r10,$r3
        jmpc    nz,nomatch
compare_2:
        lpmi    $r10,$r9,8
        cmp     $r10,$r2
        jmpc    nz,nomatch
compare_1:
        lpmi    $r10,$r9,4
        cmp     $r10,$r1
        jmpc    nz,nomatch
compare_0:
        add     $r1,$r9,4
        add     $r1,$r1,$r13
        jmp     endsearch

# Save the current pointers to PM so that they will be restored at reboot.
# Append active RAM to the end of PM, so that it will be restored 
# Return the end of the complete PM region

header  "commit",commit        /* ( -- pmend ) */
        call    pmhere
        lit     saved_pmdp
        call    pm_store

        call    dupe
        lda     $r0,dp
        lit     saved_dp
        call    pm_store
        
        call    dupe
        lda     $r0,pmdp
        sta     PM_ADDR,$r0

        ldk     $r0,PM_DATA
        ldk     $r1,0
        lda     $r2,dp

        streamout $r0,$r1,$r2

        lda     $r0,pmdp
        add     $r0,$r0,$r2

        return

header  "pmhere",pmhere
        call    dupe
        lda     $r0,pmdp
        return

header  "int-caller",int_caller
        ldi     $r1,$sp,20*4
        jmp     push_r1

#######   BOOT   #####################################################

h80000000:      .long   0x80000000

codestart:

        ldk     $r1,0x80
        sta.b   sys_regmsc0cfg_b3,$r1

       /* Enable the RTC as soon as possible */
       /* Write 1 to RTC_EN in RTC_CCR */
        ldk     $r1,(1 << 2)
        sta     0x1028c,$r1

       /* lpm     $r1,h80000000 */
       /* sta     0x10018,$r1 */

        ldk     $r26,FSTACK_TOP
        ldk     $r27,DSTACK_TOP

        ldk     $r20,0                 /* GPIO shadows */
        ldk     $r21,0
        ldk     $r22,0
        ldk     $r25,0                 /* constant 0 */

        lpm     $r1,saved_pmdp
        sta     pmdp,$r1
        lpm     $r2,saved_dp
        sta     dp,$r2

       /* copy all of RAM from pm[pmdp to pmdp+dp] */
        ldk     $r0,0                  /* dest */
ramloader:
        lpmi    $r3,$r1,0
        sti     $r0,0,$r3
        add     $r0,$r0,4
        add     $r1,$r1,4
        cmp     $r0,$r2
        jmpc    be,ramloader

        call    uart.start

        sta     _tethered,$r25
        call    decimal
        call    left_bracket
        call    pm_cold

        ldk     $r0,emit
        sta     PM_ADDR,$r0
        lpm     $r0,default_emit
        sta     PM_DATA,$r0

        call    cr
        lit     80
banner:
        lit     '-'
        call    emit

        add     $r0,$r0,-1
        cmp     $r0,0
        jmpc    nz,banner
        call    drop

        lpm     $r1,coldname           /* find a word named 'cold' */
        sta     0,$r1

        lit     0
        lit     4
        call    sfind

        cmp     $r0,0
        call    drop
        jmpc    z,no_cold

        call    execute
        call    cr

        jmp     quit

no_cold:
        call    cr                     /* empty banner */
        call    two_drop
        jmp     quit

coldname:
        .ascii "cold"

# RAM is initialized from PM as follows:
#   pmdp is loaded from saved_pmdp
#   dp is loaded from saved_dp
#   Then RAM is copied from pm[pmdp .. pmdp+dp]

saved_pmdp:     .long   endcode
saved_dp:       .long   ramhere


endcode:
        .long   0x70617773     /* guardian */
        .long   ramhere        /* dp */
        .long   endcode        /* pmdp */
        .long   forth          /* cwl */
        .long   forth          /* word lists */
        .long   2              /* nsearch */
        .long   forth          /* searchlist */
        .long   internal
        .long   0
        .long   0
        .long   0
        .long   0
        .long   0
        .long   0
        .long   0
        .long   0
        .long   0
        .long   0
        .long   0
        .long   0
        .long   0
        .long   0

        .long   internal       /* forth word list #0 */
        .long   forth_link     /* forth word list #4 */
        .long   0              /* internal word list #0 */
        .long   internal_link  /* internal word list #4 */
