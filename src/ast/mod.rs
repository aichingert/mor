pub mod parser;
pub use parser::Parser;

pub mod lexer;
pub use lexer::Lexer;

pub mod token;
pub use token::Token;

pub enum Expr {
    BinExpr(BinaryExpr),
}

#[derive(Debug)]
pub enum BinaryExpr {
    Lit(i64),
    Expr(Box<BinaryExpr>, Token, Box<BinaryExpr>),
}
