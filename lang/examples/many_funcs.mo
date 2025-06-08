calc :: fn(n: i32) -> i32 {
    if n <= 0 {
        return 0
    }

    return calc(n - 1) + calc(n - 2)
}

main :: fn() {
    res := calc(5)

    $asm(
        "mov rax, 60",
        "mov rdi, 0",
        "syscall"
    )
}


