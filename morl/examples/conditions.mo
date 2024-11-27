main :: () {
    a :: 10
    b := 20 ^ 2
    c :: 13

    if 0 {
        b = 0
    }

    if 1 {
        b = 1
    }

    $asm(
        "mov rax, 60",
        "mov rdi, b",
        "syscall"
    )
}
