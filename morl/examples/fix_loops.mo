main :: () {
    a := 10
    b := 20

    while a <= b {
        o :: 2
        a = a * o
    }

    $asm(
        "mov rax, 60",
        "mov rdi, a",
        "syscall"
    )
}
