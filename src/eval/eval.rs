use std::collections::HashMap;

use crate::ast::Token;
use crate::eval::Obj;

pub struct Environment {
    pub variables: HashMap<String, Obj>,
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
    AstAssign(String, Expr),
    AstExpr(Expr),
}

impl Statement {
    pub fn evaluate(self, env: &mut Environment) -> Obj {
        match self {
            Statement::AstDecl(ident, expr) => {
                let value = expr.evaluate(env);
                env.variables.insert(ident, value.clone());
                value
            },
            Statement::AstAssign(ident, expr) => {
                let value = expr.evaluate(env);
                *env.variables.get_mut(&ident).expect("has to be declared") = value.clone();
                value
            }
            Statement::AstExpr(expr) => expr.evaluate(env),
        }
    }
}

#[derive(Debug)]
pub enum Expr {
    IdentExpr(String),
    NumberExpr(i64),
    BooleanExpr(bool),
    ParenExpr(Box<Expr>),
    BinaryExpr(Box<Expr>, Token, Box<Expr>),
    UnaryExpr(Token, Box<Expr>),
}

impl Expr {
    pub fn evaluate(&self, env: &Environment) -> Obj {
        match self {
            Expr::IdentExpr(ident) => env.variables.get(ident).unwrap().clone(),
            Expr::NumberExpr(n)  => Obj::Num(*n),
            Expr::BooleanExpr(b) => Obj::Bool(*b),
            Expr::ParenExpr(ex) => ex.evaluate(env),
            Expr::UnaryExpr(op, expr) => match op {
                Token::Minus => {
                    let Obj::Num(n) = expr.evaluate(env) else {
                        panic!("Not able to calculate unary minus for anything except number");
                    };

                    Obj::Num(-n)
                }
                _ => panic!("invalid unary operator! {:?}", op),
            }
            Expr::BinaryExpr(l, op, r) => {
                let obj_l = l.evaluate(env);
                let obj_r = r.evaluate(env);

                match (obj_l, op, obj_r) {
                    (Obj::Num(l), Token::Minus, Obj::Num(r)) => Obj::Num(l - r),
                    (Obj::Num(l), Token::Plus, Obj::Num(r)) => Obj::Num(l + r),
                    (Obj::Num(l), Token::Star, Obj::Num(r)) => Obj::Num(l * r),
                    (Obj::Num(l), Token::Slash, Obj::Num(r)) => Obj::Num(l / r),
                    (Obj::Num(l), Token::Power, Obj::Num(r)) => Obj::Num(power(l, r)),
                    (Obj::Num(l), Token::XOR, Obj::Num(r)) => Obj::Num(l ^ r),
                    (Obj::Num(l), Token::BitAnd, Obj::Num(r)) => Obj::Num(l & r),
                    (Obj::Num(l), Token::BitOr, Obj::Num(r)) => Obj::Num(l | r),
                    (Obj::Bool(l), Token::And, Obj::Bool(r)) => Obj::Bool(l && r),
                    (Obj::Bool(l), Token::Or, Obj::Bool(r)) => Obj::Bool(l || r),
                    _ => panic!("invalid arrangement {:?} op: {:?} {:?}", l, op, r),
                }
            }
        }
    }
}

fn power(base: i64, exp: i64) -> i64 {
    let mut res = 1;

    for _ in 0..exp {
        res *= base;
    }

    res
}
