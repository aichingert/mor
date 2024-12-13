print_num :: (n: i32) {
    $asm(
        "mov rax, 1",
        "lea rsi, n",
        "mov rdx, 1",
        "syscall"
    )

    $asm(
        "mov rax, 60",
        "mov rdi, n",
        "syscall"
    )
}

main :: () {
    n :=5*3 

    print_num(n)
}


