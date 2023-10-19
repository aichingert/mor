mod ast;
use ast::{Lexer, Token};

fn main() {
    let mut lex = Lexer::new("10 + 3 * 4".chars().collect::<Vec<_>>());
    let mut token = lex.next_token();

    while token != Token::Eof {
        println!("{:?}", token);
        token = lex.next_token();
    }
}
