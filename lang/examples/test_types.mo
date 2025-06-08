add :: fn(a: u8, b: u8) -> u8 {
    return a + b
}

main :: fn() {
    small : u8 = 10
    bigger : u16 = 20

    // Should complain
    // because small and bigger have different types
    plus : u16 = small + bigger 

    $asm("mov rax, 60", "mov rdi, plus", "syscall")
}
