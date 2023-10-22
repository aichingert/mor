pub mod parser;
pub use parser::Parser;

pub mod lexer;
pub use lexer::Lexer;

pub mod token;
pub use token::Token;

#[derive(Debug)]
pub enum Expr {
    NumberExpr(i64),
    ParenExpr(Box<Expr>),
    BinaryExpr(Box<Expr>, Token, Box<Expr>),
    UnaryExpr(Token, Box<Expr>),
}

impl Expr {
    pub fn evaluate(&self) -> i64 {
        match self {
            Expr::NumberExpr(n) => *n,
            Expr::ParenExpr(ex) => ex.evaluate(),
            Expr::UnaryExpr(op, expr) => match op {
                Token::Minus => -expr.evaluate(),
                _ => panic!("invalid unary operator! {:?}", op),
            }
            Expr::BinaryExpr(l, op, r) => {
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
