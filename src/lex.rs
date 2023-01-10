#[derive(Debug,Clone)]
pub enum Token {
    StringLit(String),
    Var(String),
    Assign,
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
                _ => {}
            }
        }
    }
}
