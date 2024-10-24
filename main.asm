section .text

global _start

_start:
    mov rax, 20
    mov rcx, 30

    add rax, rcx
    mov rdi, rax

    mov rax, 60
    syscall
