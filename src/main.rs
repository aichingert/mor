use std::fs::{self, File};
use std::io::Read;

use lang::lex::*;

fn run(src: &String) {
    let mut lexer: Lexer = Lexer::new(src);

    lexer.lex();
    println!("{:?}", lexer.tokens);
}

fn main() {
    let mut args =  std::env::args().collect::<Vec<String>>();

    if args.len() <= 1 {
        // TODO: CLI repl
    } else {
        args.remove(0);
        let filename = fs::canonicalize(&args[0]).expect(&format!("File: {} not found!", &args[0]));
        let mut src = String::new();

        match File::open(&filename) {
            Ok(mut file) => match file.read_to_string(&mut src) {
                    Ok(_) => (),
                    Err(e) => panic!("Reading from file {} failed: [{}]", &args[0], e),
                },
            Err(e) => panic!("Could not open file {} failed: [{}]", &args[0], e),
        };

        run(&src);
    }
}
