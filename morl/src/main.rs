fn main() {
    let args: Vec<_> = std::env::args().skip(1).collect();

    if args.is_empty() {
        println!("usage: morl <filename/path>");
    }

}
