main :: () {
    a : str : 3
    b : i8 = 5
    c : i8 = 10
    
    if 0 {
        o :: 1
        a = o
        b = o
    } elif 0 { 
        t :: 2
        a = t
        b = t
    } elif 0 {
        d :: 3
        a = d
        b = d
    } else {
        f :: 5
        a = f
        b = f
    }

    c = a + b

    $asm(
        "mov rax, 60",
        "mov rdi, c",
        "syscall"
    )
}
