main :: fn() {
    a := 3
    b := 8

    c :: (b - a) * 2

    $asm(
        "mov rax, 60",
        "mov rdi, c",
        "syscall"
    )
}
