main :: fn() {

    len := 5
    arr := [5,1,6,12,3]
    prefix_sum := [0, 0, 0, 0, 0]

    i := 0

    while i < len {
        if i > 0 {
            prefix_sum[i] = prefix_sum[i] + prefix_sum[i - 1]
        }
        prefix_sum[i] = prefix_sum[i] + arr[i]
        i = i + 1
    }

    var := prefix_sum[len - 1]

    $asm(
        "mov rax, 60",
        "mov rdi, var",
        "syscall"
    )
}
