section .text

global _start

_start:
    push 20
    push 40

    mov rdi, [rsp + 8]

    mov rax, 60
    syscall
