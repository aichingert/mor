#[derive(Debug, Clone, Copy)]
pub enum RegKind {
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
pub enum RegSize {
    R, // 64 bit
    E, // 32 bit
    X, // 16 bit
    H, // 8  bit high
    L, // 8  bit low
    B, // 8  bit low => for R12, etc.
}

#[derive(Debug, Clone, Copy)]
pub struct Register {
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
            (RegKind::BP, RegSize::R) => "rbp",
            (RegKind::DI, RegSize::R) => "rdi",
            (RegKind::SI, RegSize::R) => "rsi",
            (RegKind::R8, RegSize::R) => "r8",
            (RegKind::R9, RegSize::R) => "r9",
            _ => todo!(),
        }
    }
}

#[derive(Debug, Clone)]
pub enum Operand {
    Reg(Register),  // ex: mov !rax!, 1
    Val(Register),  // ex: mov rbx, ![rax]!
    Implicit,       // TODO
    Immediate(i64), // ex: mov rax, !1!
    Direct(i64),    // ex: mov rax, ![0x1234]!
    // TODO: not sure if this is needed - difference to indexed comes from the past where only
    Based(Register, i32),
    Indexed(Register, Box<Operand>), // ex: mov rax, ![rsp + 8]!
}

impl Operand {
    fn to_str(&self) -> String {
        match self {
            Operand::Reg(reg) => reg.to_str().to_string(),
            Operand::Val(reg) => format!("[{}]", reg.to_str()),
            Operand::Immediate(val) => format!("{val}"),
            Operand::Indexed(reg, off) => format!("qword [{} + {}]", reg.to_str(), off.to_str()),
            _ => todo!(),
        }
    }

    #[inline]
    pub fn rax() -> Self {
        Self::Reg(Register { kind: RegKind::A, size: RegSize::R })
    }

    #[inline]
    pub fn rdx() -> Self {
        Self::Reg(Register { kind: RegKind::D, size: RegSize::R })
    }
    
    #[inline]
    pub fn rcx() -> Self {
        Self::Reg(Register { kind: RegKind::C, size: RegSize::R })
    }

    #[inline]
    pub fn reg(kind: RegKind, size: RegSize) -> Self {
        Self::Reg(Register { kind, size })
    }

    #[inline]
    pub fn indexed(kind: RegKind, size: RegSize, idx: Operand) -> Self {
        Self::Indexed(Register { kind, size }, Box::new(idx))
    }
}
