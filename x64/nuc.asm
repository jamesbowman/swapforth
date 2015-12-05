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
        object  _in,1
        object  _jumptab,6
        object  _lastword,1
        object  _thisxt,1
        object  _sourceC,2
        object  _state,1
        object  _leaves,1
        object  _tethered,1
        object  _scratch,4
        object  _emit,1
        object  _dotx,1
        object  _key,1
        object  _tib,32

%define link $

%define IMMEDIATE       1

%macro  header  2-3     0
        align   32
        %strlen %%count %1
        db %%count,%1
        align   32
%%link  dd   $-link + %3
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

header "2*",two_times
        sal     rax,1
        ret

header "2/",two_slash
        sar     rax,1
        ret

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

header "<",less
        cmp     [rdi],rax
        cond    l
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

header  "d<",d_less
        mov     rbx,[rdi]
        sub     [rdi+16],rbx
        sbb     [rdi+8],rax
        cond    c
        add     rdi,24
        ret

header  "dnegate",d_negate
        not     rax
        not     qword [rdi]
        lit     1
        jmp     m_plus
        
header  "-",minus
        poprbx
        sub     rbx,rax
        mov     rax,rbx
        ret

header  "negate",negate
        neg     rax
        ret

header  "invert",invert
        not     rax
        ret

header  "and",and
        and     rax,[rdi]
        add     rdi,8
        ret

header  "or",or
        or      rax,[rdi]
        add     rdi,8
        ret

header  "xor",xor
        xor     rax,[rdi]
        add     rdi,8
        ret

header  "abs",_abs
        cmp     rax,0
        jl      negate
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

 header "2over",two_over
        _dup
        mov     rax,[rdi+16]
        _dup
        mov     rax,[rdi+16]
        ret

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

; ( caddr u -- caddr u )
; write a word into the scratch area with appropriate padding etc
w2scratch:
        mov     rbx,0x9090909090909090
        mov     [r12+_scratch],rbx
        mov     byte [r12+_scratch],al
        push    rdi
        mov     rsi,[rdi]
        lea     rdi,[r12+_scratch+1]
        mov     rcx,rax
        rep movsb
        pop     rdi
        ret

header  "sfind",sfind
        call    w2scratch

        mov     rdx,[r12+_scratch]
        ; Search for a word starting with rdx

        _dup
        mov     rax,[r12 + _forth]
.0:
        cmp     rdx,[rax-32]
        je      .match

        call    nextword
        jne     .0

        xor     rax,rax
        ret

.match:
        call    nip
        call    nip
        add     rax,4
        _dup
        mov     eax,[rax-4]
        and     eax,1   ;               0  or  1
        sal     rax,1   ;               0  or  2
        add     rax,-1  ;              -1 or  +1
        ret

; current word in rax
; on return: eax is next word in dictionary, Z set if no more words
nextword:
        mov     ebx,dword [rax]
        and     ebx,~1
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
        lea     rax,[r12 + _tib]
        _dup
        lit     128
        call    accept
  call two_dup
  call type
  call cr
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

doubleAlso:
        call    doubleAlso2
        jmp     drop

doubleAlso_comma:
        call    doubleAlso2
        _drop
        jmp     literal

header  "interpret",interpret
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

quit:
        call    refill
        _tos0
        je      .1
        call    interpret
        jmp     quit

.1:
        ret

        header  "[",left_bracket,IMMEDIATE
        mov     qword [r12 + _state],0
        ret

        header  "]",right_bracket
        mov     qword [r12 + _state],3
        ret

        header  "here",here
        _dup
        mov     rax,[r12 + _dp]
        ret

        header  "dp",dp
        _dup
        lea     rax,[r12 + _dp]
        ret

        header  "state",state
        _dup
        lea     rax,[r12 + _state]
        ret

        header  "unused",unused
        jmp    false

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
        mov     rdx,[r12 + _scratch]             ; is the word itself

        mov     rbx,[r12 + _dp]
        add     rbx,31
        and     rbx,~31
        mov     [rbx],rdx
        add     rbx,32

        mov     [r12 + _lastword],rbx
        mov     rdx,rbx
        sub     rdx,[r12 + _forth]
        mov     [rbx],edx
        add     rbx,4
        mov     [r12 + _thisxt],ebx
        mov     [r12 + _dp],ebx

        ret

attach:
        mov     rbx,[r12 + _lastword]
        mov     [r12 + _forth],rbx
        ret

        header  ":",colon
        call    mkheader
        jmp     right_bracket

        header  ";",semi_colon,IMMEDIATE
        lit     0xc3
        call    c_comma
        call    attach
        jmp     left_bracket

        header  "immediate",immediate
        mov     rbx,[r12 + _lastword]
        or      dword [rbx],1
        ret

        header  "does>",does
        pop     rcx                             ; return address will be branch target
        mov     rbx,[r12 + _lastword]           ; points to link and LITERAL
        mov     byte [rbx + (4 + 17)],0xe9      ; patch to a JMP
        sub     rcx,rbx                         ;
        sub     rcx,(4 + 17 + 1 + 4)
        mov     [rbx + (4 + 17 + 1)],ecx        ; JMP destination
        ret

;; ================ program structure ================ 

frag_to_r:
        _to_r
len_to_r equ $ - frag_to_r

        header  ">r",to_r,IMMEDIATE
        _dup
        lea     rax,[rel frag_to_r]
        lit     len_to_r
        jmp     s_comma

        header  "2>r",two_to_r,IMMEDIATE
        call    to_r
        jmp     to_r

frag_r_from:
        _r_from
len_r_from equ $ - frag_r_from

        header  "r>",r_from,IMMEDIATE
        _dup
        lea     rax,[rel frag_r_from]
        lit     len_r_from
        jmp     s_comma

        header  "2r>",two_r_from,IMMEDIATE
        call    r_from
        jmp     r_from

frag_r_at:
        _dup
        mov     rax,[esp]
len_r_at equ $ - frag_r_at

        header  "r@",r_at,IMMEDIATE
        _dup
        lea     rax,[rel frag_r_at]
        lit     len_r_at
        jmp     s_comma

frag_lit64:
        _dup
        mov     rax,0x1234567812345678
len_lit64 equ ($ - 8) - frag_lit64

        header  "literal",literal,IMMEDIATE
        _dup
        lea     rax,[rel frag_lit64]
        lit     len_lit64
        call    s_comma
        jmp     comma

        header  "compile,",compile_comma
        call    here
        add     rax,5
        call    minus

        lit     0xe8
        call    c_comma

l_comma:
        _dup
        call    c_comma
        sar     rax,8
        _dup
        call    c_comma
        sar     rax,8
        _dup
        call    c_comma
        sar     rax,8
        jmp     c_comma

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
        lea     rsi,[rsi + rcx - 1]
        lea     rdi,[rdi + rcx - 1]
        mov     rcx,rax
        std
        rep movsb
        cld
        pop     rdi
        _drop3
        ret

        header  "fill",fill
        push    rdi
        mov     rdi,[rdi+8]
        mov     rcx,[rdi]
        rep stosb
        pop     rdi
        _drop3
        ret

;; ================ program structure ================ 

        header  "begin",begin,IMMEDIATE
        _dup
        mov     rax,[r12 + _dp]
        ret

        header  "ahead",ahead,IMMEDIATE
        lit     0xe9
        call    c_comma
        call    begin
        add     qword [r12 + _dp],4
        ret

frag_tos0:
        _tos0
len_tos0 equ $ - frag_tos0

        header  "if",if,IMMEDIATE
        lit     frag_tos0
        lit     len_tos0
        call    s_comma
        lit     $0f
        call    c_comma
        lit     $84
        call    c_comma
        call    begin
        add     qword [r12 + _dp],4
        ret

        header  "then",then,IMMEDIATE
        mov     rbx,[r12 + _dp]
        sub     rbx,rax
        sub     rbx,4
        mov     [rax],ebx
        jmp     drop

        header  "again",again,IMMEDIATE
        lit     0xe9
        call    c_comma
resolve:
        mov     rbx,[r12 + _dp]
        sub     rax,rbx
        sub     rax,4
        mov     [rbx],eax
        add     qword [r12 + _dp],4
        jmp     drop

        header  "until",until,IMMEDIATE
        lit     frag_tos0
        lit     len_tos0
        call    s_comma
        lit     $0f
        call    c_comma
        lit     $84
        call    c_comma
        jmp     resolve

        header  "recurse",recurse,IMMEDIATE
        _dup
        mov     rax,[r12 + _thisxt]
        jmp     compile_comma

header  "dummy",dummy

init:
        push    rbp
        push    rbx
        push    r12
        mov     r12,rdi

        call    left_bracket

        mov     [r12 + _emit],rsi
        mov     [r12 + _dotx],rdx
        mov     [r12 + _key],rcx

        lea     rax,[rel dummy - 4]
        mov     [r12 + _forth],rax

        lea     rax,[rel mem]
        mov     [r12 + _dp],rax

        mov     qword [r12 + _base],10

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
        align   65536
