main :: () {
    ignored := 0

    var := 25 

    $asm(
        "mov rax, 60",
        "mov rdi, 25",
        "syscall"
    )

    $asm(
        "mov var, 8223372036854775807",
        "mov rax, var",
        "mov var, rax"
    )

    $asm(
        "mov rax, 60", 
        "mov rdi, 1",
        "syscall"
    )

    other := 20302

    anoth := 10 + var * other
}
