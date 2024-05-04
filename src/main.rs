use std::io::{self, BufRead};
use std::iter::Peekable;

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
        while self.peek_ch(1).is_some_and(|b| pred(b as char)) {
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

enum Expr<'e> {
    Number  (&'e str),
    UnOp    (Box<UnOpEx<'e>>),
    BiOp    (Box<BiOpEx<'e>>),
}

enum UnOpKind {
    Not,
    Negate,
}

struct UnOpEx<'u> {
    kind: UnOpKind,
    child: Expr<'u>,
}

enum BiOpKind {
    Add,
    Sub,
    Mul,
    Div,
}

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

    fn parse_expr(&mut self, prec: u32) -> Option<Expr<'t>> {

        Some(Expr::Number(""))
    } 
}

pub fn parse_single<'t>(source: &'t [u8]) -> Expr<'t> {
    let tokens = Tokenizer::tokenize(source);
    Expr::Number("")
}

fn main() {
    let Some(file) = std::env::args().into_iter().nth(1) else {
        println!("lang: \x1b[31mfatal error\x1b[0m: no input files");
        std::process::exit(1);
    };


}
