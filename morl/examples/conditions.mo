main :: () {
    a :: 5
    b := 3
    c := 0

    if 1 {
        c = a * b
    }

    $asm(
        "mov rax, 60",
        "mov rdi, c",
        "syscall"
    )
}
