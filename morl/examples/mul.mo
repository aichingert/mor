main :: () {
    a := 3
    b := 8

    c :: b / a
    d :: c / a
    e :: d / a
    f :: e / a
    g :: f / a
    h :: g / a
    i :: h / a
    j :: i / a
    k :: j / a
    l :: k / a
    m :: l / a
    n :: m / a
    o :: n / a
    p :: o / a
    q :: p / a
    r :: q / a
    s :: r / a
    t :: s / a
    u :: t / a
    v :: u / a
    w :: v / a
    x :: w / a
    y :: x / a
    z :: y / a
    z1 :: z / a

    $asm(
        "mov rax, 60",
        "mov rdi, a",
        "syscall",
    )
}
