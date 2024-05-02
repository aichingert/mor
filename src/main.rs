use std::io::{self, BufRead};
use std::iter::Peekable;

type N = f64;

enum Instr {
    Add(N),
}

#[derive(Debug)]
enum Token {
    Num(String),

    Plus,
    Minus,

    Star,
    Slash,
}

impl Token {
    fn parse_line(mut chars: Peekable<std::str::Chars>,) -> Vec<Token> {
        let mut tokens = Vec::new();

        while let Some(ch) = chars.next() {
            if ch == ' ' { continue; }

            tokens.push(match ch {
                '+' => Token::Plus,
                '-' => Token::Minus,
                '/' => Token::Star,
                '*' => Token::Slash,
                _ => {
                    println!("ERROR: invalid token {ch}");
                    std::process::exit(1);
                }
            });
        }

        tokens
    }
}

struct Program {
    byte_code: Vec<Instr>
}

fn lex(filename: String) -> Vec<Token> {
    let file = std::fs::File::open(filename).unwrap();
    let mut tokens = Vec::new();

    for line in io::BufReader::new(file).lines().flatten() {
        tokens.append(&mut Token::parse_line(line.chars().peekable()));
        println!("{tokens:?}");
    }

    tokens
}

fn parse(tokens: Vec<Token>) -> Program {
    Program { byte_code: Vec::new() }
}

fn main() {
    let Some(filename) = std::env::args().into_iter().nth(1) else {
        println!("lang: \x1b[31mfatal error\x1b[0m: no input files");
        std::process::exit(1);
    };

    let tokens = lex(filename);
    let prog   = parse(tokens);

}
