main :: () {
    a := 3
    b := 8

    c :: b - a

    $asm(
        "mov rax, 60",
        "mov rdi, c",
        "syscall",
    )
}
