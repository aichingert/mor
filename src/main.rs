mod ast;
use ast::*;

mod parser;
use parser::*;

mod compiler;
use compiler::*;

fn main() -> std::io::Result<()> {
    let Some(file) = std::env::args().nth(1) else {
        println!("lang: \x1b[31mfatal error\x1b[0m: no input files");
        std::process::exit(1);
    };

    if !file.ends_with(".mor") {
        println!("lang: \x1b[31mfatal error\x1b[0m: invalid filename [expected .mor]");
        std::process::exit(1);
    }

    let source = std::fs::read_to_string(file)?;
    let block = parse(source.as_bytes()).unwrap();

    for stmt in &block {
        print(stmt, 0);
        println!("=====");
    }

    Compiler::compile(block).unwrap();

    Ok(())
}
