main :: () {
    a := 3
    b := 8

    c := 2 - 1 - 1

    $asm(
        "mov rax, 60",
        "mov rdi, c",
        "syscall"
    )
}
