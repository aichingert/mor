add :: fn(a: i32, b: i32) -> i32 {
    return a + b
}

main :: fn() {
    prv := 1
    twc := 2
    trc := 3
    sum := add(9, 8)

    $asm(
        "mov rax, 60",
        "mov rdi, twc",
        "syscall"
    )
}
