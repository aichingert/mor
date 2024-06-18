use crate::{Block, Opcode, Operand, OpKind};

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
    main: Vec<Opcode>,
    main_rsp: i64,
    main_lbl: i64,

    func: Vec<Vec<Opcode>>,
    func_rsp: i64,
    func_lbl: i64,
}

impl<'s> Compiler {
    fn new() -> Self {
        Self {
            main: Vec::new(),
            main_rsp: 0,
            main_lbl: 0,

            func: Vec::new(),
            func_rsp: 0,
            func_lbl: 0,
        }
    }

    #[inline]
    pub fn push_rax(&mut self, ptr: usize) {
        self.push(ptr, Operand::rax());
    }

    #[inline]
    pub fn pop_rax(&mut self, ptr: usize) {
        self.pop(ptr, Operand::rax());
    }

    #[inline]
    pub fn pop_rdx(&mut self, ptr: usize) {
        self.pop(ptr, Operand::rdx());
    }

    #[inline(always)]
    pub fn push(&mut self, ptr: usize, operand: Operand) {
        match ptr {
            0 => {
                self.main.push(Opcode::u64(OpKind::Push(operand)));
                self.main_rsp += 8;
            }
            _ => {
                self.func[ptr - 1].push(Opcode::u64(OpKind::Push(operand)));
                self.func_rsp += 8;
            }
        }
    }

    #[inline(always)]
    pub fn pop(&mut self, ptr: usize, operand: Operand) {
        match ptr {
            0 => {
                self.main.push(Opcode::u64(OpKind::Pop(operand)));
                self.main_rsp -= 8;
            }
            _ => {
                self.func[ptr - 1].push(Opcode::u64(OpKind::Pop(operand)));
                self.func_rsp -= 8;
            }
        }
    } 

    pub fn compile(block: Block<'s>) {
        let mut _compiler = Compiler::new();
    }
}
