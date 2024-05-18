mod ast;

mod parser;
use parser::*;

mod compiler;
use compiler::*;

fn main() -> std::io::Result<()> {
    let Some(file) = std::env::args().into_iter().nth(1) else {
        println!("lang: \x1b[31mfatal error\x1b[0m: no input files");
        std::process::exit(1);
    };

    let source = std::fs::read_to_string(file)?;
    let block = parse(source.as_bytes()).unwrap();

    Compiler::compile(block).unwrap();

    Ok(())
}
