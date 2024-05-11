use crate::ast::*;

pub struct Tokenizer<'t> {
    source: &'t [u8],
    cursor: usize,

    tokens: Vec<Token<'t>>,
}

#[derive(Debug, Copy, Clone, Eq, PartialEq)]
pub enum Token<'t> {
    Number(&'t str),

    Plus,
    Minus,

    Star,
    Slash,

    LParen,
    RParen,
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
    fn tokenize(source: &'t [u8]) -> Vec<Token<'t>> {
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

    fn run(&mut self) {
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
            '(' => mk_tok!(Token::LParen),
            ')' => mk_tok!(Token::RParen),
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

pub struct Parser<'p, 't> {
    tokens: &'p [Token<'t>],
    cursor: usize,
}

impl<'p, 't> Parser<'p, 't> {
    fn new(tokens: &'p [Token<'t>]) -> Self {
        Self { tokens, cursor: 0 }
    }

    fn peek(&self, off: usize) -> Option<&Token<'t>> {
        self.tokens.get(self.cursor + off)
    }

    fn next(&mut self) -> Option<&Token<'t>> {
        self.cursor += 1;
        self.tokens.get(self.cursor - 1)
    }

    fn expect_next(&mut self, token: &Token<'t>) {
        if let Some(tok) = self.next() {
            if tok == token { return; }
            panic!("expected token of type: {token:?} but found {tok:?}!");
        }

        panic!("expected token of type: {token:?} but found nothing!");
    }

    fn parse_leading_expr(&mut self, prec: u16) -> Option<Expr<'t>> {
        let tok = self.next()?;

        match tok {
            Token::Number(n) => Some(Expr::Number(n)),
            Token::LParen    => {
                let expr = self.parse_expr(0)?;
                self.expect_next(&Token::RParen);
                Some(Expr::SubExpr(Box::new(expr)))
            }
            _ => None,
        }
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
