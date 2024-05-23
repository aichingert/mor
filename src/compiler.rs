use std::collections::HashMap;
use std::io::Write;

use crate::ast::*;

#[derive(Debug, Clone, Copy)]
enum RegKind {
    A,
    B,
    C,
    D,
    SI,
    DI,
    BP,
    SP,
    R8,
    R9,
    R10,
    R11,
    R12,
    R13,
    R14,
    R15,
}

#[derive(Debug, Clone, Copy)]
enum RegSize {
    R, // 64 bit
    E, // 32 bit
    X, // 16 bit
    H, //  8 bit high
    L, //  8 bit low
    B, //  8 bit low => for R12, etc.
}

#[derive(Debug, Clone, Copy)]
struct Register {
    kind: RegKind,
    size: RegSize,
}

impl Register {
    fn to_str(&self) -> &str {
        match (self.kind, self.size) {
            (RegKind::A, RegSize::R) => "rax",
            (RegKind::B, RegSize::R) => "rbx",
            (RegKind::C, RegSize::R) => "rcx",
            (RegKind::D, RegSize::R) => "rdx",
            (RegKind::SP, RegSize::R) => "rsp",
            _ => todo!(),
        }
    }
}

#[derive(Debug, Clone, Copy)]
enum Operand {
    Reg(Register),  // ex: mov !rax!, 1
    Val(Register),  // ex: mov rbx, ![rax]!
    Implicit,       // TODO
    Immediate(i64), // ex: mov rax, !1!
    Direct(i64),    // ex: mov rax, ![0x1234]!
    // TODO: not sure if this is needed - difference to indexed comes from the past where only
    Based(Register, i32),
    Indexed(Register, i32), // ex: mov rax, ![rsp + 8]!
}

impl Operand {
    fn to_str(&self) -> String {
        match self {
            Operand::Reg(reg) => reg.to_str().to_string(),
            Operand::Val(reg) => format!("[{}]", reg.to_str()),
            Operand::Immediate(val) => format!("{val}"),
            Operand::Indexed(reg, off) => format!("qword [{} + {off}]", reg.to_str()),
            _ => todo!(),
        }
    }

    #[inline]
    fn rax() -> Self {
        Self::Reg(Register { kind: RegKind::A, size: RegSize::R })
    }

    #[inline]
    fn rdx() -> Self {
        Self::Reg(Register { kind: RegKind::D, size: RegSize::R })
    }
    
    #[inline]
    fn rcx() -> Self {
        Self::Reg(Register { kind: RegKind::C, size: RegSize::R })
    }

    #[inline]
    fn create_reg(kind: RegKind, size: RegSize) -> Self {
        Self::Reg(Register { kind, size })
    }

    #[inline]
    fn create_idx(kind: RegKind, size: RegSize, idx: i32) -> Self {
        Self::Indexed(Register { kind, size }, idx)
    }
}

#[derive(Debug)]
enum OpKind {
    Lbl(String),

    Jmp(String, String),
    Cmp(Operand, Operand),

    Or(Operand, Operand),
    And(Operand, Operand),

    Lea(Operand, Operand),
    Mov(Operand, Operand),
    Add(Operand, Operand),
    Sub(Operand, Operand),

    Div(Operand),
    Mul(Operand),

    Not(Operand),
    Neg(Operand),

    Pop(Operand),
    Push(Operand),

    Cdq,
}

#[derive(Debug)]
struct Opcode {
    kind: OpKind,
    size: RegSize,
}

impl Opcode {
    #[inline]
    fn u64(kind: OpKind) -> Self {
        Self { kind, size: RegSize::R }
    }

    fn gen_asm(self) -> String {
        match self.kind {
            OpKind::Lbl(lbl) => lbl,

            OpKind::Jmp(knd, lbl) => format!("    {knd} {lbl}"),

            OpKind::Cmp(op1, op2) => format!("    cmp {}, {}", op1.to_str(), op2.to_str()),
            OpKind::Lea(op1, op2) => format!("    lea {}, {}", op1.to_str(), op2.to_str()),
            OpKind::Mov(op1, op2) => format!("    mov {}, {}", op1.to_str(), op2.to_str()),
            OpKind::Add(op1, op2) => format!("    add {}, {}", op1.to_str(), op2.to_str()),
            OpKind::And(op1, op2) => format!("    and {}, {}", op1.to_str(), op2.to_str()),
            OpKind::Or(op1, op2) => format!("    or {}, {}", op1.to_str(), op2.to_str()),
            OpKind::Sub(op1, op2) => format!("    sub {}, {}", op1.to_str(), op2.to_str()),
            OpKind::Mul(op) => format!("    imul {}", op.to_str()),
            OpKind::Div(op) => format!("    idiv {}", op.to_str()),
            OpKind::Neg(op) => format!("    neg {}", op.to_str()),
            OpKind::Not(op) => format!("    not {}", op.to_str()),

            OpKind::Pop(op) => format!("    pop {}", op.to_str()),
            OpKind::Push(op) => format!("    push {}", op.to_str()),

            OpKind::Cdq => "    cdq".to_string(),
        }
    }
}

#[derive(Debug)]
pub struct CompileError {
    msg: String,
}

impl std::fmt::Display for CompileError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{}", self.msg)
    }
}

impl CompileError {
    pub fn new(msg: &str) -> CompileError {
        CompileError {
            msg: msg.to_string(),
        }
    }
}

impl std::error::Error for CompileError {
    fn description(&self) -> &str {
        &self.msg
    }
}

#[derive(Debug)]
pub struct Compiler {
    rsp: i32,
    lbl: i32,

    text: Vec<Opcode>, // section
    locals: HashMap<String, i32>,
}

pub const SET: u16 = 0x1;
pub const OR:  u16 = 0x2;
pub const AND: u16 = 0x4;

impl<'s> Compiler {
    fn new() -> Self {
        Self {
            rsp: 0,
            lbl: 0,

            text: Vec::new(),
            locals: HashMap::new(),
        }
    }

    fn compile_expr(&mut self, expr: Expr<'s>, flags: u16) -> Result<(), CompileError> {
        let opcode = match expr {
            Expr::Number(num) => Opcode::u64(
                OpKind::Mov(
                    Operand::rax(),
                    Operand::Immediate(
                        num.parse()
                            .map_err(|_| CompileError::new("Number too big"))?,
                    ),
                ),
            ),
            Expr::Ident(Ident { value }) => {
                let Some(offset) = self.locals.get(value) else {
                    return Err(CompileError::new("Ident: not found"));
                };
                let (op1, op2) = (
                    Operand::rax(),
                    Operand::create_idx(RegKind::SP, RegSize::R, self.rsp - offset),
                );

                match flags & SET == SET {
                    true => Opcode::u64(OpKind::Lea(op1, op2)),
                    false => Opcode::u64(OpKind::Mov(op1, op2)),
                }
            }
            Expr::UnOp(unexpr) => {
                self.compile_expr(unexpr.child, 0)?;

                Opcode::u64(match unexpr.kind {
                    UnOpKind::Neg => OpKind::Neg(Operand::rax()),
                    UnOpKind::Not => OpKind::Not(Operand::rax()),
                })
            }
            Expr::BiOp(biexpr) => {
                let [a, b] = biexpr.children;
                
                match biexpr.kind {
                    BiOpKind::Add => {
                        self.compile_expr(a, 0)?;
                        self.text.push(Opcode::u64(OpKind::Push(Operand::rax())));
                        self.rsp += 8;
                        self.compile_expr(b, 0)?;
                        self.text.push(Opcode::u64(OpKind::Pop(Operand::rdx())));
                        self.rsp -= 8;

                        Opcode::u64(OpKind::Add(Operand::rax(), Operand::rdx()))
                    }
                    BiOpKind::Sub => {
                        self.compile_expr(a, 0)?;
                        self.text.push(Opcode::u64(OpKind::Push(Operand::rax())));
                        self.rsp += 8;
                        self.compile_expr(b, 0)?;
                        self.text.push(Opcode::u64(OpKind::Mov(Operand::rdx(), Operand::rax())));
                        self.text.push(Opcode::u64(OpKind::Pop(Operand::rax())));
                        self.rsp -= 8;

                        Opcode::u64(OpKind::Sub(Operand::rax(), Operand::rdx()))
                    }
                    BiOpKind::Mul => {
                        self.compile_expr(a, 0)?;
                        self.text.push(Opcode::u64(OpKind::Push(Operand::rax())));
                        self.rsp += 8;
                        self.compile_expr(b, 0)?;
                        self.text.push(Opcode::u64(OpKind::Pop(Operand::rdx())));
                        self.rsp -= 8;

                        Opcode::u64(OpKind::Mul(Operand::rdx()))
                    }
                    BiOpKind::Div => {
                        self.compile_expr(a, 0)?;
                        self.text.push(Opcode::u64(OpKind::Push(Operand::rax())));
                        self.rsp += 8;
                        self.compile_expr(b, 0)?;
                        self.text.push(Opcode::u64(OpKind::Mov(Operand::rcx(), Operand::rax())));
                        self.text.push(Opcode::u64(OpKind::Pop(Operand::rax())));
                        self.rsp -= 8;

                        self.text.push(Opcode::u64(OpKind::Cdq));
                        Opcode::u64(OpKind::Div(Operand::rcx()))
                    }
                    BiOpKind::Set => {
                        self.compile_expr(b, 0)?;
                        self.text.push(Opcode::u64(OpKind::Push(Operand::rax())));
                        self.rsp += 8;
                        self.compile_expr(a, SET)?;
                        self.text.push(Opcode::u64(OpKind::Pop(Operand::rdx())));
                        self.rsp -= 8;

                        Opcode::u64(OpKind::Mov(Operand::create_idx(RegKind::A, RegSize::R, 0), Operand::rdx()))
                    }
                    BiOpKind::CmpEq | BiOpKind::CmpNe | BiOpKind::CmpLt | BiOpKind::CmpLe | BiOpKind::CmpGt | BiOpKind::CmpGe => {
                        self.compile_expr(a, 0)?;
                        self.text.push(Opcode::u64(OpKind::Push(Operand::rax())));
                        self.rsp += 8;
                        self.compile_expr(b, 0)?;
                        self.text.push(Opcode::u64(OpKind::Pop(Operand::rdx())));
                        self.rsp -= 8;

                        self.text.push(Opcode::u64(OpKind::Cmp(Operand::rax(), Operand::rdx())));

                        Opcode::u64(OpKind::Jmp(biexpr.kind.to_jmp()?, format!("l{}", self.lbl)))
                    }
                    BiOpKind::BiOr => {
                        self.compile_expr(a, 0)?;
                        self.text.push(Opcode::u64(OpKind::Push(Operand::rax())));
                        self.rsp += 8;
                        self.compile_expr(b, 0)?;
                        self.text.push(Opcode::u64(OpKind::Pop(Operand::rdx())));
                        self.rsp -= 8;

                        Opcode::u64(OpKind::Or(Operand::rax(), Operand::rdx()))
                    }
                    BiOpKind::BiAnd => {
                        self.compile_expr(a, 0)?;
                        self.text.push(Opcode::u64(OpKind::Push(Operand::rax())));
                        self.rsp += 8;
                        self.compile_expr(b, 0)?;
                        self.text.push(Opcode::u64(OpKind::Pop(Operand::rdx())));
                        self.rsp -= 8;

                        Opcode::u64(OpKind::And(Operand::rax(), Operand::rdx()))
                    }
                    BiOpKind::BoOr => {
                        return Ok(());
                    }
                    BiOpKind::BoAnd => {
                        return Ok(());
                    }
                }
            }
            Expr::SubExpr(expr) => return self.compile_expr(*expr, 0),
            Expr::If(if_expr) => {
                let mut lbl = self.lbl;
                self.compile_expr(if_expr.condition, 0)?;

                self.lbl += 1;
                if_expr
                    .on_true
                    .into_iter()
                    .try_for_each(|stmt| self.compile_stmt(stmt))?;

                if let Some(else_branch) = if_expr.on_false {
                    self.text.push(Opcode::u64(OpKind::Jmp("jmp".to_string(), format!("l{}", lbl + 1))));
                    self.text.push(Opcode::u64(OpKind::Lbl(format!("l{}:", lbl))));
                    self.lbl += 1;
                    lbl += 1;
                    else_branch
                        .into_iter()
                        .try_for_each(|stmt| self.compile_stmt(stmt))?;
                }

                self.lbl += 1;
                Opcode::u64(OpKind::Lbl(format!("l{}:", lbl)))
            }
            Expr::While(while_expr) => {
                self.lbl += 1;
                let lbl = self.lbl;
                self.text.push(Opcode::u64(OpKind::Lbl(format!("l{}:", lbl))));

                self.lbl += 1;
                self.compile_expr(while_expr.condition, 0)?;

                self.lbl += 1;
                while_expr
                    .body
                    .into_iter()
                    .try_for_each(|stmt| self.compile_stmt(stmt))?;

                self.lbl += 2;
                self.text.push(Opcode::u64(OpKind::Jmp("jmp".to_string(), format!("l{}", lbl))));
                Opcode::u64(OpKind::Lbl(format!("l{}:", lbl + 1)))
            }
        };
        self.text.push(opcode);

        Ok(())
    }

    fn compile_local(&mut self, local: Local<'s>) -> Result<(), CompileError> {
        if let Some(val) = local.value {
            self.compile_expr(val, 0)?;
        }

        self.locals.insert(local.name.to_string(), (self.locals.len() + 1) as i32 * 8);
        self.text.push(Opcode::u64(OpKind::Push(Operand::rax())));
        self.rsp += 8;

        Ok(())
    }

    fn compile_stmt(&mut self, stmt: Stmt<'s>) -> Result<(), CompileError> {
        match stmt {
            Stmt::Expr(ex) => self.compile_expr(ex, 0),
            Stmt::Local(loc) => self.compile_local(loc),
        }
    }

    fn emit_asm(self) -> Result<(), Box<dyn std::error::Error>> {
        let mut file = std::fs::File::create("prog.asm")?;
        file.write_all(b"section .text\n  global main\nmain:\n")?;

        for opcode in self.text.into_iter() {
            let mut line = opcode.gen_asm();
            line.push('\n');
            file.write_all(&line.bytes().collect::<Vec<_>>())?;
        }

        file.write_all(b"    mov rdi, rax\n")?;
        file.write_all(b"    mov rax, 60\n")?;
        file.write_all(b"    syscall\n")?;

        use std::process::Command;
        Command::new("nasm")
            .args(["prog.asm", "-f", "elf64", "-o", "prog.o"])
            .output()?;
        Command::new("gcc").args(["-no-pie", "prog.o"]).output()?;
        Command::new("rm").args(["prog.o"]).output()?;

        Ok(())
    }

    pub fn compile(block: Block<'s>) -> Result<(), CompileError> {
        let mut compiler = Compiler::new();

        for stmt in block {
            compiler.compile_stmt(stmt)?;
        }

        compiler
            .emit_asm()
            .map_err(|_| CompileError::new("unable to emit asm"))
    }
}
