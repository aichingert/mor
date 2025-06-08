print_num :: fn(num: i64) {
    n := num

    if n < 0 {
        print_u8(45)
        n = -n
    }

    out := [0,0,0,0,0,0,0,0,0,0]
    len := 0

    while n != 0 {
        $asm("mov rdx, 0")
        div := n / 10

        rem := 0
        $asm("mov rem, rdx")

        out[len] = rem + 48
        n = div
        len = len + 1
    }

    i := 0
    while i < len {
        print_u8(out[len - i - 1])
        i = i + 1
    }

    print_u8(10)
}

print_arr :: fn(arr: u8, len: u8) {
    i := 0

    while i < len {
        print_u8(arr[i])
        i = i + 1
    }

    print_u8(10)
}

print_u8 :: fn(n: i32) {
    $asm(
        "mov rax, 1",
        "lea rsi, n",
        "mov rdi, 1",
        "mov rdx, 8",
        "syscall"
    )
}

main :: fn() {
    n := 65

    print_arr([45, 48,49,50,51], 4)

    ten := 10
    five := 5
    res := 3 * ten - 7 * 3

    print_num(res)
}


