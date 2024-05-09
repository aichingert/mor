use std::io::Write;

type N = f64;

enum Instr {
    Add(N),
}

struct Tokenizer<'t> {
    source: &'t [u8],
    cursor: usize,

    tokens: Vec<Token<'t>>,
}

enum Token<'t> {
    Number(&'t str),

    Plus,
    Minus,

    Star,
    Slash,
}

impl<'t> Token<'t> {
    fn try_biop(&self) -> Option<BiOpKind> {
        match self {
            Token::Plus => Some(BiOpKind::Add),
            Token::Minus => Some(BiOpKind::Sub),
            Token::Star => Some(BiOpKind::Mul),
            Token::Slash => Some(BiOpKind::Div),
            _ => None,
        }
    }
}

impl<'t> Tokenizer<'t> {
    pub fn tokenize(source: &'t [u8]) -> Vec<Token<'t>> {
        let mut tokenizer = Self::new(source);
        tokenizer.run();
        tokenizer.tokens
    }

    fn new(source: &'t[u8]) -> Self {
        Self {
            source,
            cursor: 0,

            tokens: Vec::new(),
        }
    }

    fn peek_ch(&self, off: usize) -> Option<u8> {
        self.source.get(self.cursor + off).copied()
    }

    fn consume_ch(&mut self, n: usize) {
        self.cursor += n;
    }

    fn consume_ch_while<P: Fn(char) -> bool>(&mut self, pred: P) {
        while self.peek_ch(0).is_some_and(|b| pred(b as char)) {
            self.consume_ch(1);
        }
    }

    pub fn run(&mut self) {
        while let Some(tok) = self.next_token() {
            self.tokens.push(tok);
        }
    }

    fn next_token(&mut self) -> Option<Token<'t>> {
        self.consume_ch_while(|c| c == ' ');

        macro_rules! mk_tok {
            ($td: expr) => {{
                self.consume_ch(1);
                return Some($td);
            }};
        }

        let at = self.peek_ch(0)?;

        match at as char {
            '+' => mk_tok!(Token::Plus),
            '-' => mk_tok!(Token::Minus),
            '*' => mk_tok!(Token::Star),
            '/' => mk_tok!(Token::Slash),
            _ => (),
        }

        let src = self.cursor;

        if at.is_ascii_digit() {
            self.consume_ch_while(|c| c.is_ascii_digit());

            let value = &self.source[src..self.cursor];
            let value = unsafe { core::str::from_utf8_unchecked(value) };
            return Some(Token::Number(value));
        }

        self.consume_ch(1);
        None
    }
}

#[derive(Debug)]
enum Expr<'e> {
    Number  (&'e str),
    UnOp    (Box<UnOpEx<'e>>),
    BiOp    (Box<BiOpEx<'e>>),
}

#[derive(Debug)]
enum UnOpKind {
    Not,
    Negate,
}

#[derive(Debug)]
struct UnOpEx<'u> {
    kind: UnOpKind,
    child: Expr<'u>,
}

#[derive(Debug)]
enum BiOpKind {
    Add,
    Sub,
    Mul,
    Div,
}

impl BiOpKind {
    fn lprec(&self) -> u16 {
        match self {
            BiOpKind::Add => 100,
            BiOpKind::Sub => 100,
            BiOpKind::Mul => 200,
            BiOpKind::Div => 200,
        }
    }
    
    fn rprec(&self) -> u16 {
        match self {
            BiOpKind::Add => 101,
            BiOpKind::Sub => 101,
            BiOpKind::Mul => 201,
            BiOpKind::Div => 201,
        }
    }
}

#[derive(Debug)]
struct BiOpEx<'b> {
    kind: BiOpKind,
    children: [Expr<'b>; 2],
}

struct Parser<'p, 't> {
    tokens: &'p [Token<'t>],
    cursor: usize,
}

impl<'p, 't> Parser<'p, 't> {
    pub fn new(tokens: &'p [Token<'t>]) -> Self {
        Self { tokens, cursor: 0 }
    }

    fn peek(&self, off: usize) -> Option<&Token<'t>> {
        self.tokens.get(self.cursor + off)
    }

    fn next(&mut self) -> Option<&Token<'t>> {
        self.cursor += 1;
        self.tokens.get(self.cursor - 1)
    }

    fn parse_leading_expr(&mut self, prec: u16) -> Option<Expr<'t>> {
        let tok = self.next()?;

        if let Token::Number(n) = tok {
            return Some(Expr::Number(n));
        }

        None
    }

    fn parse_expr(&mut self, prec: u16) -> Option<Expr<'t>> {
        let mut res = self.parse_leading_expr(prec)?;

        loop {
            let Some(cur) = self.peek(0) else { break; };

            if let Some(biop) = cur.try_biop() {
                if biop.lprec() >= prec {
                    self.next()?; // operator

                    let other = self.parse_expr(biop.rprec())?;
                    res = Expr::BiOp(Box::new(BiOpEx {
                        kind: biop,
                        children: [res, other],
                    }));
                    continue;
                }
            }

            break;
        }

        Some(res)
    } 
}

pub fn parse_single<'t>(source: &'t [u8]) -> Option<Expr<'t>> {
    let tokens = Tokenizer::tokenize(source);
    let mut p = Parser::new(&tokens);
    p.parse_expr(0)
}

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
            Expr::UnOp(ex) => (), // TODO: implement unary ops
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

fn main() -> std::io::Result<()> {
    let Some(file) = std::env::args().into_iter().nth(1) else {
        println!("lang: \x1b[31mfatal error\x1b[0m: no input files");
        std::process::exit(1);
    };

    let source = std::fs::read_to_string(file)?;
    let ast = parse_single(source.as_bytes()).unwrap();

    println!("{ast:?}");

    Compiler::new().compile(ast);

    Ok(())
}
