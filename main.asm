section .text

global _start

fib:
    push rbp
    mov rbp, rsp

    mov rcx, qword [rbp + 24]
    cmp rcx, 1
    jg  .compute
    mov qword [rbp + 16], 1
    jmp .return
    .compute:

    sub rsp, 16
    mov rax, qword [rbp + 24]
    sub rax, 1
    mov [rsp + 8], rax
    mov qword [rsp], 0
    call fib
    mov rax, [rsp]
    mov [rbp + 16], rax

    mov rax, qword [rbp + 24]
    sub rax, 2
    mov [rsp + 8], rax
    mov qword [rsp], 0
    call fib
    mov rax, [rsp]
    add [rbp + 16], rax
    mov rcx, [rbp + 16]

    .return:
    mov rsp, rbp
    pop rbp
    ret

_start:
    push qword 9
    sub rsp, 8
    call fib

    pop rdi

    mov rax, 60
    syscall
