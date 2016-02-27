;
; For C code, the caller-preserved registers are: rbp, rbx, r12, r13, r14, r15
;
; Arguments are passed in: rdi, rsi, rdx, rcx, r8, r9
;
; In SwapForth usage is:
;
; rax   Top-of-stack
; rdi   data stack pointer
; rsp   return stack pointer
; r12   context pointer
; r13   loop counter
; r14   loop offset
; r15   constant 0
;

CFUNC_DOTX      equ     0       ;; This table matches CFUNCS in main.c
CFUNC_BYE       equ     8
CFUNC_EMIT      equ     16
CFUNC_KEY       equ     24

%define WORD_NAME       -32     ;; word name as a counted string
%define WORD_LINK       0       ;; relative link to prev word
%define WORD_CBYTES     4       ;; code size in bytes, for inlining
%define WORD_CODE       8       ;; start of native code

section .text

global swapforth
swapforth:
global _swapforth
_swapforth:
        jmp     init

%define ao 0
%macro object   2
%1      equ     ao
%%n     equ     ao+(8*%2)
        %define ao %%n
%endmacro

        object  _base,1
        object  _forth,1
        object  _dp,1
        object  _cp,1
        object  _in,1
        object  _jumptab,6
        object  _prevcall,1
        object  _lastword,1
        object  _thisxt,1
        object  _sourceid,1
        object  _sourceC,2
        object  _state,1
        object  _leaves,1
        object  _tethered,1
        object  _scratch,4
        object  _cfuncs,1
        object  _tib,32

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

%macro  poprbx  0
        mov     rbx,[rdi]
        add     rdi,8
%endmacro

%macro  _dup    0
        mov     [rdi-8],rax
        sub     rdi,8
%endmacro

%macro  _drop   0
        mov     rax,[rdi]
        add     rdi,8
%endmacro

%macro  _drop2   0
        mov     rax,[rdi+8]
        add     rdi,16
%endmacro

%macro  _drop3   0
        mov     rax,[rdi+16]
        add     rdi,24
%endmacro

%macro  _tos0   0
        or      rax,rax
        mov     rax,[rdi]
        lea     rdi,[rdi+8]
%endmacro

%macro  lit     1
        _dup
        mov     rax,%1
%endmacro

%macro  cond    1
        mov     rax,r15
        lea     rbx,[r15-1]
        cmov%1  rax,rbx
%endmacro

%macro  _to_r   0
        push    rax
        _drop
%endmacro

%macro  _r_from 0
        _dup
        pop     rax
%endmacro


        ;; C interface macro, parameter is offset into CTABLE

        %macro  c_pre   1
        push    rdi     ;; Our data stack pointer, C clobbers
        mov     rbp,rsp ;; Save the SP
        or      rsp,8   ;; Now align SP, C needs this
        sub     rsp,8
        mov     rdi,rax ;; Always pass TOS as argument
        mov     rax,[r12 + _cfuncs]
        call    [rax + %1]
        mov     rsp,rbp ;; restore our SP
        pop     rdi     ;; restore our data stack pointer
        %endmacro

        header  '.x',dotx       ; ( x -- )
        c_pre   CFUNC_DOTX
        mov     rax,[rdi]
        add     rdi,8
        ret

        header  'bye',bye
        c_pre   CFUNC_BYE       ;; never returns

        header  'emit',emit     ; ( x -- )
        c_pre   CFUNC_EMIT
        jmp     drop

        header  'key',key       ;; ( -- x )
        _dup
        c_pre   CFUNC_KEY
        ret

header  "depth",depth
        mov     rbx,r12
        sub     rbx,rdi
        _dup
        mov     rax,rbx
        sar     rax,3
        ret

header  "base",base
        _dup
        lea     rax,[r12 + _base]
        ret

header  ">in",to_in
        _dup
        lea     rax,[r12 + _in]
        ret

header  "source",source
        _dup
        lea     rax,[r12 + _sourceC]
        jmp     two_fetch

header  "source-id",source_id
        _dup
        mov     rax,[r12 + _sourceid]
        ret

source_store:
        _dup
        lea     rax,[r12 + _sourceC]
        jmp     two_store

header "2*",two_times,INLINE
        sal     rax,1
        ret

header "2/",two_slash,INLINE
        sar     rax,1
        ret

header "1+",one_plus,INLINE
        inc     rax
        ret

header "1-",one_minus,INLINE
        dec     rax
        ret

header "0=",zero_equals,INLINE
        cmp     rax,r15
        cond    e
        ret

header "cell+",cell_plus,INLINE
        add     rax,8
        ret

header "cells",cells,INLINE
        shl     rax,3
        ret

header "<>",not_equal,INLINE
        cmp     [rdi],rax
        cond    ne
        add     rdi,8
        ret

header "=",equal,INLINE
        cmp     [rdi],rax
        cond    e
        add     rdi,8
        ret

header ">",greater,INLINE
        cmp     [rdi],rax
        cond    g
        add     rdi,8
        ret

header "<",less,INLINE
        cmp     [rdi],rax
        cond    l
        add     rdi,8
        ret

header "0<",less_than_zero,INLINE
        sar     rax,63
        ret

header "0>",greater_than_zero,INLINE
        cmp     rax,r15
        cond    g
        ret

header "0<>",not_equal_zero,INLINE
        add     rax,-1
        sbb     rax,rax
        ret

header "u<",unsigned_less,INLINE
        cmp     [rdi],rax
        cond    b
        add     rdi,8
        ret

header "u>",unsigned_greater,INLINE
        cmp     [rdi],rax
        cond    a
        add     rdi,8
        ret

header  "+",plus,INLINE
        add     rax,[rdi]
        add     rdi,8
        ret

header  "s>d",s_to_d,INLINE
        _dup
        sar     rax,63
        ret

header  "d>s",d_to_s,INLINE
        _drop
        ret

header  "m+",m_plus
        call    s_to_d
        jmp     d_plus

header  "d+",d_plus
        mov     rbx,[rdi]
        add     [rdi+16],rbx
        adc     [rdi+8],rax
        _drop2
        ret

header  "d=",d_equal
        cmp     [rdi+8],rax
        jne     .1
        mov     rbx,[rdi+16]
        cmp     rbx,[rdi]
.1:
        cond    e
        add     rdi,24
        ret

header  "du<",d_u_less
        cmp     [rdi+8],rax
        jne     .1
        mov     rbx,[rdi+16]
        cmp     rbx,[rdi]
.1:
        cond    b
        add     rdi,24
        ret

header  "d<",d_less
        cmp     [rdi+8],rax
        jne     .1
        mov     rbx,[rdi+16]
        cmp     rbx,[rdi]
        cond    b
        add     rdi,24
        ret
.1:
        cond    l
        add     rdi,24
        ret

header  "d0<",d_less_than_zero
        call    nip
        jmp     less_than_zero

header  "dnegate",d_negate
        not     rax
        not     qword [rdi]
        lit     1
        jmp     m_plus

header  "d-",d_minus
        mov     rbx,[rdi]
        sub     [rdi+16],rbx
        sbb     [rdi+8],rax
        jmp     two_drop

header  "d2*",d_two_times,INLINE
        shl     qword [rdi],1
        adc     rax,rax
        ret

header  "d2/",d_two_slash,INLINE
        sar     rax,1
        rcr     qword [rdi],1
        ret

header  "-",minus,INLINE
        poprbx
        sub     rbx,rax
        mov     rax,rbx
        ret

header  "negate",negate,INLINE
        neg     rax
        ret

header  "invert",invert,INLINE
        not     rax
        ret

header  "and",and,INLINE
        and     rax,[rdi]
        add     rdi,8
        ret

header  "or",or,INLINE
        or      rax,[rdi]
        add     rdi,8
        ret

header  "xor",xor,INLINE
        xor     rax,[rdi]
        add     rdi,8
        ret

header  "lshift",lshift,INLINE
        mov     rcx,rax
        mov     rax,[rdi]
        shl     rax,cl
        add     rdi,8
        ret

header  "rshift",rshift,INLINE
        mov     rcx,rax
        mov     rax,[rdi]
        shr     rax,cl
        add     rdi,8
        ret

header  "abs",_abs,INLINE
        mov     rbx,rax
        sar     rbx,63
        xor     rax,rbx
        sub     rax,rbx
        ret

header  "um*",u_m_multiply,INLINE
        mul     qword [rdi]
        mov     [rdi],rax
        mov     rax,rdx
        ret

header  "*",multiply,INLINE
        imul    rax,[rdi]
        add     rdi,8
        ret

header  "/",divide
        mov     rbx,rax
        mov     rax,[rdi]
        cqo
        idiv    rbx
        add     rdi,8
        ret

header  "mod",mod
        mov     rbx,rax
        mov     rax,[rdi]
        cqo
        idiv    rbx
        mov     rax,rdx
        add     rdi,8
        ret

header  "um/mod",u_m_slash_mod
        mov     rbx,rax
        mov     rdx,[rdi]
        mov     rax,[rdi+8]
        div     rbx
        mov     [rdi+8],rdx
        call    nip
        ret

header  "c@",c_fetch,INLINE
        movzx   rax,byte [rax]
        ret

header  "c!",c_store,INLINE
        mov     bl,byte [rdi]
        mov     [rax],bl
        _drop2
        ret

header  "@",fetch,INLINE
        mov     rax,[rax]
        ret

header  "!",store,INLINE
        mov     rbx,[rdi]
        mov     [rax],rbx
        _drop2
        ret

header  "ul@",u_l_fetch,INLINE
        mov     eax,dword [rax]
        ret

header  "sl@",s_l_fetch,INLINE
        movsx   rax,dword [rax]
        ret

header  "2@",two_fetch,INLINE
        mov     rbx,[rax+8]
        mov     rax,[rax]
        sub     rdi,8
        mov     [rdi],rbx
        ret

header  "2!",two_store,INLINE
        mov     rbx,[rdi]
        mov     [rax],rbx
        mov     rbx,[rdi+8]
        mov     [rax+8],rbx
        _drop3
        ret

header  "/string",slash_string
        mov     rbx,rax
        _drop
        sub     rax,rbx
        add     [rdi],rbx
        ret

header  "swap",swap,INLINE
        mov     rbx,[rdi]
        mov     [rdi],rax
        mov     rax,rbx
        ret

header  "over",over,INLINE
        _dup
        mov     rax,[rdi+8]
        ret

header "false",false,INLINE
        _dup
        xor     rax,rax
        ret

header "true",true,INLINE
        _dup
        lea     rax,[r15-1]
        ret

header "bl",_bl,INLINE
        lit     32
        ret

header "rot",rot,INLINE
        xchg    rax,[rdi]
        xchg    rax,[rdi+8]
        ret

header "noop",noop
        ret

header "-rot",minus_rot,INLINE
        xchg    rax,[rdi+8]
        xchg    rax,[rdi]
        ret

header "tuck",tuck     ; : tuck  swap over ; 
        call    swap
        jmp     over

header "?dup",question_dupe     ; : ?dup  dup if dup then ;
        cmp     rax,r15
        jne     dupe
        ret

header "2dup",two_dup,INLINE     ; : 2dup  over over ; 
        _dup
        mov     rax,[rdi+8]
        _dup
        mov     rax,[rdi+8]
        ret

header "+!",plus_store,INLINE       ; : +!    tuck @ + swap ! ; 
        mov     rbx,[rdi]
        add     [rax],rbx
        _drop2
        ret

header "2swap",two_swap,INLINE    ; : 2swap rot >r rot r> ;
        mov     rbx,[rdi]
        xchg    rax,[rdi+8]
        xchg    rbx,[rdi+16]
        mov     [rdi],rbx
        ret

 header "2over",two_over,INLINE
        _dup
        mov     rax,[rdi+24]
        _dup
        mov     rax,[rdi+24]
        ret

header "min",min,INLINE      ; : min   2dup< if drop else nip then ;
        poprbx
        cmp     rax,rbx
        cmovg   rax,rbx
        ret

header "max",max,INLINE      ; : max   2dup< if nip else drop then ;
        poprbx
        cmp     rax,rbx
        cmovl   rax,rbx
        ret

header  "space",space
        lit     ' '
        jmp     emit

header  "cr",cr
        lit     10
        jmp     emit

header "count",count,INLINE
        inc     rax
        _dup
        movzx   rax,byte [rax-1]
        ret

header "dup",dupe,INLINE
        _dup
        ret

header "drop",drop,INLINE
        _drop
        ret

header  "nip",nip,INLINE
        add     rdi,8
        ret

header "2drop",two_drop,INLINE
        _drop2
        ret

header "execute",execute
        mov     rbx,rax
        _drop
        jmp     rbx

header "bounds",bounds,INLINE ; ( a n -- a+n a )
        mov     rbx,[rdi]
        add     rax,rbx
        mov     [rdi],rax
        mov     rax,rbx
        ret

header "type",type
        call    bounds
.0:
        cmp     rax,[rdi]
        je      .2
        _dup
        movzx   rax,byte [rax]
        call    emit
        inc     rax
        jmp     .0
.2:     jmp     two_drop

; ( caddr u -- caddr u )
; write a word into the scratch area with appropriate padding etc
w2scratch:
        mov     rbx,0x9090909090909090
        mov     [r12+_scratch],rbx
        mov     [r12+_scratch + 8],rbx
        mov     byte [r12+_scratch],al
        push    rdi
        mov     rsi,[rdi]
        lea     rdi,[r12+_scratch+1]
        mov     rcx,rax
        rep movsb
        pop     rdi
        ret

        align   32
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

        mov     rdx,[r12+_scratch]
        ; Search for a word starting with rdx
        vmovdqu xmm0,[r12+_scratch]
        lower   xmm0

        _dup
        mov     rax,[r12 + _forth]
.0:
        vmovdqu xmm1,[rax-32]
        lower   xmm1

        vpcmpeqb xmm2,xmm1,xmm0
        vpmovmskb rcx,xmm2
        cmp     rcx,0xffff
        je      .match

        call    nextword
        jne     .0

        xor     rax,rax
        ret

.match:
        call    nip
        call    nip
        add     rax,WORD_CODE
        _dup
        mov     eax,[rax-WORD_CODE]
        and     eax,1   ;               0  or  1
        sal     rax,1   ;               0  or  2
        add     rax,-1  ;              -1 or  +1
        ret

; current word in rax
; on return: eax is next word in dictionary, Z set if no more words
nextword:
        mov     ebx,dword [rax]
        and     ebx,~(IMMEDIATE|INLINE)
        cmp     ebx,0
        cmove   rbx,rax
        sub     rax,rbx
        ret

header  "words",words
        _dup
        mov     rax,[r12 + _forth]
.0:
        _dup
        sub     rax,32
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
        mov     rax,[r12 + _sourceid]
        call    zero_equals
        or      rax,rax
        je      .1

        _dup
        lea     rax,[r12 + _tib]
        _dup
        lit     128
        call    accept
  ;; call two_dup
  ;; call type
  ;; call cr
        call    source_store
        mov     qword [r12 + _in],0
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
        push    r13
        mov     r13,rax
        _drop
.0:
        call    over
        call    c_fetch
        call    r13
        call    over
        call    and
        _tos0
        je      .1
        lit     1
        call    slash_string
        jmp     .0
.1:
        pop     r13
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
%macro  tick    1
        _dup
        lea     rax,[rel %1]
%endmacro

header  "parse-name",parse_name
        push    r13
        call    source
        call    to_in
        call    fetch
        call    slash_string
        tick    isspace
        call    xt_skip
        mov     r13,[rdi]
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
        mov     rax,r13
        call    tuck
        call    minus
        pop     r13
        ret

; : digit? ( c -- u f )
;    lower
;    dup h# 39 > h# 100 and +
;    dup h# 160 > h# 127 and - h# 30 -
;    dup base @i u<
; ;
isdigit:
        cmp     rax,'A'
        jl      .1
        cmp     rax,'Z'
        jg      .1
        add     rax,0x20
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
        or      rax,rax
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
        and     rax,-13
        call    throw
        call    less_than_zero
        _tos0
        je      .1
        call    literal
        _dup
        lea     rax,[rel compile_comma]
.1:
        jmp     compile_comma

isnotdelim:
        _dup
        mov     rax,[r12 + _scratch]
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

        mov     [r12 + _scratch],rax
        _drop

        call    source
        call    to_in
        call    fetch
        call    slash_string

        call    over
        _to_r

        _dup
        lea     rax,[rel isnotdelim]
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
        call    nip
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

        push    rax
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
        mov     rbx,[rdi]
        cmp     eax,3                   ;; Handle 'c' case
        jne     .1
        cmp     byte [rbx],"'"
        jne     .1
        cmp     byte [rbx+2],"'"
        jne     .1
        _drop2
        _dup
        movzx   rax,byte [rbx+1]
        lit     1
        ret
.1:
        lit     "$"
        call    consume1
        _tos0
        mov     rbx,16
        jne     .base
        lit     "#"
        call    consume1
        _tos0
        mov     rbx,10
        jne      .base
        lit     "%"
        call    consume1
        _tos0
        mov     rbx,2
        jne      .base
        jmp     doubleAlso2

.base:
        push    qword [r12 + _base]
        mov     [r12 + _base],rbx
        call    doubleAlso1
        pop     qword [r12 + _base]
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
        or      rax,rax
        je      .1
        call    sfind

        add     rax,[r12 + _state]

        call    one_plus
        mov     rbx,rax
        _drop
        call    [r12 + _jumptab + 8 * rbx]
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
        push    qword [r12 + _sourceC]
        push    qword [r12 + _sourceC + 8]
        push    qword [r12 + _in]
        push    qword [r12 + _sourceid]
        mov     qword [r12 + _sourceid],-1

        call    source_store
        mov     qword [r12 + _in],0
        call    interpret
        pop     qword [r12 + _sourceid]
        pop     qword [r12 + _in]
        pop     qword [r12 + _sourceC + 8]
        pop     qword [r12 + _sourceC]
        ret

quit:
        mov     qword [r12 + _sourceid],0
        call    refill
        _tos0
        je      .1
        call    interpret
        jmp     quit

.1:
        ret

        header  "here",here
        _dup
        mov     rax,[r12 + _dp]
        ret

        header  "dp",dp
        _dup
        lea     rax,[r12 + _dp]
        ret

        header  "chere",chere
        _dup
        mov     rax,[r12 + _cp]
        ret

        header  "cp",cp
        _dup
        lea     rax,[r12 + _cp]
        ret

        header  "forth",forth
        _dup
        lea     rax,[r12 + _forth]
        ret

        header  "state",state
        _dup
        lea     rax,[r12 + _state]
        ret

        header  "unused",unused
        call    here
        jmp     negate

        header  "aligned",aligned
        add     rax,7
        and     rax,~7
        ret

        header  ",",comma
        mov     rbx,[r12 + _dp]
        mov     [rbx],rax
        add     rbx,8
        mov     [r12 + _dp],rbx
        jmp     drop

        header  "c,",c_comma
        mov     rbx,[r12 + _dp]
        mov     [rbx],al
        add     rbx,1
        mov     [r12 + _dp],rbx
        jmp     drop

        header  "s,",s_comma
        push    rdi
        mov     rsi,[rdi]
        mov     rdi,[r12 + _dp]
        mov     rcx,rax
        rep movsb
        mov     [r12 + _dp],rdi
        pop     rdi
        jmp     two_drop

;; ================ R stack           ================ 

        %macro  frag    1
        _dup
        lea     rax,[rel frag_%1]
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
        _dup
        lea     rax,[rel swap]
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
        _dup
        lea     rax,[rel swap]
        jmp     compile_comma

frag_r_at:
        _dup
        mov     rax,[rsp]
len_r_at equ $ - frag_r_at

        header  "r@",r_at,IMMEDIATE
        frag    r_at
        ret

        header  "2r@",two_r_at
        _dup
        mov     rax,[rsp + 16]
        _dup
        mov     rax,[rsp + 8]
        ret

;; ================ Compiling         ================ 

        header  "code.,",code_comma
        mov     rbx,[r12 + _cp]
        mov     [rbx],rax
        add     rbx,8
        mov     [r12 + _cp],rbx
        jmp     drop

        header  "code.c,",code_c_comma
        mov     rbx,[r12 + _cp]
        mov     [rbx],al
        add     rbx,1
        mov     [r12 + _cp],rbx
        jmp     drop

        header  "code.s,",code_s_comma
        push    rdi
        mov     rsi,[rdi]
        mov     rdi,[r12 + _cp]
        mov     rcx,rax
        rep movsb
        mov     [r12 + _cp],rdi
        pop     rdi
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

        mov     rbx,[r12 + _cp]
        add     rbx,31
        and     rbx,~31
        mov     rdx,[r12 + _scratch]             ; is the word itself
        mov     [rbx],rdx
        mov     rdx,[r12 + _scratch + 8]
        mov     [rbx + 8],rdx
        mov     rdx,[r12 + _scratch + 16]
        mov     [rbx + 16],rdx
        mov     rdx,[r12 + _scratch + 24]
        mov     [rbx + 24],rdx
        add     rbx,32

        mov     [r12 + _lastword],rbx
        mov     rdx,rbx
        sub     rdx,[r12 + _forth]
        or      rdx,INLINE                      ;; words are inline by default
        mov     [rbx],edx
        mov     dword [rbx+4],0                 ;; WORD_CBYTES
        add     rbx,WORD_CODE
        mov     [r12 + _thisxt],rbx
        mov     [r12 + _cp],rbx
        ret

attach:
        mov     rbx,[r12 + _lastword]
        mov     [r12 + _forth],rbx
        mov     rcx,[r12 + _cp]
        sub     rcx,[r12 + _thisxt]
        sub     rcx,1
        mov     [rbx + WORD_CBYTES],ecx
        ret

        header  ":noname",colon_noname
        add     qword [r12 + _cp],15
        and     qword [r12 + _cp],~15
        call    chere
        mov     [r12 + _thisxt],rax
        jmp     right_bracket

        header  ":",colon
        call    mkheader
        jmp     right_bracket

        header  ";",semi_colon,IMMEDIATE
        call    exit
        call    attach
        jmp     left_bracket

        header  "exit",exit,IMMEDIATE
        mov     rbx,[r12 + _cp]
        sub     rbx,5
        cmp     rbx,[r12 + _prevcall]
        jne     .1
        mov     byte [rbx],0xe9
.1:
        lit     0xc3
        jmp     code_c_comma

        header  "immediate",immediate
        mov     rbx,[r12 + _lastword]
        or      dword [rbx],1
        ret

        header  "noinline",noinline
        mov     rbx,[r12 + _lastword]
        and     dword [rbx],~INLINE
        ret

;; CREATE makes a word that pushes a literal, followed by
;; a return.
;; DOES> works by patching the return instruction to a jump.

;; CREATERET is the offset from the word to the RET opcode
%define CREATERET       (WORD_CODE + 18)

        header  "does>",does
        call    noinline
        pop     rcx                             ; return address will be branch target
        mov     rbx,[r12 + _lastword]           ; points to link and LITERAL
        mov     byte [rbx + CREATERET],0xe9     ; patch to a JMP
        sub     rcx,rbx                         ;
        sub     rcx,(CREATERET + 1 + 4)
        mov     [rbx + (CREATERET + 1)],ecx     ; JMP destination
        ret

        header  "[",left_bracket,IMMEDIATE
        mov     qword [r12 + _state],0
        ret

        header  "]",right_bracket
        mov     qword [r12 + _state],3
        ret

frag_lit64:
        _dup
        mov     rax,0x1234567812345678
len_lit64 equ ($ - 8) - frag_lit64

        header  "literal",literal,IMMEDIATE
        mov     rbx,0x100000000
        cmp     rax,rbx
        frag    lit64
        jmp     code_comma

        header  "compile,",compile_comma
        mov     ebx,dword [rax - WORD_CODE]
        test    ebx,INLINE
        je      .1
        ;; inline it
        mov     qword [r12 + _prevcall],0
        _dup
        mov     eax,dword [rax - WORD_CBYTES]
        jmp     code_s_comma

.1:
        call    noinline
        call    chere
        mov     [r12 + _prevcall],rax
        add     rax,5
        call    minus

        lit     0xe8
        call    code_c_comma

l_comma:
        mov     rbx,[r12 + _cp]
        mov     [rbx],eax
        add     rbx,4
        mov     [r12 + _cp],rbx
        jmp     drop

        header  "2literal",two_literal,IMMEDIATE
        call    swap
        call    literal
        jmp     literal

;; ================ block copy        ================ 

        header  "cmove",cmove
        push    rdi
        mov     rsi,[rdi+8]
        mov     rdi,[rdi]
        mov     rcx,rax
        rep movsb
        pop     rdi
        _drop3
        ret

        header  "cmove>",cmove_up
        push    rdi
        mov     rsi,[rdi+8]
        mov     rdi,[rdi]
        mov     rcx,rax
        lea     rsi,[rsi + rcx - 1]
        lea     rdi,[rdi + rcx - 1]
        std
        rep movsb
        cld
        pop     rdi
        _drop3
        ret

        header  "fill",fill
        push    rdi
        mov     rcx,[rdi]
        mov     rdi,[rdi+8]
        rep stosb
        pop     rdi
        _drop3
        ret

;; ================ program structure ================ 

        header  "begin",begin,IMMEDIATE
        _dup
        mov     rax,[r12 + _cp]
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
        add     qword [r12 + _cp],4
        ret

        header  "then",then,IMMEDIATE
        mov     rbx,[r12 + _cp]
        sub     rbx,rax
        sub     rbx,4
        mov     [rax],ebx
        jmp     drop

        header  "again",again,IMMEDIATE
        lit     0xe9
        call    code_c_comma
backjmp: ;; ( dst -- ) make a backwards jump from here to dst
        mov     rbx,[r12 + _cp]
        sub     rax,rbx
        sub     rax,4
        mov     [rbx],eax
        add     qword [r12 + _cp],4
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
        mov     rax,[r12 + _thisxt]
        jmp     compile_comma

;; 
;; How DO...LOOP is implemented
;; 
;; Uses two registers:
;;    r13 is the counter; it starts negative and counts up. When it reaches 0, loop exits
;;    r14 is the offset. It is set up at loop start so that I can be computed from (r13+r14)
;; 
;; So when DO we have ( limit start ) on the stack so need to compute:
;;      r13 = start - limit
;;      r14 = limit
;; 
;; E.g. for "13 3 DO"
;;      r13 = -10
;;      r14 = 13
;; 
;; So the loop runs:
;;      r13     -10 -9 -8 -7 -6 -5 -4 -3 -2 -1
;;      I         3  4  5  6  7  8  9 10 11 12
;; 
;; 

frag_do:
        push    r13
        push    r14
        mov     r13,rax                 ; start
        mov     r14,[rdi]               ; limit
        _drop2
        mov     rbx,$8000000000000000
        xor     r14,rbx
        sub     r13,r14
len_do equ $ - frag_do

        header  "do",do,IMMEDIATE
        _dup
        mov     rax,[r12 + _leaves]
        mov     qword [r12 + _leaves],0
        frag    do
        jmp     begin

frag_qdo:
        push    r13
        push    r14
        mov     r13,rax                 ; start
        mov     r14,[rdi]               ; limit
        mov     rbx,$8000000000000000
        xor     r14,rbx
        sub     r13,r14
        cmp     rax,[rdi]
        mov     rax,[rdi+8]
        lea     rdi,[rdi + 16]
len_qdo equ $ - frag_qdo

        header  "?do",question_do,IMMEDIATE
        _dup
        mov     rax,[r12 + _leaves]
        mov     qword [r12 + _leaves],0
        frag    qdo

        lit     0x0f
        call    code_c_comma
        lit     0x84
        call    code_c_comma
        mov     rbx,[r12 + _cp]
        mov     [r12 + _leaves],rbx
        lit     0
        call    l_comma

        jmp     begin

        header  "leave",leave,IMMEDIATE
        call    ahead
        cmp     qword [r12 + _leaves],0
        je      .1
        ;; Write [rax - _leaves] into [rax]
        ;; the leave chain is a chain of 32-bit relative links
        mov     rbx,rax
        sub     rbx,[r12 + _leaves]
        mov     dword [rax],ebx
.1:
        mov     [r12 + _leaves],rax
        _drop
        ret

resolveleaves:
        _dup
        mov     rax,[r12 + _leaves]
        or      rax,rax
        je      .2

.1:
        mov     ecx,dword [rax]
        _dup
        call    then
        
        or      ecx,ecx
        je      .2
        sub     rax,rcx
        jmp     .1
.2:
        _drop
        mov     [r12 + _leaves],rax
        jmp     drop

frag_loop:
        inc     r13
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
        mov     rbx,rax
        _drop
        add     r13,rbx
        jno     swapforth
len_plus_loop equ ($ - 4) - frag_plus_loop

        header  "+loop",plus_loop,IMMEDIATE
        frag    plus_loop
        call    backjmp
        call    resolveleaves
        jmp     unloop

frag_unloop:
        pop     r14
        pop     r13
len_unloop equ $ - frag_unloop

        header  "unloop",unloop,IMMEDIATE
        frag    unloop
        ret

frag_i:
        _dup
        mov     rax,r13
        add     rax,r14
len_i equ $ - frag_i

        header  "i",i,IMMEDIATE
        frag    i
        ret

        header  "j",j
        _dup
        mov     rax,[rsp+16]
        add     rax,[rsp+8]
        ret


header  "decimal",decimal
        mov     qword [r12 + _base],10
        ret

header  "dummy",dummy
L%[wnum]:

init:
        push    rbp
        push    rbx
        push    r12

        mov     r15,0
        mov     r12,rdi

        call    left_bracket

        mov     [r12 + _cfuncs],rsi

        lea     rax,[rel dummy - WORD_CODE]
        call    nextword
        mov     [r12 + _forth],rax

        lea     rax,[rel mem]
        mov     [r12 + _cp],rax
        add     rax,512*1024
        mov     [r12 + _dp],rax

        call    decimal

        lea     rax,[rel execute]
        mov     [r12 + _jumptab + 0],rax

        lea     rax,[rel doubleAlso]
        mov     [r12 + _jumptab + 8],rax

        lea     rax,[rel execute]
        mov     [r12 + _jumptab + 16],rax

        lea     rax,[rel compile_comma]
        mov     [r12 + _jumptab + 24],rax

        lea     rax,[rel doubleAlso_comma]
        mov     [r12 + _jumptab + 32],rax

        lea     rax,[rel execute]
        mov     [r12 + _jumptab + 40],rax

        call    quit

        mov     rax,rdi
        pop     r12
        pop     rbx
        pop     rbp
        ret

        align 32
mem:
global swapforth_ends
swapforth_ends:
global _swapforth_ends
_swapforth_ends:
