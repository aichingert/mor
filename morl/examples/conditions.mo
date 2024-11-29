main :: () {
    a : str : 3
    b : i8 = 5
    c : i8 = 10
    
    if 0 {
        a = 1
        b = 1
    } elif 0 { 
        a = 2
        b = 2
    } elif 0 {
        a = 3
        b = 3
    } else {
        a = 5
        b = 5
    }

    c = a + b

    $asm(
        "mov rax, 60",
        "mov rdi, c",
        "syscall"
    )
}
