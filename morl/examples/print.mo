print_num :: (n: i32) {
    if n < 0 {
        return
    }

    $asm(
        "mov rax, 60",
        "mov rdi, 1",
        "syscall"
    )
}

main :: () {
    print_num(10)
}


