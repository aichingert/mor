section .text

global _start

_start:
    mov rax, 3
    mov rbx, 5

    div rbx

    mov rdi, rax
    mov rax, 60
    syscall

;;     push qword [rsp+0x8]
;;     mov rax,0x0
;; 
;;     push rax
;;     pop rax
;;     pop rcx
;;     mov rdx,0x0
;; 
;;     cmp rcx,rax
;;     mov rbx,0x1
;; 
;;     cmovg rdx,rbp
;;     push rdx
;;     pop rax
;;     cmp rax,0x0
;;     jz .end
;;     push qword [rsp+0x8]
;;     push qword [rsp+0x8]
;;     pop rax
;;     pop rcx
;;     mov rbx,rax
;;     mov rax,rcx
;;     div rbx
;;     push rax
;;     pop rax
;;     mov [rsp+0x8],rax
;;     jmp .loop
;; .end:
;;     mov rax,0x3c
;; 
;;     mov rdi,[rsp+0x8]
;;     syscall
;; 
;; 
;;     mov rax, 20
;;     mov rbx, 10
;;     div rbx
;; 
;;     mov rdi, rax
;;     mov rax, 60
;;     syscall

    ;; mov rax,0x5

    ;; push rax
    ;; mov rax,0x0

    ;; push rax
    ;; mov rax,0x0

    ;; push rax
    ;; pop rax
    ;; mov rcx,0x8

    ;; mul rcx
    ;; lea rcx,[rsp+0x8]
    ;; add rax,rcx
    ;; push qword [rax]
    ;; pop rdx
    ;; mov rax,0x0

    ;; push rax
    ;; pop rax
    ;; mov rcx,0x8

    ;; mul rcx
    ;; lea rcx,[rsp+0x0]
    ;; add rax,rcx
    ;; mov [rax],rdx
    ;; mov rax,0x3c

    ;; mov rdi,[rsp+0x0]
    ;; syscall
 


    ;; push qword 0x3
    ;; push qword 0x2
    ;; push qword 0x1

    ;; mov rax, 1
    ;; push rax
    ;; pop rax
    ;; mov rcx, 8
    ;; mul rcx

    ;; lea rcx, [rsp + 0]
    ;; add rax, rcx
    ;; push qword [rax]
    ;; pop rdi 

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
