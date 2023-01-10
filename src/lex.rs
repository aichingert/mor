#[derive(Debug,Clone)]
pub enum Token<'a> {
    StringLit(String),
    Var(String),
    Assign,
}

pub struct Lexer<'a> {
    chars: std::iter::Peekable<std::str::Chars<'a>>,
    pub tokens: Vec<Token<'a>>
}

impl<'a> Lexer<'a> {
    fn new(code: &'a str) -> Self {
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
            
        }
    }
}
