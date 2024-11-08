main :: () {
    fth := 10
    var := fth
    fst := 1
    snd := 2
    trd := fst + snd

    $asm(
        "mov rax, 60",
        "mov rdi, 0",
        "syscall"
    )
}
