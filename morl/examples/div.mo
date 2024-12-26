main :: () {
    a := 10
    b := 2

    while a > 0 {
        a = a / b
    }

    $asm("mov rax, 60", "mov rdi, a", "syscall")
}
