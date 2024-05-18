section .text
  global main
main:
    mov rax, 10
    push rax
    mov rax, 3
    push rax
    lea rax, qword [rsp + 0]
    push rax
    mov rax, 1
    neg rax
    mov rdx, rax
    lea rcx, qword [rsp + 0]
    mov rax, qword [rcx + 0]
    mov qword [rax + 0], rdx
    lea rax, qword [rsp + 16]
    push rax
    mov rcx, qword [rsp]
    mov rax, [rcx]
    mov rdi, rax
    mov rax, 60
    syscall
