
fn :: (n: i32) -> i32 {
    if n <= 1 {
        return n
    }

    return fn(n - 1) + fn(n - 2)
}

main :: () {
    a := fn(9)

    $asm(
        "mov rax, 60",
        "mov rdi, a",
        "syscall"
    )
}
