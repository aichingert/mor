main :: () {
    a :: 10
    b := 0
    c := 13

    if 0 {
        c = 0
        b = 1
    }

    if 0 {
        c = 1
        b = 2
    }

    $asm(
        "mov rax, 60",
        "mov rdi, b",
        "syscall"
    )
}
