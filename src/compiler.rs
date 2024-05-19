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
            Register::R12 => "r12",
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
    Lbl(String),
    Jmp(String, String),

    Cmp(Operand, Operand),

    Lea(Operand, Operand),
    Mov(Operand, Operand),
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
    pub fn new(msg: &str) -> CompileError {
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
    ifs: i32, 

    text: Vec<Opcode>, // section
    locals: HashMap<String, i32>,
}

const PTR:   u16 = 0x1;
const DEREF: u16 = 0x2;

impl<'s> Compiler {
    fn new() -> Self {
        Self { 
            rsp: 0, 
            ifs: 0,

            text: Vec::new(),
            locals: HashMap::new(),
        }
    }

    fn compile_expr(&mut self, expr: Expr<'s>, mut flags: u16) -> Result<(), CompileError> {
        let opcode = match expr {
            Expr::Number(num) => Opcode::Mov(Operand::Reg(Register::RAX), Operand::Immediate(num.parse().map_err(|_| CompileError::new("Number too big"))?)),
            Expr::Ident(Ident { value }) => {
                let Some(offset) = self.locals.get(value) else { return Err(CompileError::new("Ident: not found")); };
                let (mut op1, mut op2) = (Operand::Reg(Register::RAX), Operand::Indexed(Register::RSP, self.rsp - offset));

                // TODO: fix wrong deref in the second case -> *d = &a | a = *d
                if flags & DEREF == DEREF {
                    self.text.push(Opcode::Lea(Operand::Reg(Register::RCX), op2));
                    (op1, op2) = (Operand::Reg(Register::RAX), Operand::Indexed(Register::RCX, 0));
                }

                match flags & PTR == PTR {
                    true  => { Opcode::Lea(op1, op2) },
                    false => { Opcode::Mov(op1, op2) }
                }
            }
            Expr::UnOp(unexpr) => {
                let child = unexpr.child;
                flags |= unexpr.kind as u16;
                self.compile_expr(child, flags)?;

                match unexpr.kind {
                    UnOpKind::Neg => Opcode::Neg(Operand::Reg(Register::RAX)),
                    UnOpKind::Not => Opcode::Not(Operand::Reg(Register::RAX)),
                    UnOpKind::Ref | UnOpKind::Deref => return Ok(()),
                }
            }
            Expr::BiOp(biexpr) => {
                let [a, b] = biexpr.children;
                if biexpr.kind == BiOpKind::Set { flags |= PTR; }
                self.compile_expr(b, flags)?;
                self.text.push(Opcode::Mov(Operand::Reg(Register::RDX), Operand::Reg(Register::RAX)));
                self.compile_expr(a, flags)?;

                match biexpr.kind {
                    BiOpKind::Add => Opcode::Add(Operand::Reg(Register::RAX), Operand::Reg(Register::RDX)),
                    BiOpKind::Sub => Opcode::Sub(Operand::Reg(Register::RAX), Operand::Reg(Register::RDX)),
                    BiOpKind::Mul => Opcode::Mul(Operand::Reg(Register::RDX)),
                    BiOpKind::Set => Opcode::Mov(Operand::Indexed(Register::RAX, 0), Operand::Reg(Register::RDX)),
                    BiOpKind::Div => {
                        self.text.push(Opcode::Cdq);
                        Opcode::Div(Operand::Reg(Register::RDX))
                    }
                    BiOpKind::CmpEq | BiOpKind::CmpNe | BiOpKind::CmpLt | BiOpKind::CmpLe | BiOpKind::CmpGt | BiOpKind::CmpGe => {
                        self.text.push(Opcode::Cmp(Operand::Reg(Register::RDX), Operand::Reg(Register::RAX)));
                        Opcode::Jmp(biexpr.kind.to_jmp()?, format!("i{}", self.ifs))
                    }
                    BiOpKind::BoOr => {
                        // TODO: maybe rework this as it seems like a huge hack
                        let len = self.text.len();
                        self.ifs += 1;

                        if let Some(&mut Opcode::Jmp(_, ref mut lbl)) = self.text.get_mut(len - 1) {
                            lbl.clear();
                            lbl.push_str(&format!("i{}", self.ifs));
                        }

                        if let Some(&mut Opcode::Jmp(ref mut jmp, _)) = self.text.get_mut(len - 7) {
                            println!("and again");
                            let rev = match jmp.as_str() {
                                "je"    => "jne",
                                "jne"   => "je",
                                "jl"    => "jge",
                                "jle"   => "jg",
                                "jg"    => "jle",
                                "jge"   => "jl",
                                _ => return Err(CompileError::new("Implement rev jmp")),
                            };

                            jmp.clear();
                            jmp.push_str(rev);
                        }
                        Opcode::Lbl(format!("i{}:", self.ifs - 1))
                    }
                    BiOpKind::BoAnd => return Ok(()),
                    _ => todo!()
                }
            }
            Expr::SubExpr(expr) => return self.compile_expr(*expr, flags),
            Expr::If(if_expr)   => {
                self.compile_expr(if_expr.condition, flags)?;
                if_expr.on_true.into_iter().try_for_each(|stmt| self.compile_stmt(stmt))?;

                if let Some(else_branch) = if_expr.on_false {
                    self.text.push(Opcode::Jmp("jmp".to_string(), format!("i{}", self.ifs + 1)));
                    self.text.push(Opcode::Lbl(format!("i{}:", self.ifs)));
                    self.ifs += 1;
                    else_branch.into_iter().try_for_each(|stmt| self.compile_stmt(stmt))?;
                }

                self.ifs += 1;
                Opcode::Lbl(format!("i{}:", self.ifs - 1))
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

        self.text.push(Opcode::Push(Operand::Reg(Register::RAX)));
        self.rsp += 8;

        Ok(())
    }

    fn compile_stmt(&mut self, stmt: Stmt<'s>) -> Result<(), CompileError> {
        match stmt {
            Stmt::Expr(ex)   => self.compile_expr(ex, 0),
            Stmt::Local(loc) => self.compile_local(loc),
        }
    }

    fn emit_asm(self) -> Result<(), Box<dyn std::error::Error>> {
        let mut file = std::fs::File::create("prog.asm")?;
        file.write_all(b"section .text\n  global main\nmain:\n")?;

        for opcode in self.text.into_iter() {
            let mut line = match opcode {
                Opcode::Lbl(lbl) => lbl,

                Opcode::Jmp(ki, lbl) => format!("    {ki} {lbl}"),
                Opcode::Cmp(op1, op2) => format!("    cmp {}, {}", op1.to_str(), op2.to_str()),
                Opcode::Lea(op1, op2) => format!("    lea {}, {}", op1.to_str(), op2.to_str()),
                Opcode::Mov(op1, op2) => format!("    mov {}, {}", op1.to_str(), op2.to_str()),
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

        file.write_all(b"    mov rdi, rax\n")?;
        file.write_all(b"    mov rax, 60\n")?;
        file.write_all(b"    syscall\n")?;

        use std::process::Command;
        Command::new("nasm").args(["prog.asm", "-f", "elf64", "-o", "prog.o"]).output()?;
        Command::new("gcc").args(["-no-pie", "prog.o"]).output()?;
        Command::new("rm").args(["prog.o"]).output()?;

        Ok(())
    }

    pub fn compile(block: Block<'s>) -> Result<(), CompileError> {
        let mut compiler = Compiler::new();

        for stmt in block {
            compiler.compile_stmt(stmt)?;
        }

        compiler.emit_asm().map_err(|_| CompileError::new("unable to emit asm"))
    }
}

