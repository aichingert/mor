main :: () {
    a : str : 3
    b : i8 = 5
    c : i8 = 10

    if a >= c || 0 || 1 && 0 {
        c = 20 - b - a
    }
    
    if b - c ^ 5 == a || b + 3 {
        c = 2
    }

    $asm(
        "mov rax, 60",
        "mov rdi, c",
        "syscall"
    )
}
