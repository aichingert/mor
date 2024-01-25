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
            '!' => Token::Not,
            '&' => {
                if self.peek(1) == '&' {
                    self.loc += 1;
                    Token::And
                } else {
                    Token::BitAnd
                }
            }
            '|' => {
                if self.peek(1) == '|' {
                    self.loc += 1;
                    Token::Or
                } else {
                    Token::BitOr
                }
            }
            '/' => Token::Slash,
            '(' => Token::LParen,
            ')' => Token::RParen,
            '=' => {
                if self.peek(1) == '=' {
                    self.loc += 1;
                    Token::Equal
                } else {
                    Token::Assign
                }
            }
            ':' if self.peek(1) == '=' => { self.loc += 1; Token::Decl }
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

        while self.loc < self.source.len() && self.source[self.loc].is_alphanumeric() {
            acc.push(self.source[self.loc]);
            self.loc += 1;
        }

        match acc.as_str() {
            "true" | "false" => Token::Bool(acc.as_str() == "true"),
            _ => Token::Ident(acc),
        }
    }

    fn consume_number(&mut self) -> Token {
        let src = self.loc;

        while self.loc + 1 < self.source.len() && self.source[self.loc + 1].is_numeric() {
            self.loc += 1;
        }

        let num = self.source[src..self.loc + 1].iter().collect::<String>();

        Token::Number(num.parse::<i64>().unwrap())
    }
}
