main :: fn() {
    $asm(
        "mov rax, 60",
        "mov rdi, 1",
        "syscall"
    )
}
