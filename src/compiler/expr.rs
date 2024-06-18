use crate::{Compiler, Opcode, Expr};

impl<'e> Compiler {
    pub fn compile_expr(&mut self, expr: Expr<'e>) -> Vec<Opcode> {
        match expr {
            Expr::Number(_n) => vec![],
            Expr::Ident(_id) => vec![],
            Expr::Index(_id) => vec![],
            Expr::If(i_expr) => vec![],
            Expr::Call(c_expr) => vec![],
            Expr::UnOp(u_expr) => vec![],
            Expr::BiOp(b_expr) => vec![],
            Expr::While(w_expr) => vec![],
            Expr::Return(r_expr) => vec![],
            Expr::SubExpr(s_expr) => vec![],
        }
    }

    fn compile_number(&mut self, n: i64) -> Vec<Opcode> {
        vec![]
    }
}
