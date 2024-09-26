fib :: (n: u32) -> u32 {
    res := n - 2 + n - 1

    return res
}

main :: () {
    n :: 10
    o := n * 5

    hello :: fib(fib(o))

    return hello
}
