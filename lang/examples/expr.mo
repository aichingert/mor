main :: () {
    a : u8 = 3;
    b : u8 = 8;

    c :: (b - a) * 2;

    $asm(
        "mov rax, 60",
        "mov rdi, c",
        "syscall"
    );
}
