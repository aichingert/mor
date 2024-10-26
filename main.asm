section .text

global _start

fn:
    mov rax, 10
    mov rdi, 20
    add rdi, rax
    ret

_start:
    call fn

    mov rax, 60
    syscall
