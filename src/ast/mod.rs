pub mod parser;
pub use parser::Parser;

pub mod lexer;
pub use lexer::Lexer;

pub mod token;
pub use token::Token;

#[derive(Debug)]
pub enum BinaryExpr {
    Lit(i64),
    Expr(Box<BinaryExpr>, Token, Box<BinaryExpr>),
}

impl BinaryExpr {
    pub fn evaluate(&self) -> i64 {
        match self {
            BinaryExpr::Lit(n) => *n,
            BinaryExpr::Expr(l, op, r) => {
                match op {
                    Token::Minus => l.evaluate() - r.evaluate(),
                    Token::Plus  => l.evaluate() + r.evaluate(),
                    Token::Star  => l.evaluate() * r.evaluate(),
                    Token::Slash => l.evaluate() / r.evaluate(),
                    _ => panic!("invalid token!? {:?}", op),
                }
            }
        }
    }
}
