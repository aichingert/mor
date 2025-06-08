main :: fn() {
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

    d : i32 = 20
    e : i32 = 10

    while d >= e {
        t := 2
        e = e * t
    }

    $asm(
        "mov rax, 60",
        "mov rdi, e",
        "syscall"
    )
}
