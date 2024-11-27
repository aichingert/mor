main :: () {
    a :: 10
    b := 20 ^ 2
    c := 13

    if 1 > 2 {
        c = 2
    }

    if 0 {
        b = a + c
    }

    if 1 {
        b = 2
    } 

    $asm(
        "mov rax, 60",
        "mov rdi, b",
        "syscall"
    )
}
