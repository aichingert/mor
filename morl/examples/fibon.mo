fib :: (n: i32) -> i32 {
    if n <= 1 {
        return 1
    }

    return fib(n - 1) + fib(n - 2)
}

main :: () {
    a : i32 = 1
    b : i32 = 0
    c : i32 = 0

    i : i32 = 7

    while i {
        c = a + b
        b = a
        a = c

        i = i - 1
    }

    n := fib(5)

    $asm(
        "mov rax, 60",
        "mov rdi, a",
        "syscall"
    )
}
