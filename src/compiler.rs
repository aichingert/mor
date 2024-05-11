use std::io::Write;

use crate::ast::*;

pub struct Compiler {
    text: Vec<String>,
    data: Vec<String>,
    bss:  Vec<String>,
}

fn ts(s:&str) -> String { s.to_string() }

impl<'ex> Compiler {
    pub fn new() -> Self {
        let conv = |v: Vec<&str>| {
            v.into_iter().map(|s| ts(s)).collect::<Vec<_>>()
        };

        let data = conv(vec!["segment    .data", "    result dd 0", ""]);
        let bss  = conv(vec!["segment    .bss", "    buffer resb 12 ; 4", ""]);
        let text = conv(vec!["segment    .text", "global     _start", "_start: "]);

        Self { text, data, bss }
    }

    fn compile_expr(&mut self, expr: Expr<'ex>) {
        match expr {
            Expr::BiOp(ex) => {
                let [a, b] = ex.children;

                self.compile_expr(a);
                self.compile_expr(b);

                self.text.push(ts("    pop ebx"));
                self.text.push(ts("    pop eax"));

                match ex.kind {
                    BiOpKind::Add => self.text.push(ts("    add eax, ebx")),
                    BiOpKind::Sub => self.text.push(ts("    sub eax, ebx")),
                    BiOpKind::Mul => self.text.push(ts("    imul bx")),
                    BiOpKind::Div => {
                        self.text.push(ts("    cdq"));
                        self.text.push(ts("    idiv ebx"));
                    }
                }

                self.text.push(ts("    push eax"));
            }
            Expr::UnOp(ex) => {
                self.compile_expr(ex.child);
                self.text.push(ts("    pop eax"));

                match ex.kind {
                    UnOpKind::Not => self.text.push(ts("   not eax")),
                    UnOpKind::Neg => self.text.push(ts("   neg eax")),
                }

                self.text.push(ts("    push eax"));
            }
            Expr::SubExpr(ex) => self.compile_expr(*ex),
            Expr::Number(num) => {
                self.text.push(format!("    push {num}"));
            }
        }
    }

    pub fn compile(&mut self, expr: Expr<'ex>) {
        self.compile_expr(expr);
        self.text.push(ts("    pop eax"));
        self.text.push(ts("    mov [result], eax"));
        self.text.push(ts("    push ecx"));

        self.text.push(ts(""));
        self.text.push(ts("    mov ecx, [result]"));
        self.text.push(ts("    push ecx"));
        self.text.push(ts(""));
        self.text.push(ts("    lea esi, [buffer]"));
        self.text.push(ts("    mov eax, [result]"));
        self.text.push(ts("    call int_to_string"));
        self.text.push(ts(""));
        self.text.push(ts("    mov ecx, eax"));
        self.text.push(ts("    xor edx, edx"));
        self.text.push(ts("getlen:"));
        self.text.push(ts("    cmp byte [ecx + edx], 10"));
        self.text.push(ts("    jz gotlen"));
        self.text.push(ts("    inc edx"));
        self.text.push(ts("    jmp getlen"));
        self.text.push(ts("gotlen:"));
        self.text.push(ts("    inc edx"));
        self.text.push(ts(""));
        self.text.push(ts("    mov eax, 4"));
        self.text.push(ts("    mov ebx, 1"));
        self.text.push(ts("    int 0x80"));
        self.text.push(ts(""));
        self.text.push(ts("    pop ecx"));
        self.text.push(ts(""));
        self.text.push(ts("    mov eax, 1"));
        self.text.push(ts("    mov ebx, 0"));
        self.text.push(ts("    int 0x80"));
        self.text.push(ts(""));

        self.text.push(ts("    mov eax, 1"));
        self.text.push(ts("    xor ebx, ebx"));
        self.text.push(ts("    int 0x80"));
        self.text.push(ts(""));

        self.text.push(ts("int_to_string:"));
        self.text.push(ts("    add esi, 9"));
        self.text.push(ts("    mov byte [esi], 10"));
        self.text.push(ts("    mov ebx, 10"));
        self.text.push(ts(".next_digit:"));
        self.text.push(ts("    xor	edx, edx"));
        self.text.push(ts("    div	ebx"));
        self.text.push(ts("    add	dl, '0'"));
        self.text.push(ts("    dec	esi"));
        self.text.push(ts("    mov	[esi],dl"));
        self.text.push(ts("    test	eax, eax"));
        self.text.push(ts("    jnz	.next_digit"));
        self.text.push(ts("    mov	eax, esi"));
        self.text.push(ts("    ret"));

        let mut file = std::fs::File::create("prog.asm").unwrap();
        file.write_all(&self.data.join("\n").bytes().collect::<Vec<_>>()).unwrap();
        file.write_all(&self.bss.join("\n").bytes().collect::<Vec<_>>()).unwrap();
        file.write_all(&self.text.join("\n").bytes().collect::<Vec<_>>()).unwrap();

        std::process::Command::new("nasm")
            .args(["-f", "elf32", "prog.asm"])
            .output().unwrap();
        std::process::Command::new("ld")
            .args(["-m", "elf_i386", "-o", "prog", "prog.o"])
            .output().unwrap();
    }
}


