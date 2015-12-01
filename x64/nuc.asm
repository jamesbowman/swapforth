; SwapForth x86-64
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
;

global _swapforth
_swapforth:
        jmp     init

section .text

%define link $

%define _base     0x0
%define _forth    0x8
%define _dp       0x10
%define _lastword 0x18
%define _thisxt   0x20
%define _in       0x28
%define _sourceC  0x30
%define _state    0x40
%define _leaves   0x48
%define _tethered 0x50
%define _scratch  0x58
%define _jumptab  0x78
%define _emit     0xa8
%define _dotx     0x90
%define _key      0x98
%define _tib      0x100

%macro  header  2
        align   32
        %strlen %%count %1
        db %%count,%1
        align   32
%%link  dd   $-link
        %define link %%link
%2:
%endmacro

%macro  poprbx  0
        mov     rbx,[rdi]
        add     rdi,8
%endmacro

%macro  _dup    0
        sub     rdi,8
        mov     [rdi],rax
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
        mov     rax,0
        mov     rbx,-1
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


        extern  __dotx
        header  '.x',dotx
        push    rdi
        mov     rbp,rsp
        or      rsp,8
        sub     rsp,8
        mov     rdi,rax
        call    [r12 + _dotx]
        mov     rsp,rbp
        pop     rdi
        mov     rax,[rdi]
        add     rdi,8
        ret

        extern  __emit
        header  'emit',emit
        push    rdi
        mov     rbp,rsp
        or      rsp,8
        sub     rsp,8
        mov     rdi,rax
        call    [r12 + _emit]
        mov     rsp,rbp
        pop     rdi
        jmp     drop

        extern  __key
        header  'key',key
        _dup
        push    rdi
        mov     rbp,rsp
        or      rsp,8
        sub     rsp,8
        mov     rdi,rax
        call    [r12 + _key]
        mov     rsp,rbp
        pop     rdi
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

source_store:
        _dup
        lea     rax,[r12 + _sourceC]
        jmp     two_store

header "1+",one_plus
        inc     rax
        ret
header "1-",one_minus
        dec     rax
        ret
header "0=",zero_equals
        cmp     rax,0
        cond    e
        ret

header "cell+",cell_plus
        add     rax,8
        ret

header "cells",cells
        shl     rax,3
        ret

header "<>",not_equal
        cmp     [rdi],rax
        cond    ne
        add     rdi,8
        ret

header "=",equal
        cmp     [rdi],rax
        cond    e
        add     rdi,8
        ret

header ">",greater
        cmp     [rdi],rax
        cond    g
        add     rdi,8
        ret

header "0<",less_than_zero
        sar     rax,63
        ret

header "0>",greater_than_zero
        neg     rax
        sar     rax,63
        ret

header "0<>",not_equal_zero
        add     rax,-1
        sbb     rax,rax
        ret

header "u<",unsigned_less
        cmp     [rdi],rax
        cond    b
        add     rdi,8
        ret

header "u>",unsigned_greater
        cmp     [rdi],rax
        cond    a
        add     rdi,8
        ret

header  "+",plus
        add     rax,[rdi]
        add     rdi,8
        ret

header  "s>d",s_to_d
        _dup
        sar     rax,63
        ret

header  "m+",m_plus
        call    s_to_d
        jmp     d_plus

header  "d+",d_plus
        mov     rbx,[rdi]
        add     [rdi+16],rbx
        adc     [rdi+8],rax
        jmp     two_drop

header  "-",minus
        poprbx
        sub     rbx,rax
        mov     rax,rbx
        ret

header  "and",and
        and     rax,[rdi]
        add     rdi,8
        ret

header  "um*",u_m_multiply
        mul     qword [rdi]
        mov     [rdi],rax
        mov     rax,rdx
        ret

header  "*",multiply
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

header  "c@",c_fetch
        movzx   rax,byte [rax]
        ret

header  "c!",c_store
        mov     bl,byte [rdi]
        mov     [rax],bl
        jmp     two_drop

header  "@",fetch
        mov     rax,[rax]
        ret

header  "!",store
        mov     rbx,[rdi]
        mov     [rax],rbx
        jmp     two_drop

header  "2@",two_fetch
        mov     rbx,[rax+8]
        mov     rax,[rax]
        sub     rdi,8
        mov     [rdi],rbx
        ret

header  "2!",two_store
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

header  "swap",swap
        xchg    rax,[rdi]
        ret
        ; xxx - or is this faster?
        ; mov     rbx,[rdi]
        ; mov     [rdi],rax
        ; mov     rax,rbx
        ret

header  "over",over
        _dup
        mov     rax,[rdi+8]
        ret

header "false",false    ; : false d# 0 ;
        lit     0
        ret

header "true",true     ; : true  d# -1 ; 
        lit     -1
        ret

header "rot",rot      ; : rot   >r swap r> swap ; 
        xchg    rax,[rdi]
        xchg    rax,[rdi+8]
        ret

header "-rot",minus_rot     ; : -rot  swap >r swap r> ; 
        xchg    rax,[rdi+8]
        xchg    rax,[rdi]
        ret

header "tuck",tuck     ; : tuck  swap over ; 
        call    swap
        jmp     over

header "?dup",question_dupe     ; : ?dup  dup if dup then ;
        cmp     rax,0
        jne     dupe
        ret

header "2dup",two_dup     ; : 2dup  over over ; 
        call    over
        jmp     over

header "+!",plus_store       ; : +!    tuck @ + swap ! ; 
        poprbx
        add     [rax],rbx
        jmp     drop

header "2swap",two_swap    ; : 2swap rot >r rot r> ;
        mov     rbx,[rdi]
        xchg    rax,[rdi+8]
        xchg    rbx,[rdi+16]
        mov     [rdi],rbx
        ret

; header "2over",two_over    ; : 2over >r >r 2dup r> r> 2swap ;
        ; ret

header "min",min      ; : min   2dup< if drop else nip then ;
        poprbx
        cmp     rax,rbx
        cmovg   rax,rbx
        ret

header "max",max      ; : max   2dup< if nip else drop then ;
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

header "count",count
        inc     rax
        _dup
        movzx   rax,byte [rax-1]
        ret

header "dup",dupe
        _dup
        ret

header "drop",drop
        _drop
        ret

header  "nip",nip
        add     rdi,8
        ret

header "2drop",two_drop
        _drop
        _drop
        ret

header "execute",execute
        mov     rbx,rax
        _drop
        jmp     rbx

header "bounds",bounds ; ( a n -- a+n a )
        add     rax,[rdi]
        jmp     swap
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

header  "sfind",sfind
        mov     rbx,0x9090909090909090
        mov     [r12+_scratch],rbx
        mov     byte [r12+_scratch],al
        push    rdi
        mov     rsi,[rdi]
        lea     rdi,[r12+_scratch+1]
        mov     rcx,rax
        rep movsb
        pop     rdi

        mov     rdx,[r12+_scratch]
        ; Search for a word starting with rdx

        _dup
        lea     rax,[rel dummy - 4]
.0:
        cmp     rdx,[rax-32]
        je      .match

        mov     ebx,dword [rax]
        cmp     ebx,0
        je      .2
        sub     rax,rbx
        jmp     .0
.2:
        xor     rax,rax
        ret

.match:
        call    nip
        call    nip
        add     rax,4
        lit     -1              ; non-immediate
        ret

header  "words",words
        _dup
        lea     rax,[rel dummy - 4]
.0:
        _dup
        sub     rax,32
        call    count
        call    type
        call    space

        mov     ebx,dword [rax]
        cmp     ebx,0
        je      .2
        sub     rax,rbx
        jmp     .0
.2:
        jmp     drop

header "accept",accept ; ( c-addr +n1 -- +n2 )
        call    drop
        call    dupe

.0:
        call    key
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
        lea     rax,[rdi + _tib]
        _dup
        lit     128
        call    accept
        call    source_store
        mov     qword [r12 + _in],0
        jmp     true

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
        call    cr
        lit     'a'
        call    emit
        call    cr
        lit     'a'
        call    emit
        call    cr
.1:     jmp     .1

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
        call    to_number
        lit     '.'
        call    consume1
        _tos0
        je      .1
        call    isvoid
        lit     2
        ret

.1:
        call    isvoid
        call    drop
        lit     1
        ret

doubleAlso:
        call    doubleAlso2
        jmp     drop

header  "interpret",interpret
.0:
        call    parse_name
        or      rax,rax
        je      .1
        call    sfind

        call    one_plus
        mov     rbx,rax
        _drop
        call    [r12 + _jumptab + 8 * rbx]
        jmp     .0
.1:     call    two_drop
        ret
header  "dummy",dummy

demo:
        lit     0x3333333333333333
        lit     0x1111111111111111
        call    min
        call    dotx

        call    words
        call    cr

        call    refill
        call    drop
        call    interpret

        ; _dup
        ; lea     rax,[r12 + _tib]
        ; lit     256
        ; call    accept

        ; call    cr
        ; call    cr
        ; call    dotx
        ; _dup
        ; mov     rax,[r12 + _tib]
        ; call    dotx

        ; _dup
        ; lea     rax,[r12 + _tib]
        ; lit     5
        ; call    type

        ret

init:
        push    rbp
        push    rbx
        push    r12
        mov     r12,rdi

        mov     [r12 + _emit],rsi
        mov     [r12 + _dotx],rdx
        mov     [r12 + _key],rcx

        mov     qword [r12 + _base],10

        lea     rax,[rel execute]
        mov     [r12 + _jumptab + 0],rax

        lea     rax,[rel doubleAlso]
        mov     [r12 + _jumptab + 8],rax

        lea     rax,[rel execute]
        mov     [r12 + _jumptab + 16],rax

        call    demo

        mov     rax,rdi
        pop     r12
        pop     rbx
        pop     rbp
        ret
