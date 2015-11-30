# SwapForth x86-64

# For C code, the caller-preserved registers are: rbp, rbx, r12, r13, r14, r15
        .text

.global _swapforth
_swapforth:
        push    %rbp
        push    %rbx
        call    demo
        mov     %rdi,%rax
        pop     %rbx
        pop     %rbp
        ret

emit:
        push    %rdi
        mov     %rsp,%rbp
        or      $8,%rsp
        sub     $8,%rsp
        mov     %rax,%rdi
        call    __emit
        mov     %rbp,%rsp
        pop     %rdi
        mov     (%rdi),%rax
        add     $8,%rdi
        ret

dotx:
        push    %rdi
        mov     %rsp,%rbp
        or      $8,%rsp
        sub     $8,%rsp
        mov     %rax,%rdi
        call    __dotx
        mov     %rbp,%rsp
        pop     %rdi
        mov     (%rdi),%rax
        add     $8,%rdi
        ret

# From here, register usage is SwapForth's convention:
#
# rax   Top-of-stack
# rdi   data stack
# rsp   return stack
# rbx   context pointer
#

        .macro  _dup
        sub     $$8,%rdi
        mov     %rax,(%rdi)
        .endm

        .macro  _drop
        mov     (%rdi),%rax
        add     $$8,%rdi
        .endm

        .macro  lit v=0
        _dup
        mov     \v,%rax
        .endm

        .data
        .set    link,.
        .long   0
        .text

        # .macro  fheader  fname,immediate=0
        # .text
        # # .long   forth_link + \immediate
        # .set    forth_link,.-4
        # .string "\fname"
        # .p2align 4
        # .endm

        .data
plus:
        .long   link-.
        .set    link,.-4

demo:
        lit     $'D'
        lit     $'C'
        lit     $'B'
        lit     $'A'
        call    emit
        call    emit
        call    emit
        call    emit
        lit     $7
        call    dotx
        ret
