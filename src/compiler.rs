use std::io::Write;
use std::collections::HashMap;

use crate::ast::*;

#[derive(Debug, Clone, Copy)]
enum Register {
    RAX,
    RBX,
    RCX,
    RDX,
    RSI,
    RDI,
    RBP,
    RSP,
    R8,
    R9,
    R10,
    R11,
    R12,
    R13,
    R14,
    R15,
}

impl Register {
    fn to_str(&self) -> &str {
        match self {
            Register::RAX => "rax",
            Register::RBX => "rbx",
            Register::RCX => "rcx",
            Register::RDX => "rdx",
            Register::RSI => "rsi",
            Register::RDI => "rdi",
            Register::RBP => "rbp",
            Register::RSP => "rsp",
            _ => todo!()
        }
    }
}

#[derive(Debug, Clone, Copy)]
enum Operand {
    Reg(Register), // ex: mov !rax!, 1
    Val(Register), // ex: mov rbx, ![rax]!
    Implicit, // TODO
    Immediate(i64),// ex: mov rax, !1!
    Direct(i64),   // ex: mov rax, ![0x1234]!
    // TODO: not sure if this is needed - difference to indexed comes from the past where only
    Based(Register, i32), 
    Indexed(Register, i32), // ex: mov rax, ![rsp + 8]!
}

impl Operand {
    fn to_str(&self) -> String {
        match self {
            Operand::Reg(reg) => format!("{}", reg.to_str()),
            Operand::Val(reg) => format!("[{}]", reg.to_str()),
            Operand::Immediate(val) => format!("{val}"),
            Operand::Indexed(reg, off) => format!("qword [{} + {off}]", reg.to_str()),
            _ => todo!(),
        }
    }
}

#[derive(Debug)]
enum Opcode {
    Add(Operand, Operand),
    Sub(Operand, Operand),
    Cdq,
    Div(Operand),
    Mul(Operand),

    Not(Operand),
    Neg(Operand),

    Pop(Operand),
    Push(Operand),
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
    fn new(msg: &str) -> CompileError {
        CompileError { msg: msg.to_string() }
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

    text: Vec<Opcode>, // section
    idents: HashMap<String, i32>,
}

// SIZES
// byte => 8 bit usigned
// WORD => 16 bit unsigned (SWORD)
// DWORD => 32 bit unsigned (SDWORD)
// QWORD => 64 bit

impl<'s> Compiler {
    fn new() -> Self {
        Self { 
            rsp: 0, 
            text: Vec::new(),
            idents: HashMap::new(),
        }
    }

    // nasm prog.asm -f elf64 -o prog.o
    // gcc -no-pie prog.o

    fn compile_expr(&mut self, expr: Expr<'s>) -> Result<(), CompileError> {
        match expr {
            Expr::Ident(id) => {
                let Some(&offset) = self.idents.get(id.value) else {
                    return Err(CompileError::new(&format!("unkown identifier: {}", id.value)));
                };

                self.text.push(Opcode::Push(Operand::Indexed(Register::RSP, offset)));
            }
            Expr::Number(n) => {
                let val = n.parse().map_err(|_| CompileError::new("number too large"))?;
                self.text.push(Opcode::Push(Operand::Immediate(val)));
            }
            Expr::SubExpr(ex) => self.compile_expr(*ex)?,
            Expr::BiOp(ex) => {
                let [a, b] = ex.children;

                self.compile_expr(a)?;
                self.compile_expr(b)?;

                let rax = Operand::Reg(Register::RAX);
                let rbx = Operand::Reg(Register::RBX);

                self.text.push(Opcode::Pop(rbx));
                self.text.push(Opcode::Pop(rax));

                match ex.kind {
                    BiOpKind::Add => self.text.push(Opcode::Add(rax, rbx)),
                    BiOpKind::Sub => self.text.push(Opcode::Sub(rax, rbx)),
                    BiOpKind::Mul => self.text.push(Opcode::Mul(rbx)),
                    BiOpKind::Div => {
                        self.text.push(Opcode::Cdq);
                        self.text.push(Opcode::Div(rbx));
                    }
                }

                self.text.push(Opcode::Push(rax));
            }
            Expr::UnOp(ex) => {
                self.compile_expr(ex.child)?;
                let rax = Operand::Reg(Register::RAX);

                self.text.push(Opcode::Pop(rax));

                match ex.kind {
                    UnOpKind::Not => self.text.push(Opcode::Not(rax)),
                    UnOpKind::Neg => self.text.push(Opcode::Neg(rax)),
                }

                self.text.push(Opcode::Push(rax));
            }
        }

        Ok(())
    }

    fn compile_local(&mut self, local: Local<'s>) -> Result<(), CompileError> {
        if let Some(val) = local.value {
            self.compile_expr(val)?;
        }

        self.idents.insert(local.name.to_string(), self.rsp);
        self.rsp += 8;

        Ok(())
    }

    fn compile_stmt(&mut self, stmt: Stmt<'s>) -> Result<(), CompileError> {
        match stmt {
            Stmt::Expr(ex)   => self.compile_expr(ex),
            Stmt::Local(loc) => self.compile_local(loc),
        }
    }

    fn emit_asm(&self) -> std::io::Result<()> {
        let mut file = std::fs::File::create("prog.asm")?;

        file.write_all(b"extern printf\ndefault rel\n\nsection .text\n  global main\nmain:\n")?;

        for opcode in self.text.iter() {
            let mut line = match opcode {
                Opcode::Add(op1, op2) => format!("    add {}, {}", op1.to_str(), op2.to_str()),
                Opcode::Sub(op1, op2) => format!("    sub {}, {}", op1.to_str(), op2.to_str()),
                Opcode::Mul(op) => format!("    imul {}", op.to_str()),
                Opcode::Div(op) => format!("    idiv {}", op.to_str()),
                Opcode::Neg(op) => format!("    neg {}", op.to_str()),
                Opcode::Not(op) => format!("    not {}", op.to_str()),

                Opcode::Pop(op) => format!("    pop {}", op.to_str()),
                Opcode::Push(op) => format!("    push {}", op.to_str()),

                Opcode::Cdq => "    cdq".to_string(),
            };
            line.push('\n');
            file.write_all(&line.bytes().collect::<Vec<_>>())?;
        }

        file.write_all(b"    mov rax, 0\n    ret\nsection .data\n    ifmt: db \"%d\", 10, 0")?;

        Ok(())
    }

    pub fn compile(stmts: Vec<Stmt<'s>>) -> Result<(), CompileError> {
        let mut compiler = Compiler::new();

        for stmt in stmts {
            compiler.compile_stmt(stmt)?;
        }

        compiler.emit_asm().map_err(|_| CompileError::new("unable to emit asm"))
    }
}

