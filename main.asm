section .text

global _start

_start:

    push qword 1

    mov rax, 0

    cmp rax, 0
    je  if_false
    push qword 2
    jmp both
if_false:
    push qword 3
both:

    mov rdi, [rsp]
    mov rax, 60
    syscall
