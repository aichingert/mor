use crate::{Compiler, Stmt, Local};

impl<'s> Compiler {
    pub fn compile_stmt(&mut self, stmt: Stmt<'s>) {
        match stmt {
            Stmt::Expr(expr) => self.compile_expr(expr),
            Stmt::Func(func) => self.compile_func(func),
            Stmt::Local(loc) => self.compile_local(loc),
        }
    }

    fn compile_local(&mut self, loc: Local<'s>) {
    }
}
