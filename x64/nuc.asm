;
; For C code, the caller-preserved registers are: rbp, rbx, r12, r13, r14, r15
;
; Arguments are passed in: rdi, rsi, rdx, rcx, r8, r9
;
; In SwapForth usage is:
;
; TOS    Top-of-stack                rax        eax
; TMP    scratch register            rcx        ecx
; DSP    data stack pointer          rdi        edi
;        return stack pointer        rsp        esp
; CTX    context pointer             r12        ebp
; LPC    loop counter                r13        ebx
; LPO    loop offset                 r14        edx
;

%if (CELL == 8)
%define L2CELL          3
%define CELLPTR         qword

%define TOS             rax
%define DSP             rdi
%define CTX             r12
%define TMP             rcx
%define LPC             r13
%define LPO             rdx

%define SXT             cqo

        ;; C interface macro, parameter is offset into CTABLE
        %macro  c_pre   1
        push    rbp
        push    rdi     ;; Our data stack pointer, C clobbers
        mov     rbp,rsp ;; Save the SP
        or      rsp,8   ;; Now align SP, C needs this
        sub     rsp,8
        mov     rdi,TOS ;; Always pass TOS as argument
        mov     rax,[r12 + _cfuncs]
        call    [rax + %1]
        mov     rsp,rbp ;; restore our SP
        pop     rdi     ;; restore our data stack pointer
        pop     rbp
        %endmacro
%else
%define L2CELL          2
%define CELLPTR         dword

%define TOS             eax
%define DSP             edi
%define CTX             ebp
%define TMP             ecx
%define rsp             esp
%define LPC             ebx
%define LPO             edx

%define SXT             cdq

        ;; C interface macro, parameter is offset into CTABLE
        %macro  c_pre   1
        push    edx
        push    ebx
        push    ebp
        push    edi     ;; Our data stack pointer, C clobbers
        mov     ebx,esp ;; Caller-preserved
        sub     esp,16
        and     esp,~15
        mov     [esp+0],eax
        mov     eax,[ebp + _cfuncs]
        call    [eax + %1]
        mov     esp,ebx
        pop     edi     ;; restore our data stack pointer
        pop     ebp
        pop     ebx
        pop     edx
        %endmacro
%endif

%define CELLS(N)        (CELL * N)

;; A dictionary entry (i.e. a word) looks like this:
;;
;;     |--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
;; -32 |C | NAME                                       |
;;     |--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
;; -16 |                                               |
;;     |--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
;; +0  | LINK      | CBYTES    | CODE...
;;     |--+--+--+--+--+--+--+--+
;;
;; Note that LINK is a relative link to the next word.
;; CBYTES is the size of the code in bytes, used for inlining.
;;

%define WORD_NAME       -32     ;; word name as a counted string
%define WORD_LINK       0       ;; relative link to prev word
%define WORD_CBYTES     4       ;; code size in bytes, for inlining
%define WORD_CODE       8       ;; start of native code

;; This table matches CFUNCS in main.c

CFUNC_DOTX      equ     CELLS(0)
CFUNC_BYE       equ     CELLS(1)
CFUNC_EMIT      equ     CELLS(2)
CFUNC_KEY       equ     CELLS(3)

section .text

global swapforth
global _swapforth
swapforth:
_swapforth:
        jmp     init

%define ao 0
%macro object   2
%1      equ     ao
%%n     equ     ao+%2
        %define ao %%n
%endmacro

        object  _base,          CELLS(1)
        object  _forth,         CELLS(1)
        object  _dp,            CELLS(1)
        object  _cp,            CELLS(1)
        object  _in,            CELLS(1)
        object  _jumptab,       CELLS(6)
        object  _prevcall,      CELLS(1)
        object  _lastword,      CELLS(1)
        object  _thisxt,        CELLS(1)
        object  _sourceid,      CELLS(1)
        object  _sourceC,       CELLS(2)
        object  _state,         CELLS(1)
        object  _leaves,        CELLS(1)
        object  _tethered,      CELLS(1)
        object  _scratch,       32
        object  _cfuncs,        CELLS(1)
        object  _tib,           128

%define link $

%define IMMEDIATE       1       ;; IMMEDIATE words have this bit set in link
%define INLINE          2       ;; 

%assign wnum    0               ;; Word number, for computing CBYTES

%macro  header  2-3     0
L%[wnum]:
        %assign wnum wnum+1
        align   32
        %strlen %%count %1
        db %%count,%1
        align   32
%%link  dd   $-link + %3                ;; relative link to prev word
        %define link %%link
        dd      L%[wnum] - ($+5)        ;; CBYTES: code size in bytes
%2:
%endmacro

%macro  popTMP  0
        mov     TMP,[DSP]
        add     DSP,CELL
%endmacro

%macro  _dup    0
        mov     [DSP-CELL],TOS
        sub     DSP,CELL
%endmacro

%macro  _nip    0
        add     DSP,CELL
%endmacro

%macro  _drop   0
        mov     TOS,[DSP]
        add     DSP,CELL
%endmacro

%macro  _drop2   0
        mov     TOS,[DSP+CELL]
        add     DSP,CELLS(2)
%endmacro

%macro  _drop3   0
        mov     TOS,[DSP+CELLS(2)]
        add     DSP,CELLS(3)
%endmacro

%macro  _tos0   0
        or      TOS,TOS
        mov     TOS,[DSP]
        lea     DSP,[DSP+CELL]
%endmacro

%macro  lit     1
        _dup
        mov     TOS,%1
%endmacro

%if (CELL == 8)

%macro  tick    1
        _dup
        lea     TOS,[rel %1]
%endm

%else

%macro  tick    1
        _dup
        call    fowia
        add     eax,(%1 - $)
%endm

%endif

%macro  cond    1
        mov     TOS,0
        mov     TMP,-1
        cmov%1  TOS,TMP
%endmacro

%macro  _to_r   0
        push    TOS
        _drop
%endmacro

%macro  _r_from 0
        _dup
        pop     TOS
%endmacro


fowia:  mov     eax,[esp]
        ret

        header  ".x",dotx       ; ( x -- )
        c_pre   CFUNC_DOTX
        jmp     drop

        header  "bye",bye
        c_pre   CFUNC_BYE       ;; never returns

        header  "emit",emit     ; ( x -- )
        c_pre   CFUNC_EMIT
        jmp     drop

        header  "key",key       ;; ( -- x )
        _dup
        c_pre   CFUNC_KEY
        ret

header  "depth",depth
        mov     TMP,CTX
        sub     TMP,DSP
        _dup
        mov     TOS,TMP
        sar     TOS,L2CELL
        ret

header  "base",base
        _dup
        lea     TOS,[CTX + _base]
        ret

header  ">in",to_in
        _dup
        lea     TOS,[CTX + _in]
        ret

header  "source",source
        _dup
        lea     TOS,[CTX + _sourceC]
        jmp     two_fetch

header  "source-id",source_id
        _dup
        mov     TOS,[CTX + _sourceid]
        ret

source_store:
        _dup
        lea     TOS,[CTX + _sourceC]
        jmp     two_store

header "2*",two_times,INLINE
        sal     TOS,1
        ret

header "2/",two_slash,INLINE
        sar     TOS,1
        ret

header "1+",one_plus,INLINE
        inc     TOS
        ret

header "1-",one_minus,INLINE
        dec     TOS
        ret

header "0=",zero_equals,INLINE
        cmp     TOS,0
        cond    e
        ret

header "cell+",cell_plus,INLINE
        add     TOS,CELL
        ret

header "cells",cells,INLINE
        shl     TOS,L2CELL
        ret

header "<>",not_equal,INLINE
        cmp     [DSP],TOS
        cond    ne
        add     DSP,CELL
        ret

header "=",equal,INLINE
        cmp     [DSP],TOS
        cond    e
        add     DSP,CELL
        ret

header ">",greater,INLINE
        cmp     [DSP],TOS
        cond    g
        add     DSP,CELL
        ret

header "<",less,INLINE
        cmp     [DSP],TOS
        cond    l
        add     DSP,CELL
        ret

header "0<",less_than_zero,INLINE
        sar     TOS,(8*CELL-1)
        ret

header "0>",greater_than_zero,INLINE
        cmp     TOS,0
        cond    g
        ret

header "0<>",not_equal_zero,INLINE
        add     TOS,-1
        sbb     TOS,TOS
        ret

header "u<",unsigned_less,INLINE
        cmp     [DSP],TOS
        cond    b
        add     DSP,CELL
        ret

header "u>",unsigned_greater,INLINE
        cmp     [DSP],TOS
        cond    a
        add     DSP,CELL
        ret

header  "+",plus,INLINE
        add     TOS,[DSP]
        add     DSP,CELL
        ret

header  "s>d",s_to_d,INLINE
        _dup
        sar     TOS,(8*CELL-1)
        ret

header  "d>s",d_to_s,INLINE
        _drop
        ret

header  "m+",m_plus
        call    s_to_d
        jmp     d_plus

header  "d+",d_plus
        mov     TMP,[DSP]
        add     [DSP+CELLS(2)],TMP
        adc     [DSP+CELL],TOS
        _drop2
        ret

header  "d=",d_equal
        cmp     [DSP+CELL],TOS
        jne     .1
        mov     TMP,[DSP+CELLS(2)]
        cmp     TMP,[DSP]
.1:
        cond    e
        add     DSP,CELLS(3)
        ret

header  "du<",d_u_less
        cmp     [DSP+CELL],TOS
        jne     .1
        mov     TMP,[DSP+CELLS(2)]
        cmp     TMP,[DSP]
.1:
        cond    b
        add     DSP,CELLS(3)
        ret

header  "d<",d_less
        cmp     [DSP+CELL],TOS
        jne     .1
        mov     TMP,[DSP+CELLS(2)]
        cmp     TMP,[DSP]
        cond    b
        add     DSP,CELLS(3)
        ret
.1:
        cond    l
        add     DSP,CELLS(3)
        ret

header  "d0<",d_less_than_zero
        _nip
        jmp     less_than_zero

header  "dnegate",d_negate
        not     TOS
        not     CELLPTR [DSP]
        lit     1
        jmp     m_plus

header  "d-",d_minus
        mov     TMP,[DSP]
        sub     [DSP+CELLS(2)],TMP
        sbb     [DSP+CELL],TOS
        jmp     two_drop

header  "d2*",d_two_times,INLINE
        shl     CELLPTR [DSP],1
        adc     TOS,TOS
        ret

header  "d2/",d_two_slash,INLINE
        sar     TOS,1
        rcr     CELLPTR [DSP],1
        ret

header  "-",minus,INLINE
        popTMP
        sub     TMP,TOS
        mov     TOS,TMP
        ret

header  "negate",negate,INLINE
        neg     TOS
        ret

header  "invert",invert,INLINE
        not     TOS
        ret

header  "and",and,INLINE
        and     TOS,[DSP]
        add     DSP,CELL
        ret

header  "or",or,INLINE
        or      TOS,[DSP]
        add     DSP,CELL
        ret

header  "xor",xor,INLINE
        xor     TOS,[DSP]
        add     DSP,CELL
        ret

header  "lshift",lshift,INLINE
        mov     TMP,TOS
        mov     TOS,[DSP]
        shl     TOS,cl
        add     DSP,CELL
        ret

header  "rshift",rshift,INLINE
        mov     TMP,TOS
        mov     TOS,[DSP]
        shr     TOS,cl
        add     DSP,CELL
        ret

header  "abs",_abs,INLINE
        mov     TMP,TOS
        sar     TMP,(8*CELL-1)
        xor     TOS,TMP
        sub     TOS,TMP
        ret

header  "um*",u_m_multiply,INLINE
        push    LPO
        mul     CELLPTR [DSP]
        mov     [DSP],TOS
        mov     TOS,LPO
        pop     LPO
        ret

header  "*",multiply,INLINE
        imul    TOS,[DSP]
        add     DSP,CELL
        ret

header  "/",divide
        mov     TMP,TOS
        mov     TOS,[DSP]
        SXT
        idiv    TMP
        add     DSP,CELL
        ret

header  "mod",mod
        push    LPO
        mov     TMP,TOS
        mov     TOS,[DSP]
        SXT
        idiv    TMP
        mov     TOS,LPO
        add     DSP,CELL
        pop     LPO
        ret

header  "um/mod",u_m_slash_mod
        push    LPO
        mov     TMP,TOS
        mov     LPO,[DSP]
        mov     TOS,[DSP+CELL]
        div     TMP
        mov     [DSP+CELL],LPO
        _nip
        pop     LPO
        ret

header  "c@",c_fetch,INLINE
        movzx   TOS,byte [TOS]
        ret

header  "c!",c_store,INLINE
        mov     cl,byte [DSP]
        mov     [TOS],cl
        _drop2
        ret

header  "@",fetch,INLINE
        mov     TOS,[TOS]
        ret

header  "!",store,INLINE
        mov     TMP,[DSP]
        mov     [TOS],TMP
        _drop2
        ret

%if (CELL == 8)
header  "ul@",u_l_fetch,INLINE
        mov     eax,dword [TOS]
        ret

header  "sl@",s_l_fetch,INLINE
        movsx   TOS,dword [TOS]
        ret
%endif

header  "2@",two_fetch,INLINE
        mov     TMP,[TOS+CELL]
        mov     TOS,[TOS]
        sub     DSP,CELL
        mov     [DSP],TMP
        ret

header  "2!",two_store,INLINE
        mov     TMP,[DSP]
        mov     [TOS],TMP
        mov     TMP,[DSP+CELL]
        mov     [TOS+CELL],TMP
        _drop3
        ret

header  "/string",slash_string
        mov     TMP,TOS
        _drop
        sub     TOS,TMP
        add     [DSP],TMP
        ret

header  "swap",swap,INLINE
        mov     TMP,[DSP]
        mov     [DSP],TOS
        mov     TOS,TMP
        ret

header  "over",over,INLINE
        _dup
        mov     TOS,[DSP+CELL]
        ret

header "false",false,INLINE
        _dup
        xor     TOS,TOS
        ret

header "true",true,INLINE
        _dup
        mov     TOS,-1
        ret

header "bl",_bl,INLINE
        lit     32
        ret

header "rot",rot,INLINE
        xchg    TOS,[DSP]
        xchg    TOS,[DSP+CELL]
        ret

header "noop",noop
        ret

header "-rot",minus_rot,INLINE
        xchg    TOS,[DSP+CELL]
        xchg    TOS,[DSP]
        ret

header "tuck",tuck     ; : tuck  swap over ; 
        call    swap
        jmp     over

header "?dup",question_dupe     ; : ?dup  dup if dup then ;
        cmp     TOS,0
        jne     dupe
        ret

header "2dup",two_dup,INLINE     ; : 2dup  over over ; 
        _dup
        mov     TOS,[DSP+CELL]
        _dup
        mov     TOS,[DSP+CELL]
        ret

header "+!",plus_store,INLINE       ; : +!    tuck @ + swap ! ; 
        mov     TMP,[DSP]
        add     [TOS],TMP
        _drop2
        ret

header "2swap",two_swap,INLINE    ; : 2swap rot >r rot r> ;
        mov     TMP,[DSP]
        xchg    TOS,[DSP+CELL]
        xchg    TMP,[DSP+CELLS(2)]
        mov     [DSP],TMP
        ret

 header "2over",two_over,INLINE
        _dup
        mov     TOS,[DSP+CELLS(3)]
        _dup
        mov     TOS,[DSP+CELLS(3)]
        ret

header "min",min,INLINE
        popTMP
        cmp     TOS,TMP
        cmovg   TOS,TMP
        ret

header "max",max,INLINE
        popTMP
        cmp     TOS,TMP
        cmovl   TOS,TMP
        ret

header  "space",space
        lit     ' '
        jmp     emit

header  "cr",cr
        lit     10
        jmp     emit

header "count",count,INLINE
        inc     TOS
        _dup
        movzx   TOS,byte [TOS-1]
        ret

header "dup",dupe,INLINE
        _dup
        ret

header "drop",drop,INLINE
        _drop
        ret

header  "nip",nip,INLINE
        add     DSP,CELL
        ret

header "2drop",two_drop,INLINE
        _drop2
        ret

header "execute",execute
        mov     TMP,TOS
        _drop
        jmp     TMP

header "bounds",bounds,INLINE ; ( a n -- a+n a )
        mov     TMP,[DSP]
        add     TOS,TMP
        mov     [DSP],TOS
        mov     TOS,TMP
        ret

header "type",type
        call    bounds
.0:
        cmp     TOS,[DSP]
        je      .2
        _dup
        movzx   TOS,byte [TOS]
        call    emit
        inc     TOS
        jmp     .0
.2:     jmp     two_drop

; ( caddr u -- caddr u )
; write a word into the scratch area with appropriate padding etc
w2scratch:
        movaps  xmm0,[rel nops]
        movups  [CTX+_scratch],xmm0

        mov     byte [CTX+_scratch],al
        call    two_dup
        _dup
        lea     TOS,[CTX+_scratch+1]
        call    swap
        jmp     cmove

        align   32
nops:   times 16 db 0x90
aaaa:   times 16 db ('A'-1)
zzzz:   times 16 db 'Z'
case:   times 16 db 0x20

        %macro  lower   1
        movaps  xmm5,[rel aaaa]
        movaps  xmm6,[rel zzzz]
        movaps  xmm7,[rel case]
        vpcmpgtb xmm3,%1,xmm5
        vpcmpgtb xmm4,%1,xmm6
        vpandn  xmm3,xmm4,xmm3
        vpand   xmm3,xmm3,xmm7
        vpaddb  %1,%1,xmm3
        %endmacro

header  "sfind",sfind
        call    w2scratch

        ; Search for a word starting with xmm0
        vmovdqu xmm0,[CTX+_scratch]
        lower   xmm0

        _dup
        mov     TOS,[CTX + _forth]
.0:
        vmovdqu xmm1,[TOS-32]
        lower   xmm1

        vpcmpeqb xmm2,xmm1,xmm0
        vpmovmskb TMP,xmm2
        cmp     TMP,0xffff
        je      .match

        call    nextword
        jne     .0

        xor     TOS,TOS
        ret

.match:
        _nip
        _nip
        add     TOS,WORD_CODE
        _dup
        mov     eax,[TOS-WORD_CODE]
        and     eax,1   ;               0  or  1
        sal     TOS,1   ;               0  or  2
        add     TOS,-1  ;              -1 or  +1
        ret

; current word in TOS
; on return: eax is next word in dictionary, Z set if no more words
nextword:
        mov     ecx,dword [TOS]
        and     ecx,~(IMMEDIATE|INLINE)
        cmp     ecx,0
        cmove   TMP,TOS
        sub     TOS,TMP
        ret

header  "words",words
        _dup
        mov     TOS,[CTX + _forth]
.0:
        _dup
        sub     TOS,32
        call    count
        call    type
        call    space

        call    nextword
        jne     .0

        jmp     drop

header "accept",accept ; ( c-addr +n1 -- +n2 )
        call    drop
        call    dupe

.0:
        call    key
        cmp     eax,0           ;; key returns a 32-bit int, so -1 is FFFFFFFF
        jl      bye
        cmp     al,10
        je      .1
        call    over
        call    c_store
        call    one_plus
        jmp     .0
.1:
        call    drop
        call    swap
        jmp     minus

header  "refill",refill
        _dup
        mov     TOS,[CTX + _sourceid]
        call    zero_equals
        or      TOS,TOS
        je      .1

        _dup
        lea     TOS,[CTX + _tib]
        _dup
        lit     128
        call    accept
  call two_dup
  call type
  call cr
        call    source_store
        mov     CELLPTR [CTX + _in],0
.1:
        ret

; \ From Forth200x - public domain
; 
; : isspace? ( c -- f )
;     h# 21 u< ;

isspace:
        lit     0x21
        jmp     unsigned_less

; 
; : isnotspace? ( c -- f )
;     isspace? 0= ;

isnotspace:
        call    isspace
        jmp     zero_equals
; 
; : xt-skip   ( addr1 n1 xt -- addr2 n2 ) \ gforth
;     \ skip all characters satisfying xt ( c -- f )
;     >r
;     BEGIN
;         over c@ r@ execute
;         overand
;     WHILE
;         d# 1 /string
;     REPEAT
;     r> drop ;

xt_skip:
        push    LPC
        mov     LPC,TOS
        _drop
.0:
        call    over
        call    c_fetch
        call    LPC
        call    over
        call    and
        _tos0
        je      .1
        lit     1
        call    slash_string
        jmp     .0
.1:
        pop     LPC
        ret
; 
; header parse-name
; : parse-name ( "name" -- c-addr u )
;     source >in @ /string
;     ['] isspace? xt-skip over >r
;     ['] isnotspace? xt-skip ( end-word restlen r: start-word )
;     2dup d# 1 min + source drop - >in !
;     drop r> tuck -
; ;

header  "parse-name",parse_name
        push    LPC
        call    source
        call    to_in
        call    fetch
        call    slash_string
        tick    isspace
        call    xt_skip
        mov     LPC,[DSP]
        tick    isnotspace
        call    xt_skip
        call    two_dup
        lit     1
        call    min
        call    plus
        call    source
        call    drop
        call    minus
        call    to_in
        call    store
        call    drop
        _dup
        mov     TOS,LPC
        call    tuck
        call    minus
        pop     LPC
        ret

; : digit? ( c -- u f )
;    lower
;    dup h# 39 > h# 100 and +
;    dup h# 160 > h# 127 and - h# 30 -
;    dup base @i u<
; ;
isdigit:
        cmp     TOS,'A'
        jl      .1
        cmp     TOS,'Z'
        jg      .1
        add     TOS,0x20
.1:
        call    dupe
        lit     0x39
        call    greater
        lit     0x100
        call    and
        call    plus

        call    dupe
        lit     0x160
        call    greater
        lit     0x127
        call    and
        call    minus
        lit     0x30
        call    minus

        call    dupe
        call    base
        call    fetch
        jmp     unsigned_less

; : >number ( ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
;     begin
;         dup
;     while
;         over c@ digit?
;         0= if drop ; then
;         >r 2swap base @i
;         \ ud*
;         tuck * >r um* r> +
;         r> m+ 2swap
;         1/string
;     repeat
; ;
header  ">number",to_number
.0:
        or      TOS,TOS
        je      .1

        call    over
        call    c_fetch
        call    isdigit

        _tos0
        je      drop

        _to_r
        call    two_swap
        call    base
        call    fetch

        call    tuck
        call    multiply
        _to_r
        call    u_m_multiply
        _r_from
        call    plus

        _r_from

        call    m_plus
        call    two_swap

        lit     1
        call    slash_string
        jmp     .0
.1:
        ret

header  "abort",abort
        lit     'a'
        call    emit
        lit     'a'
        call    emit
        lit     'a'
        call    emit
        call    cr
        jmp     bye

        header  "postpone",postpone,IMMEDIATE
        call    parse_name
        call    sfind
        call    dupe
        call    zero_equals
        and     TOS,-13
        call    throw
        call    less_than_zero
        _tos0
        je      .1
        call    literal
        tick    compile_comma
.1:
        jmp     compile_comma

isnotdelim:
        _dup
        mov     TOS,[CTX + _scratch]
        jmp     not_equal

;;      : parse ( "ccc<char" -- c-addr u )
;;          delim !
;;          source >in @ /string
;;          over >r
;;          ['] isnotdelim xt-skip
;;          2dup d# 1 min + source drop - >in !
;;          drop r> tuck -
;;      ;

        header  "parse",parse

        mov     [CTX + _scratch],TOS
        _drop

        call    source
        call    to_in
        call    fetch
        call    slash_string

        call    over
        _to_r

        tick    isnotdelim
        call    xt_skip

        call    two_dup
        lit     1
        call    min
        call    plus
        call    source
        call    drop
        call    minus
        call    to_in
        call    store

        call    drop
        _r_from
        call    tuck
        call    minus

        ret

header  "throw",throw
        _tos0
        jne     abort
        ret

; : isvoid ( caddr u -- ) \ any char remains, abort
isvoid:
        _nip
        _tos0
        jne     abort
        ret

; : consume1 ( caddr u ch -- caddr' u' f )
;     >r over c@ r> =
;     over 0<> and
;     dup>r d# 1 and /string r>
; ;
consume1:
        _to_r
        call    over
        call    c_fetch
        _r_from
        call    equal

        call    over
        call    not_equal_zero
        call    and

        push    TOS
        lit     1
        call    and
        call    slash_string
        _r_from
        ret

doubleAlso2:
        lit     0
        _dup
        call    two_swap
        lit     '-'
        call    consume1
        _to_r
        call    to_number
        lit     '.'
        call    consume1
        _tos0
        je      .1
        call    isvoid
        _r_from
        _tos0
        je      .2pos
        call    d_negate
.2pos:
        lit     2
        ret

.1:
        call    isvoid
        call    drop
        _r_from
        _tos0
        je      .1pos
        call    negate
.1pos:
        lit     1
        ret

doubleAlso1:
        mov     TMP,[DSP]
        cmp     eax,3                   ;; Handle 'c' case
        jne     .1
        cmp     byte [TMP],"'"
        jne     .1
        cmp     byte [TMP+2],"'"
        jne     .1
        _drop2
        _dup
        movzx   TOS,byte [TMP+1]
        lit     1
        ret
.1:
        lit     "$"                     ;; hex
        call    consume1
        _tos0
        mov     TMP,16
        jne     .base
        lit     "#"                     ;; decimal
        call    consume1
        _tos0
        mov     TMP,10
        jne      .base
        lit     "%"                     ;; binary
        call    consume1
        _tos0
        mov     TMP,2
        jne      .base
        jmp     doubleAlso2

.base:
        push    CELLPTR [CTX + _base]
        mov     [CTX + _base],TMP
        call    doubleAlso1
        pop     CELLPTR [CTX + _base]
        ret

doubleAlso:
        call    doubleAlso1
        jmp     drop

doubleAlso_comma:
        call    doubleAlso1
        call    one_minus
        _tos0
        je      literal
        jmp     two_literal

interpret:
.0:
        call    parse_name
        or      TOS,TOS
        je      .1
        call    sfind

        add     TOS,[CTX + _state]

        call    one_plus
        mov     TMP,TOS
        _drop
        call    [CTX + _jumptab + CELL * TMP]
        jmp     .0
.1:     call    two_drop
        ret

;   source >r >r >in @ >r
;   source-id >r d# -1 sourceid !
;   source! d# 0 >in !
;   interpret
;   r> sourceid !
;   r> >in ! r> r> source!

header  "evaluate",evaluate
        push    CELLPTR [CTX + _sourceC]
        push    CELLPTR [CTX + _sourceC + CELL]
        push    CELLPTR [CTX + _in]
        push    CELLPTR [CTX + _sourceid]
        mov     CELLPTR [CTX + _sourceid],-1

        call    source_store
        mov     CELLPTR [CTX + _in],0
        call    interpret
        pop     CELLPTR [CTX + _sourceid]
        pop     CELLPTR [CTX + _in]
        pop     CELLPTR [CTX + _sourceC + CELL]
        pop     CELLPTR [CTX + _sourceC]
        ret

quit:
        mov     CELLPTR [CTX + _sourceid],0
        call    refill
        _tos0
        je      .1
        call    interpret
        jmp     quit

.1:
        ret

        header  "here",here
        _dup
        mov     TOS,[CTX + _dp]
        ret

        header  "dp",dp
        _dup
        lea     TOS,[CTX + _dp]
        ret

        header  "chere",chere
        _dup
        mov     TOS,[CTX + _cp]
        ret

        header  "cp",cp
        _dup
        lea     TOS,[CTX + _cp]
        ret

        header  "forth",forth
        _dup
        lea     TOS,[CTX + _forth]
        ret

        header  "state",state
        _dup
        lea     TOS,[CTX + _state]
        ret

        header  "unused",unused
        call    here
        jmp     negate

        header  "aligned",aligned
        add     TOS,(CELL-1)
        and     TOS,~(CELL-1)
        ret

        header  ",",comma
        mov     TMP,[CTX + _dp]
        mov     [TMP],TOS
        add     TMP,CELL
        mov     [CTX + _dp],TMP
        jmp     drop

        header  "c,",c_comma
        mov     TMP,[CTX + _dp]
        mov     [TMP],al
        add     TMP,1
        mov     [CTX + _dp],TMP
        jmp     drop

        header  "s,",s_comma
        push    DSP
%if (CELL == 8)
        mov     rsi,[DSP]
        mov     rdi,[CTX + _dp]
        mov     rcx,TOS
%else
        mov     esi,[DSP]
        mov     edi,[CTX + _dp]
        mov     ecx,TOS
%endif
        rep movsb
        mov     [CTX + _dp],DSP
        pop     DSP
        jmp     two_drop

;; ================ R stack           ================ 

        %macro  frag    1
        tick    frag_%1
        lit     len_%1
        call    code_s_comma
        %endmacro

frag_to_r:
        _to_r
len_to_r equ $ - frag_to_r

        header  ">r",to_r,IMMEDIATE
        frag    to_r
        ret

        header  "2>r",two_to_r,IMMEDIATE
        tick    swap
        call    compile_comma
        call    to_r
        jmp     to_r

frag_r_from:
        _r_from
len_r_from equ $ - frag_r_from

        header  "r>",r_from,IMMEDIATE
        frag    r_from
        ret

        header  "2r>",two_r_from,IMMEDIATE
        call    r_from
        call    r_from
        tick    swap
        jmp     compile_comma

frag_r_at:
        _dup
        mov     TOS,[rsp]
len_r_at equ $ - frag_r_at

        header  "r@",r_at,IMMEDIATE
        frag    r_at
        ret

        header  "2r@",two_r_at
        _dup
        mov     TOS,[rsp + CELLS(2)]
        _dup
        mov     TOS,[rsp + CELL]
        ret

;; ================ Compiling         ================ 

        header  "code.,",code_comma
        mov     TMP,[CTX + _cp]
        mov     [TMP],TOS
        add     TMP,CELL
        mov     [CTX + _cp],TMP
        jmp     drop

        header  "code.c,",code_c_comma
        mov     TMP,[CTX + _cp]
        mov     [TMP],al
        add     TMP,1
        mov     [CTX + _cp],TMP
        jmp     drop

        header  "code.s,",code_s_comma
        push    DSP
%if (CELL == 8)
        mov     rsi,[DSP]
        mov     rdi,[CTX + _cp]
        mov     rcx,TOS
%else
        mov     esi,[DSP]
        mov     edi,[CTX + _cp]
        mov     ecx,TOS
%endif
        rep movsb
        mov     [CTX + _cp],DSP
        pop     DSP
        jmp     two_drop

;   align
;   here lastword _!
;   forth @i w,
;   parse-name
;   s,
;   dp @i thisxt _!

mkheader:
        call    parse_name
        call    w2scratch
        call    two_drop

        _dup
        mov     TOS,[CTX + _cp]
        add     TOS,31
        and     TOS,~31

        vmovdqu xmm0,[CTX + _scratch]
        vmovdqa xmm1,[CTX + _scratch + 16]
        vmovdqu [TOS],xmm0
        vmovdqa [TOS + 16],xmm1

        add     TOS,32

        mov     [CTX + _lastword],TOS
        mov     TMP,TOS
        sub     TMP,[CTX + _forth]
        or      TMP,INLINE                      ;; words are inline by default
        mov     [TOS],ecx
        mov     dword [TOS+4],0                 ;; WORD_CBYTES
        add     TOS,WORD_CODE
        mov     [CTX + _thisxt],TOS
        mov     [CTX + _cp],TOS
        jmp     drop

attach:
        mov     TMP,[CTX + _lastword]
        mov     [CTX + _forth],TMP
        _dup
        mov     TOS,[CTX + _cp]
        sub     TOS,[CTX + _thisxt]
        sub     TOS,1
        mov     [TMP + WORD_CBYTES],eax
        jmp     drop

        header  ":noname",colon_noname
        ;; add     CELLPTR [CTX + _cp],15
        ;; and     CELLPTR [CTX + _cp],~15
        call    false
        call    code_comma
        call    false
        call    code_comma
        call    chere
        mov     [CTX + _thisxt],TOS
        jmp     right_bracket

        header  ":",colon
        call    mkheader
        jmp     right_bracket

        header  ";",semi_colon,IMMEDIATE
        call    exit
        call    attach
        jmp     left_bracket

        header  "exit",exit,IMMEDIATE
        mov     TMP,[CTX + _cp]
        sub     TMP,5
        cmp     TMP,[CTX + _prevcall]
        jne     .1
        mov     byte [TMP],0xe9
.1:
        lit     0xc3
        jmp     code_c_comma

        header  "immediate",immediate
        mov     TMP,[CTX + _lastword]
        or      dword [TMP],1
        ret

        header  "noinline",noinline
        mov     TMP,[CTX + _lastword]
        and     dword [TMP],~INLINE
        ret

;; CREATE makes a word that pushes a literal, followed by
;; a return.
;; DOES> works by patching the return instruction to a jump.

;; CREATERET is the offset from the word to the RET opcode
%if (CELL == 8)
%define CREATERET       (WORD_CODE + 18)
%else
%define CREATERET       (WORD_CODE + 11)
%endif

        header  "does>",does
        call    noinline
        _r_from
        mov     TMP,[CTX + _lastword]           ; points to link and LITERAL
        mov     byte [TMP + CREATERET],0xe9     ; patch to a JMP
        sub     TOS,TMP                         ;
        sub     TOS,(CREATERET + 1 + 4)
        mov     [TMP + (CREATERET + 1)],eax     ; JMP destination
        jmp     drop

        header  "[",left_bracket,IMMEDIATE
        mov     CELLPTR [CTX + _state],0
        ret

        header  "]",right_bracket
        mov     CELLPTR [CTX + _state],3
        ret

%if (CELL == 8)
frag_litCell:
        _dup
        mov     TOS,0x1234567812345678
len_litCell equ ($ - 8) - frag_litCell
%else
frag_litCell:
        _dup
        mov     TOS,0x12345678
len_litCell equ ($ - 4) - frag_litCell
%endif

        header  "literal",literal,IMMEDIATE
        frag    litCell
        jmp     code_comma

        header  "compile,",compile_comma
        mov     ecx,dword [TOS - WORD_CODE]
        test    ecx,INLINE
        je      .1
        ;; inline it
        mov     CELLPTR [CTX + _prevcall],0
        _dup
        mov     eax,dword [TOS - WORD_CBYTES]
        jmp     code_s_comma

.1:
        call    noinline
        call    chere
        mov     [CTX + _prevcall],TOS
        add     TOS,5
        call    minus

        lit     0xe8
        call    code_c_comma

l_comma:
        mov     TMP,[CTX + _cp]
        mov     [TMP],eax
        add     TMP,4
        mov     [CTX + _cp],TMP
        jmp     drop

        header  "2literal",two_literal,IMMEDIATE
        call    swap
        call    literal
        jmp     literal

;; ================ block copy        ================ 

%if (CELL == 8)
        header  "cmove",cmove
        push    DSP
        mov     rsi,[DSP+CELL]
        mov     DSP,[DSP]
        mov     rcx,TOS
        rep movsb
        pop     DSP
        _drop3
        ret

        header  "cmove>",cmove_up
        push    DSP
        mov     rsi,[DSP+CELL]
        mov     DSP,[DSP]
        mov     rcx,TOS
        lea     rsi,[rsi + rcx - 1]
        lea     DSP,[DSP + rcx - 1]
        std
        rep movsb
        cld
        pop     DSP
        _drop3
        ret

        header  "fill",fill
        push    DSP
        mov     rcx,[DSP]
        mov     DSP,[DSP+CELL]
        rep stosb
        pop     DSP
        _drop3
        ret
%else
        header  "cmove",cmove
        push    edi
        mov     esi,[DSP+CELL]
        mov     edi,[DSP]
        mov     ecx,TOS
        rep movsb
        pop     edi
        _drop3
        ret

        header  "cmove>",cmove_up
        push    edi
        mov     esi,[DSP+CELL]
        mov     edi,[DSP]
        mov     ecx,TOS
        lea     esi,[esi + ecx - 1]
        lea     edi,[edi + ecx - 1]
        std
        rep movsb
        cld
        pop     edi
        _drop3
        ret

        header  "fill",fill
        push    edi
        mov     ecx,[DSP]
        mov     edi,[DSP+CELL]
        rep stosb
        pop     edi
        _drop3
        ret
%endif

;; ================ program structure ================ 

        header  "begin",begin,IMMEDIATE
        _dup
        mov     TOS,[CTX + _cp]
        ret

        header  "ahead",ahead,IMMEDIATE
        lit     0xe9
        call    code_c_comma
        call    begin
        lit     0
        jmp     l_comma

frag_tos0:
        _tos0
len_tos0 equ $ - frag_tos0

        header  "if",if,IMMEDIATE
        frag    tos0
        lit     $0f
        call    code_c_comma
        lit     $84
        call    code_c_comma
        call    begin
        add     CELLPTR [CTX + _cp],4
        ret

        header  "then",then,IMMEDIATE
        mov     TMP,[CTX + _cp]
        sub     TMP,TOS
        sub     TMP,4
        mov     [TOS],ecx
        jmp     drop

        header  "again",again,IMMEDIATE
        lit     0xe9
        call    code_c_comma
backjmp: ;; ( dst -- ) make a backwards jump from here to dst
        mov     TMP,[CTX + _cp]
        sub     TOS,TMP
        sub     TOS,4
        mov     [TMP],eax
        add     CELLPTR [CTX + _cp],4
        jmp     drop

        header  "until",until,IMMEDIATE
        frag    tos0
        lit     $0f
        call    code_c_comma
        lit     $84
        call    code_c_comma
        jmp     backjmp

        header  "recurse",recurse,IMMEDIATE
        call    noinline
        _dup
        mov     TOS,[CTX + _thisxt]
        jmp     compile_comma

;; 
;; How DO...LOOP is implemented
;; 
;; Uses two registers:
;;    LPC is the counter; it starts negative and counts up. When it reaches 0, loop exits
;;    LPO is the offset. It is set up at loop start so that I can be computed from (LPC+LPO)
;; 
;; So when DO we have ( limit start ) on the stack so need to compute:
;;      LPC = start - limit
;;      LPO = limit
;; 
;; E.g. for "13 3 DO"
;;      LPC = -10
;;      LPO = 13
;; 
;; So the loop runs:
;;      LPC     -10 -9 -8 -7 -6 -5 -4 -3 -2 -1
;;      I         3  4  5  6  7  8  9 10 11 12
;; 
;; 

%if (CELL == 8)
        %define HIBIT $8000000000000000
%else
        %define HIBIT $80000000
%endif

frag_do:
        push    LPC
        push    LPO
        mov     LPC,TOS                 ; start
        mov     LPO,[DSP]               ; limit
        _drop2
        mov     TMP,HIBIT
        xor     LPO,TMP
        sub     LPC,LPO
len_do equ $ - frag_do

        header  "do",do,IMMEDIATE
        _dup
        mov     TOS,[CTX + _leaves]
        mov     CELLPTR [CTX + _leaves],0
        frag    do
        jmp     begin

frag_qdo:
        push    LPC
        push    LPO
        mov     LPC,TOS                 ; start
        mov     LPO,[DSP]               ; limit
        mov     TMP,HIBIT
        xor     LPO,TMP
        sub     LPC,LPO
        cmp     TOS,[DSP]
        mov     TOS,[DSP+CELL]
        lea     DSP,[DSP + CELLS(2)]
len_qdo equ $ - frag_qdo

        header  "?do",question_do,IMMEDIATE
        _dup
        mov     TOS,[CTX + _leaves]
        mov     CELLPTR [CTX + _leaves],0
        frag    qdo

        lit     0x0f
        call    code_c_comma
        lit     0x84
        call    code_c_comma
        mov     TMP,[CTX + _cp]
        mov     [CTX + _leaves],TMP
        lit     0
        call    l_comma

        jmp     begin

        header  "leave",leave,IMMEDIATE
        call    ahead
        cmp     CELLPTR [CTX + _leaves],0
        je      .1
        ;; Write [TOS - _leaves] into [TOS]
        ;; the leave chain is a chain of 32-bit relative links
        mov     TMP,TOS
        sub     TMP,[CTX + _leaves]
        mov     dword [TOS],ecx
.1:
        mov     [CTX + _leaves],TOS
        _drop
        ret

resolveleaves:
        _dup
        mov     TOS,[CTX + _leaves]
        or      TOS,TOS
        je      .2

.1:
        mov     ecx,dword [TOS]
        _dup
        push    TMP
        call    then
        pop     TMP
        
        or      ecx,ecx
        je      .2
        sub     TOS,TMP
        jmp     .1
.2:
        _drop
        mov     [CTX + _leaves],TOS
        jmp     drop

frag_loop:
        inc     LPC
len_loop equ $ - frag_loop

        header  "loop",loop,IMMEDIATE
        frag    loop
        lit     0x0f
        call    code_c_comma
        lit     0x81
        call    code_c_comma
        call    backjmp
        call    resolveleaves
        jmp     unloop

frag_plus_loop:
        mov     TMP,TOS
        _drop
        add     LPC,TMP
        jno     swapforth
len_plus_loop equ ($ - 4) - frag_plus_loop

        header  "+loop",plus_loop,IMMEDIATE
        frag    plus_loop
        call    backjmp
        call    resolveleaves
        jmp     unloop

frag_unloop:
        pop     LPO
        pop     LPC
len_unloop equ $ - frag_unloop

        header  "unloop",unloop,IMMEDIATE
        frag    unloop
        ret

frag_i:
        _dup
        mov     TOS,LPC
        add     TOS,LPO
len_i equ $ - frag_i

        header  "i",i,IMMEDIATE
        frag    i
        ret

        header  "j",j
        _dup
        mov     TOS,[rsp+CELLS(2)]
        add     TOS,[rsp+CELL]
        ret


header  "decimal",decimal
        mov     CELLPTR [CTX + _base],10
        ret

header  "dummy",dummy
L%[wnum]:

init:

%if (CELL == 8)
        push    rbx
        push    r12
        mov     CTX,rdi
        mov     [CTX + _cfuncs],rsi
%else
        push    ebx
        push    esi
        push    edi
        push    ebp

        mov     CTX,[esp + 20]
        mov     eax,[esp + 24]
        mov     [CTX + _cfuncs],eax
        mov     DSP,CTX

%endif

        call    left_bracket

        tick    dummy
        sub     TOS,WORD_CODE
        call    nextword
        mov     [CTX + _forth],TOS
        _drop

        tick    mem
        mov     [CTX + _cp],TOS
        add     TOS,512*1024
        mov     [CTX + _dp],TOS
        _drop

        call    decimal

        tick    execute
        mov     [CTX + _jumptab + CELLS(0)],TOS
        _drop

        tick    doubleAlso
        mov     [CTX + _jumptab + CELLS(1)],TOS
        _drop

        tick    execute
        mov     [CTX + _jumptab + CELLS(2)],TOS
        _drop

        tick    compile_comma
        mov     [CTX + _jumptab + CELLS(3)],TOS
        _drop

        tick    doubleAlso_comma
        mov     [CTX + _jumptab + CELLS(4)],TOS
        _drop

        tick    execute
        mov     [CTX + _jumptab + CELLS(5)],TOS
        _drop

        call    quit

%if (CELL == 8)
        pop     r12
        pop     rbx
%else
        pop     ebp
        pop     edi
        pop     esi
        pop     ebx
%endif
        ret

        align 32
mem:

global swapforth_ends
global _swapforth_ends
swapforth_ends:
_swapforth_ends:
