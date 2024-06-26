use crate::ast::*;

pub struct Tokenizer<'t> {
    source: &'t [u8],
    cursor: usize,

    tokens: Vec<Token<'t>>,
}

#[derive(Debug, Copy, Clone, Eq, PartialEq)]
pub enum Token<'t> {
    Ident(&'t str),
    Number(&'t str),

    // binops
    Plus,
    Minus,
    Star,
    Slash,

    Eq,
    Ne,
    Lt,
    Le,
    Gt,
    Ge,

    Or,
    And,

    BiOr,
    BiAnd,

    // unops
    Not,

    // sp
    Paren(char),
    Comma,
    Comment,
    Assign,
    Semicolon,

    // KW
    KwIf,
    KwElse,
    KwWhile,
    KwReturn,

    // types
    I08Type,
    I16Type,
    I32Type,
    I64Type,
}

impl<'t> Token<'t> {
    fn try_biop(&self) -> Option<BiOpKind> {
        match self {
            Token::Plus => Some(BiOpKind::Add),
            Token::Minus => Some(BiOpKind::Sub),
            Token::Star => Some(BiOpKind::Mul),
            Token::Slash => Some(BiOpKind::Div),
            Token::Assign => Some(BiOpKind::Set),

            Token::Or => Some(BiOpKind::BiOr),
            Token::And => Some(BiOpKind::BiAnd),
            Token::BiOr => Some(BiOpKind::BoOr),
            Token::BiAnd => Some(BiOpKind::BoAnd),

            Token::Eq => Some(BiOpKind::CmpEq),
            Token::Ne => Some(BiOpKind::CmpNe),
            Token::Lt => Some(BiOpKind::CmpLt),
            Token::Le => Some(BiOpKind::CmpLe),
            Token::Gt => Some(BiOpKind::CmpGt),
            Token::Ge => Some(BiOpKind::CmpGe),
            _ => None,
        }
    }

    fn try_unop(&self) -> Option<UnOpKind> {
        match self {
            Token::Not => Some(UnOpKind::Not),
            Token::Minus => Some(UnOpKind::Neg),
            _ => None,
        }
    }

    fn try_type(&self) -> Option<Self> {
        match self {
            Token::I08Type | Token::I16Type | Token::I32Type | Token::I64Type => Some(*self),
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

    fn new(source: &'t [u8]) -> Self {
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
            if Token::Comment != tok {
                self.tokens.push(tok);
            }
        }
    }

    fn next_token(&mut self) -> Option<Token<'t>> {
        self.consume_ch_while(|c| c == ' ' || c == '\n');

        macro_rules! mk_tok {
            ($td: expr) => {{
                self.consume_ch(1);
                return Some($td);
            }};
        }

        macro_rules! mk_tok2 {
            ($td1: expr, $nxt: expr, $td2: expr) => {{
                if self.peek_ch(1) == Some($nxt) {
                    self.consume_ch(2);
                    return Some($td2);
                } else {
                    self.consume_ch(1);
                    return Some($td1);
                }
            }};
        }

        let at = self.peek_ch(0)?;

        match at as char {
            '+' => mk_tok!(Token::Plus),
            '-' => mk_tok!(Token::Minus),
            '*' => mk_tok!(Token::Star),
            '|' => mk_tok2!(Token::Or, b'|', Token::BiOr),
            '&' => mk_tok2!(Token::And, b'&', Token::BiAnd),
            '>' => mk_tok2!(Token::Gt, b'=', Token::Ge),
            '<' => mk_tok2!(Token::Lt, b'=', Token::Le),
            '=' => mk_tok2!(Token::Assign, b'=', Token::Eq),
            '!' => mk_tok2!(Token::Not, b'=', Token::Ne),
            '(' | ')' | '{' | '}' | '[' | ']' => mk_tok!(Token::Paren(at as char)),
            ',' => mk_tok!(Token::Comma),
            ';' => mk_tok!(Token::Semicolon),
            '/' => {
                match self.peek_ch(1)? {
                    b'/' => {
                        self.consume_ch_while(|c| c != '\n');
                        self.consume_ch(1);
                    }
                    b'*' => loop {
                        self.consume_ch_while(|c| c != '*');

                        self.consume_ch(1);
                        if b'/' == self.peek_ch(0)? {
                            self.consume_ch(1);
                            break;
                        }
                    }
                    _ => mk_tok!(Token::Slash),
                }
                return Some(Token::Comment);
            }
            _ => (),
        }

        let src = self.cursor;

        if at.is_ascii_digit() {
            self.consume_ch_while(|c| c.is_ascii_digit());

            let value = &self.source[src..self.cursor];
            let value = unsafe { core::str::from_utf8_unchecked(value) };
            return Some(Token::Number(value));
        }

        if at.is_ascii_alphabetic() {
            self.consume_ch_while(|c| c.is_ascii_alphanumeric());

            let value = &self.source[src..self.cursor];
            let value = unsafe { core::str::from_utf8_unchecked(value) };

            match value {
                // KW
                "if" => return Some(Token::KwIf),
                "else" => return Some(Token::KwElse),
                "while" => return Some(Token::KwWhile),
                "return" => return Some(Token::KwReturn),

                // types
                "i8" => return Some(Token::I08Type),
                "i16" => return Some(Token::I16Type),
                "i32" => return Some(Token::I32Type),
                "i64" => return Some(Token::I64Type),
                _ => (),
            }

            return Some(Token::Ident(value));
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

    fn expect(&mut self, token: &Token<'t>) {
        if let Some(tok) = self.next() {
            if tok == token {
                return;
            }
            panic!("expected token of type: {token:?} but found {tok:?}!");
        }

        panic!("expected token of type: {token:?} but found nothing!");
    }
    
    fn expect_ident(&mut self) -> &'t str {
        if let Some(Token::Ident(id)) = self.next() {
            return id;
        }

        panic!("expected identifier");
    }

    fn expect_num(&mut self) -> i64 {
        if let Some(Token::Number(num)) = self.next() {
            return num.parse().unwrap();
        }

        panic!("expected number");
    }

    fn parse_leading_expr(&mut self) -> Option<Expr<'t>> {
        let tok = *self.next()?;

        match tok {
            Token::Ident(id) => return Some(Expr::Ident(id)),
            Token::Number(n) => return Some(Expr::Number(n.parse().ok()?)),
            Token::KwIf => return self.parse_if(),
            Token::KwWhile => return self.parse_while(),
            Token::KwReturn => return Some(Expr::Return(Box::new(self.parse_expr(0)?))),
            Token::Paren('(') => {
                let expr = self.parse_expr(0)?;
                self.expect(&Token::Paren(')'));
                return Some(Expr::SubExpr(Box::new(expr)));
            }
            _ => (),
        }

        if let Some(unop) = tok.try_unop() {
            return Some(Expr::UnOp(Box::new(UnOpEx {
                kind: unop,
                child: self.parse_leading_expr()?,
            })));
        }

        None
    }

    fn parse_expr(&mut self, prec: u16) -> Option<Expr<'t>> {
        let mut res = self.parse_leading_expr()?;

        loop {
            let Some(cur) = self.peek(0) else {
                break;
            };

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

            if Token::Paren('[') == *cur {
                self.next().unwrap();

                let idx = self.parse_expr(0)?;
                self.expect(&Token::Paren(']'));

                res = Expr::Index(Box::new(Index {
                    base: res,
                    index: idx,
                }));

                continue;
            }

            if Token::Paren('(') == *cur {
                self.next().unwrap();

                let mut args = Vec::new();
                while let Some(&at) = self.peek(0) {
                    if Token::Semicolon == at {
                        self.next().unwrap();
                        continue;
                    }
                    if Token::Paren(')') == at {
                        self.next().unwrap();
                        break;
                    }

                    args.push(self.parse_expr(0)?);
                }

                res = Expr::Call(Box::new(Call {
                    fun: res,
                    args,
                }));
            }

            break;
        }

        Some(res)
    }

    fn parse_var(&mut self) -> Option<Stmt<'t>> {
        let typ = self.next().copied();
        let name = self.expect_ident();

        if let Some(Token::Paren('(')) = self.peek(0) {
            return self.parse_fn(typ?, name);
        }

        let mut size = None;
        if let Some(Token::Paren('[')) = self.peek(0) {
            self.next().unwrap();
            size = Some(self.expect_num());
            self.expect(&Token::Paren(']'));
        }

        let mut value = None;
        if let Some(Token::Assign) = self.peek(0) {
            self.next().unwrap();
            value = Some(self.parse_expr(0)?);
        }

        Some(Stmt::Local(Local::new(name, size, typ, value)))
    }

    pub fn parse_fn(&mut self, typ: Token<'t>, name: &'t str) -> Option<Stmt<'t>> {
        let mut func = Func::new(typ, name);

        self.expect(&Token::Paren('('));

        while let Some(&at) = self.peek(0) {
            if Token::Semicolon == at {
                self.next().unwrap();
                continue;
            }
            if Token::Paren(')') == at {
                self.next().unwrap();
                break;
            }

            let Some(Stmt::Local(loc)) = self.parse_var() else { return None; };
            func.args.push(loc);
        }

        self.expect(&Token::Paren('{'));
        func.body = self.parse_block()?;

        Some(Stmt::Func(func))
    }

    pub fn parse_if(&mut self) -> Option<Expr<'t>> {
        let cond = self.parse_expr(0)?;
        self.expect(&Token::Paren('{'));
        let on_true = self.parse_block()?;
        let mut on_false = None::<Block<'t>>;

        if self.peek(0).is_some_and(|&tok| tok == Token::KwElse) {
            self.next().unwrap();
            self.expect(&Token::Paren('{'));
            on_false = Some(self.parse_block()?);
        }

        Some(Expr::If(Box::new(If {
            condition: cond,
            on_true,
            on_false,
        })))
    }

    pub fn parse_while(&mut self) -> Option<Expr<'t>> {
        let cond = self.parse_expr(0)?;
        self.expect(&Token::Paren('{'));
        let body = self.parse_block()?;

        Some(Expr::While(Box::new(While {
            condition: cond,
            body,
        })))
    }

    pub fn parse_block(&mut self) -> Option<Block<'t>> {
        let mut stmts = Vec::new();

        while let Some(&at) = self.peek(0) {
            match at {
                Token::Semicolon | Token::Paren('}') => {
                    self.next().unwrap();
                    if at == Token::Semicolon {
                        continue;
                    } else {
                        break;
                    }
                }
                _ => (),
            }

            stmts.push(if at.try_type().is_some() {
                self.parse_var()?
            } else {
                Stmt::Expr(self.parse_expr(0)?)
            })
        }

        Some(stmts)
    }
}

pub fn parse(source: &[u8]) -> Option<Block<'_>> {
    let tokens = Tokenizer::tokenize(source);
    let mut p = Parser::new(&tokens);
    p.parse_block()
}
