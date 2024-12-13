print_num :: (n: i32) {
    $asm(
        "mov rax, 1",
        "lea rsi, n",
        "mov rdi, 1",
        "mov rdx, 8",
        "syscall"
    )
}

main :: () {
    n := 65

    print_num(n)
    print_num(n + 1)
    print_num(n + 2)
}


