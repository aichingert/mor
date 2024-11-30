main :: () {
    a : i32 = 10
    b : i32 = 0

    while a {
        b = b + 2

        if a == 5 {
            $asm(
                "mov rax, 60",
                "mov rdi, b",
                "syscall"
            )
        }

        a = a - 1
    }

    $asm(
        "mov rax, 60",
        "mov rdi, b",
        "syscall"
    )
}
