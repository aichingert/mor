print_num :: (num: i64) {
    n := num

    if n < 0 {
        print_u8(45)
        n = -n
    }

    out := [0,0,0,0,0]
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
        idx := len
        idx = idx - i
        idx = idx - 1

        print_u8(out[idx])
        i = i + 1
    }

    print_u8(10)
}

print_arr :: (arr: u8, len: u8) {
    i := 0

    while i < len {
        print_u8(arr[i])
        i = i + 1
    }

    print_u8(10)
}

print_u8 :: (n: i32) {
    $asm(
        "mov rax, 1",
        "lea rsi, n",
        "mov rdi, 1",
        "mov rdx, 8",
        "syscall"
    )
}

main :: () {
    n := 65

    print_arr([45, 48,49,50,51], 4)

    print_num(-123)
}


