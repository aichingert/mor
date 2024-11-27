section .text

global _start

_start:

    push qword 1

    cmp 10, 20
    jne
    push qword 2
if_false:
    push qword 3
both:

    mov rdi, [rsp]
    mov rax, 60
    syscall
