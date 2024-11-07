main :: () {
    var := 10 

    $asm(
        "mov rax, 60", 
        "mov rdi, 1",
        "syscall"
    )

    other := 30

    anoth := 10 + var * other
}
