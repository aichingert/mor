use std::collections::HashMap;

pub mod parser;
pub use parser::Parser;

pub mod lexer;
pub use lexer::Lexer;

pub mod token;
pub use token::Token;

pub struct Environment {
    pub variables: HashMap<String, i64>,
}

impl Environment {
    pub fn new() -> Self {
        Self {
            variables: HashMap::new(),
        }
    }
}

pub enum Statement {
    AstDecl(String, Expr),
    AstExpr(Expr),
}

impl Statement {
    pub fn evaluate(self, env: &mut Environment) -> i64 {
        match self {
            Statement::AstDecl(ident, expr) => {
                let value = expr.evaluate(env);
                env.variables.insert(ident, value);
                value
            },
            Statement::AstExpr(expr) => expr.evaluate(env),
        }
    }
}

pub enum Expr {
    IdentExpr(String),
    NumberExpr(i64),
    ParenExpr(Box<Expr>),
    BinaryExpr(Box<Expr>, Token, Box<Expr>),
    UnaryExpr(Token, Box<Expr>),
}

impl Expr {
    pub fn evaluate(&self, env: &Environment) -> i64 {
        match self {
            Expr::IdentExpr(ident) => *env.variables.get(ident).unwrap(),
            Expr::NumberExpr(n) => *n,
            Expr::ParenExpr(ex) => ex.evaluate(env),
            Expr::UnaryExpr(op, expr) => match op {
                Token::Minus => -expr.evaluate(env),
                _ => panic!("invalid unary operator! {:?}", op),
            }
            Expr::BinaryExpr(l, op, r) => {
                match op {
                    Token::Minus => l.evaluate(env) - r.evaluate(env),
                    Token::Plus  => l.evaluate(env) + r.evaluate(env),
                    Token::Star  => l.evaluate(env) * r.evaluate(env),
                    Token::Slash => l.evaluate(env) / r.evaluate(env),
                    Token::Power => l.power(r.evaluate(env), env),
                    Token::XOR   => l.evaluate(env) ^ r.evaluate(env),
                    Token::BitAnd=> l.evaluate(env) & r.evaluate(env),
                    Token::BitOr => l.evaluate(env) | r.evaluate(env),
                    _ => panic!("invalid token!? {:?}", op),
                }
            }
        }
    }

    fn power(&self, exp: i64, env: &Environment) -> i64 {
        let base = self.evaluate(env);
        let mut res = 1;

        for _ in 0..exp {
            res *= base;
        }

        res
    }
}
