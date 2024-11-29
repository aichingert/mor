main :: () {
    a :: 3
    b := 5
    c := 0

    if 0 >= 0 {
        c = 20 - b - a
    }

    $asm(
        "mov rax, 60",
        "mov rdi, c",
        "syscall"
    )
}
