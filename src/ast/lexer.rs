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

    pub fn next_token(&mut self) -> Token {
        self.skip_whitespace();

        if self.loc >= self.source.len() {
            return Token::Eof;
        }

        let token = match self.source[self.loc] {
            '+' => Token::Plus,
            '-' => Token::Minus,
            '*' => Token::Star,
            '/' => Token::Slash,
            '(' => Token::LParen,
            ')' => Token::RParen,
            '0'..='9' => self.consume_number(),
            _ => Token::Invalid,
        };
        self.loc += 1;

        token
    }

    fn skip_whitespace(&mut self) {
        while self.loc < self.source.len() && self.source[self.loc] == ' ' {
            self.loc += 1;
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
