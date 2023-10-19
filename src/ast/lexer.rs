use crate::ast::token::Token;


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
        let mut base: i64 = 1;
        let mut lit:  i64 = 0;

        while self.loc < self.source.len() && self.source[self.loc].is_alphanumeric() {
            lit += (self.source[self.loc] as u8 - b'0') as i64 * base;
            base *= 10;
            self.loc += 1;
        }

        Token::Number(lit)
    }
}
