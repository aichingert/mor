section .text

global _start

_start:
    push qword 0x3
    push qword 0x2
    push qword 0x1

    mov rax, 1
    push rax
    pop rax
    mov rcx, 8
    mul rcx

    lea rcx, [rsp + 0]
    add rax, rcx
    push qword [rax]
    pop rdi 

    ;mov rax, 2
    ;mov rcx, 8
    ;mul rcx

    ;lea rdi, [rsp]
    ;add rdi, rax
    ;push qword [rdi]
    ;pop rbx

    mov rax, 60
    syscall

    ; push qword 0x1

    ; push rbp
    ; mov rbp, rsp

    ; push qword 0x31
    ; push qword 0

    ; sub rsp, 0x10
    ; mov qword [rsp + 0x10], 0x32

    ; push qword 0x32
    ; push qword 0

    ; lea rsi, [rsp + 8]

    ; mov rax, 1
    ; mov rdi, 1
    ; mov rdx, 8
    ; syscall

    ; mov rax, 60
    ; mov rdi, 0
    ; syscall

;; section .text
;; 
;; global _start
;; 
;; fib:
;;     push rbp
;;     mov rbp, rsp
;; 
;;     mov rcx, qword [rbp + 24]
;;     cmp rcx, 1
;;     jg  .compute
;;     ;; Parsing a return stmt
;;     ;; return 10;
;; 
;;     ;; Parse expression evalution
;;     push qword 1
;;     pop rax
;; 
;;     ;; Function epiloge
;;     mov [rbp + 16], rax ;; set the value 10 to the return position
;;     mov rsp, rbp        ;; ...
;;     pop rbp             ;; ...
;;     ret                 ;; ...
;;     .compute:
;; 
;;     sub rsp, 16
;;     mov rax, qword [rbp + 24]
;;     sub rax, 1
;;     mov [rsp + 8], rax
;;     mov qword [rsp], 0
;;     call fib
;;     mov rax, [rsp]
;;     mov [rbp + 16], rax
;; 
;;     mov rax, qword [rbp + 24]
;;     sub rax, 2
;;     mov [rsp + 8], rax
;;     mov qword [rsp], 0
;;     call fib
;;     mov rax, [rsp]
;;     add [rbp + 16], rax
;;     mov rcx, [rbp + 16]
;; 
;;     .return:
;;     mov rsp, rbp
;;     pop rbp
;;     ret
;; 
;; _start:
;;     push qword 5
;;     sub rsp, 8
;;     call fib
;; 
;;     pop rdi
;; 
;;     mov rax, 60
;;     syscall
