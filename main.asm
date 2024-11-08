section .text

global _start

_start:
    push qword 1
    mov rdi, [rsp + 8]

    mov rax, 60
    syscall
