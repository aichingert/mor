use crate::ast::token::Token;

const BASE: i64 = 10;

pub struct Lexer {
    source: Vec<char>,
    loc: usize,
}

impl Lexer {
    pub fn new(source: Vec<char>) -> Self {
        Self {
            source,
            loc: 0,
        }
    }

    pub fn next_token(&mut self) -> Option<Token> {
        self.skip_whitespace();

        if self.loc >= self.source.len() {
            return None;
        }

        let token = match self.source[self.loc] {
            '+' => Token::Plus,
            '-' => Token::Minus,
            '*' => if self.peek(1) == '*' {
                self.loc += 1; 
                Token::Power
            } else {
                Token::Star
            },
            '^' => Token::XOR,
            '&' => Token::BitAnd,
            '|' => Token::BitOr,
            '/' => Token::Slash,
            '(' => Token::LParen,
            ')' => Token::RParen,
            '=' => Token::Assign,
            'A'..='Z' | 'a'..='z' => self.consume_ident(),
            '0'..='9' => self.consume_number(),
            _ => Token::Invalid,
        };

        self.loc += 1;
        Some(token)
    }

    fn peek(&self, offset: usize) -> char {
        if offset + self.loc > self.source.len() {
            println!("hhshh");
            return ' ';
        }

        self.source[self.loc + offset]
    }

    fn skip_whitespace(&mut self) {
        while self.loc < self.source.len() && self.source[self.loc] == ' ' {
            self.loc += 1;
        }
    }

    fn consume_ident(&mut self) -> Token {
        let mut acc = String::new();

        while self.loc + 1 < self.source.len() && self.source[self.loc].is_alphanumeric() {
            acc.push(self.source[self.loc]);
            self.loc += 1;
        }

        match acc.as_str() {
            "let" => Token::KwLet,
            _ => Token::Ident(acc),
        }
    }

    fn consume_number(&mut self) -> Token {
        let mut lit:  i64 = (self.source[self.loc] as u8 - b'0') as i64;

        while self.loc + 1 < self.source.len() && self.source[self.loc + 1].is_numeric() {
            let cur = (self.source[self.loc + 1] as u8 - b'0') as i64;

            lit = if cur == 0 {
                lit * BASE
            } else {
                lit * BASE + cur
            };

            self.loc += 1;
        }

        Token::Number(lit)
    }
}
