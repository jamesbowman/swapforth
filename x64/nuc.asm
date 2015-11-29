; SwapForth x86-64
;
; For C code, the caller-preserved registers are: rbp, rbx, r12, r13, r14, r15
;
; Arguments are passed in: rdi, rsi, rdx, rcx, r8, r9

section .text

%define link $

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

%macro  lit     1
        _dup
        mov     rax,%1
%endmacro

%macro  cond    1
        mov     rax,0
        mov     rbx,-1
        cmov%1  rax,rbx
%endmacro

        extern  __dotx
        header  '.x',dotx
        push    rdi
        mov     rbp,rsp
        or      rsp,8
        sub     rsp,8
        mov     rdi,rax
        call    __dotx
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
        call    __emit
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
        call    __key
        mov     rsp,rbp
        pop     rdi
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
        cmp     [rdi],rax
        cond    ne
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

header  "-",minus
        poprbx
        sub     rbx,rax
        mov     rax,rbx
        ret

header  "c!",c_store
        mov     bl,byte [rdi]
        mov     [rax],bl
        jmp     two_drop

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
        mov     rax,[rbx+8]
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
        cmp     rax,'\n'
        jmp     .1
        call    over
        call    c_store
        call    one_plus
        jmp     .0
.1:
        call    drop
        call    swap
        jmp     minus

header  "dummy",dummy

demo:
        lit     0x3333333333333333
        lit     0x1111111111111111
        call    min
        call    dotx

        call    words

        call    key
        call    dotx
        ret

global _swapforth
_swapforth:
        push    rbp
        push    rbx
        call    demo
        mov     rax,rdi
        pop     rbx
        pop     rbp
        ret
