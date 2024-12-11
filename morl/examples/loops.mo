main :: () {
    a : i32 = 1
    b : i32 = 0
    c : i32 = 0

    i : i32 = 8

    while i {
        c = a + b
        b = a
        a = c

        i = i - 1
    }

    $asm(
        "mov rax, 60",
        "mov rdi, a",
        "syscall"
    )
}
