#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum Token {
    Number(i64),

    Plus,
    Minus,
    Star,
    Slash,

    Invalid,
    Eof,
}

impl Token {
    pub fn get_precedence(&self) -> u8 {
        match self {
            Token::Plus  => 1,
            Token::Minus => 1,
            Token::Star  => 2,
            Token::Slash => 2,
            Token::Eof => 0,
            _ => panic!("=> {:?} is not an operator!", self),
        }
    }
}
