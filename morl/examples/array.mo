main :: () {

    arr := [10, 20, 30]
    var := arr[3]

    $asm(
        "mov rax, 60",
        "mov rdi, var",
        "syscall"
    )
}
