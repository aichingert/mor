// algebraic_optimizations
//
use crate::ast::*;

pub fn eval_const_stmt(stmt: Stmt<'_>) -> Stmt<'_> {
    match stmt {
        Stmt::Expr(expr) => Stmt::Expr(eval_const_expr(expr)),
        Stmt::Local(loc) => {
            let value = if let Some(expr) = loc.value {
                Some(eval_const_expr(expr))
            } else {
                None
            };

            Stmt::Local(Local {
                name: loc.name,
                size: loc.size,
                typ: loc.typ,
                value,
            })
        }
        _ => stmt,
    }
}

fn eval_const_expr(expr: Expr<'_>) -> Expr<'_> {
    match expr {
        Expr::SubExpr(expr) => eval_const_expr(*expr),
        Expr::UnOp(expr) => {
            let eval = eval_const_expr(expr.child);

            if let Some(num) = get_number(&eval) {
                match expr.kind {
                    UnOpKind::Not => Expr::Number(!num),
                    UnOpKind::Neg => Expr::Number(-num),
                }
            } else {
                eval
            }
        }
        Expr::BiOp(expr) => {
            let [a, b] = expr.children;
            let (eval_a, eval_b) = (eval_const_expr(a), eval_const_expr(b));

            match (get_number(&eval_a), get_number(&eval_b)) {
                (Some(a), Some(b)) => Expr::Number(eval_bi_expr(expr.kind, a, b)),
                (Some(a), None) => Expr::BiOp(Box::new(BiOpEx { kind: expr.kind, children: [Expr::Number(a), eval_b] })),
                (None, Some(b)) => Expr::BiOp(Box::new(BiOpEx { kind: expr.kind, children: [eval_a, Expr::Number(b)] })),
                (None, None) => Expr::BiOp(Box::new(BiOpEx { kind: expr.kind, children: [eval_a, eval_b] })),
                _ => panic!(),
            }
        }
        _ => expr,
    }
}

fn eval_bi_expr(kind: BiOpKind, a: i64, b: i64) -> i64 {
    match kind {
        BiOpKind::Add => a + b,
        BiOpKind::Sub => a - b,
        BiOpKind::Div => a / b,
        BiOpKind::Mul => a * b,

        BiOpKind::BiOr => a | b,
        BiOpKind::BiAnd=> a & b,

        BiOpKind::BoOr => if a != 0 || b != 0 { 1 } else { 0 },
        BiOpKind::BiAnd=> if a != 0 && b != 0 { 1 } else { 0 },

        _ => panic!("invalid eval bi expr"),
    }
}

fn get_number(expr: &Expr<'_>) -> Option<i64> {
    match expr {
        Expr::Number(n) => Some(*n),
        _ => None,
    }
}

