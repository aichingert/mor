section .text

global _start

_start:

    push qword 25
    push qword 1

    mov rdi, [rsp + 0x8]

    mov rax, 60
    syscall
