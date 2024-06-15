use crate::{Operand, RegSize};

#[derive(Debug)]
pub enum OpKind {
    Lbl(String),

    Jmp(String, String),
    Cmp(Operand, Operand),

    Or(Operand, Operand),
    And(Operand, Operand),

    Lea(Operand, Operand),
    Mov(Operand, Operand),
    Add(Operand, Operand),
    Sub(Operand, Operand),
    Xor(Operand, Operand),

    Div(Operand),
    Mul(Operand),

    Not(Operand),
    Neg(Operand),

    Pop(Operand),
    Push(Operand),

    Cdq,
}

#[derive(Debug)]
pub struct Opcode {
    kind: OpKind,
    size: RegSize,
}

impl Opcode {
    #[inline]
    pub fn u64(kind: OpKind) -> Self {
        Self { kind, size: RegSize::R }
    }
}

