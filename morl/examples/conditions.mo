main :: () {
    a :: 10
    b := 20
    c :: 13

    if a + 3 < b {
        b = 0
    }

    $asm(
        "mov rax, 60",
        "mov rdi, b",
        "syscall"
    )
}
