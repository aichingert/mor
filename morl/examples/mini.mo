main :: () {
    var := 42

    $asm(
        "mov rax, var"
    )

    $asm(
        "mov rax, 60", 
        "mov rdi, 1",
        "syscall"
    )

    other := 30

    anoth := 10 + var * other
}
