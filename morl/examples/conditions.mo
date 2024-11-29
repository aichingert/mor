main :: () {
    a :: 3
    b := 5
    c := 10

    if a >= c {
        c = 20 - b - a
    }

    $asm(
        "mov rax, 60",
        "mov rdi, c",
        "syscall"
    )
}
