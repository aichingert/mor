main :: () {

    arr := [10, 20, 30]
    arr[1] = 0

    $asm(
        "mov rax, 60",
        "mov rdi, arr",
        "syscall"
    )
}
