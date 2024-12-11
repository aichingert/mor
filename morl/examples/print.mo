print_num :: (n: i32) {
    $asm(
        "mov rax, 60",
        "mov rdi, n",
        "syscall"
    )
}

main :: () {
    n := 50 + 50

    $asm(
        "mov rax, 60",
        "mov rdi, n",
        "syscall"
    )

    print_num(n)
}


