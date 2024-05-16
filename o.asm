section .text
  global main
main:
    push 10

    ; ref = 10

    lea rsi, qword [rsp + 0]
    push rsi

    ; i64* ptr = &ref

    push qword [rsp + 8]
    push 20
    pop rbx
    pop rax
    mov qword [rax], rbx

    ; ref = 20

    push rax
    push qword [rsp + 8]

    ; ptr

    mov rax, 60
    pop rdi
    syscall
