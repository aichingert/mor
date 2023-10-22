#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum Token {
    Number(i64),

    Plus,
    Minus,
    Star,
    Slash,

    LParen,
    RParen,

    Invalid,
    Eof,
}

impl Token {
    pub fn get_unary_precedence(&self) -> u8 {
        match self {
            Token::Minus => 3,
            _ => 0,
        }
    }

    pub fn get_precedence(&self) -> u8 {
        match self {
            Token::Plus  => 1,
            Token::Minus => 1,
            Token::Star  => 2,
            Token::Slash => 2,
            Token::RParen => 0,
            Token::Eof => 0,
            _ => panic!("=> {:?} is not an operator!", self),
        }
    }
}
