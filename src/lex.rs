#[derive(Debug,Clone, PartialEq, Eq, PartialOrd, Ord)]
pub enum Token {
    StringLit(String),
    Indent(String),
    If,
    Else,
    Assign,
	LParen,
	RParen,
}

pub struct Lexer<'a> {
    chars: std::iter::Peekable<std::str::Chars<'a>>,
    pub tokens: Vec<Token>
}

impl<'a> Lexer<'a> {
    pub fn new(code: &'a str) -> Self {
        Lexer {
            chars: code.chars().peekable(),
            tokens: Vec::new()
        }
    }

    fn peek(&mut self) -> Option<&char> {
        self.chars.peek()
    }

    fn next(&mut self) -> Option<char> {
        self.chars.next()
    }

    pub fn lex(&mut self) {
        while let Some(ch) = self.next() {
            match ch {
                '"' => {
                    let mut acc: String = String::new();
                    while self.peek() != Some(&ch) {
                        match self.next() {
                            Some(c) => acc.push(c),
                            None => panic!("String doesn't end"),
                        }
                    }
                    self.next();
                    self.tokens.push(Token::StringLit(acc));
                },
                ' ' | '\n' => {},
				'(' => self.tokens.push(Token::LParen),
				')' => self.tokens.push(Token::RParen),
                ch => {
                    let mut acc: String = ch.to_string();

                    if ch.is_alphabetic() {
                        while self.peek() != Some(&' ') {
                            match self.next() {
                                Some(c) => acc.push(c),
                                None => panic!("Hit eof"),
                            }
                        }

                        match acc.as_str() {
                            "if" => self.tokens.push(Token::If),
                            "else" => self.tokens.push(Token::Else),
                            _ => self.tokens.push(Token::Indent(acc))
                        }

                        self.next();
                    } else {
                        while self.peek() != Some(&' ') {
                            match self.next() {
                                Some(c) => acc.push(c),
                                None => panic!("Hit eof"),
                            }
                        }

                        match acc.as_str() {
                            "=" => self.tokens.push(Token::Assign),
                            _ => self.tokens.push(Token::Indent(acc)),
                        }

                        self.next();
                    }
                }
            }
        }
    }
}
