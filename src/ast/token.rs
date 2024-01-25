#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Token {
    // types
    Ident(String),
    Number(i64),
    Bool(bool),

    // ops
    Plus,
    Minus,
    Star,
    Slash,
    Power,

    Decl,
    Assign,
    Equal,

    // binary ops
    XOR,
    BitOr,
    BitAnd,

    // logical ops
    Or,
    And,
    Not,

    // scoping
    LParen,
    RParen,

    // Other
    Invalid,
    Eof,
}

impl Token {
    pub fn get_unary_precedence(&self) -> u8 {
        match self {
            Token::Minus => 3,
            Token::Not   => 3,
            _ => 0,
        }
    }

    pub fn get_precedence(&self) -> u8 {
        match self {
            Token::Plus  => 1,
            Token::Minus => 1,
            Token::Star  => 2,
            Token::Slash => 2,
            Token::Power => 2,
            Token::XOR   => 2,
            Token::Equal => 2,
            Token::And   => 2,
            Token::Or    => 2,
            Token::BitOr => 2,
            Token::BitAnd=> 2,
            Token::RParen => 0,
            Token::Eof => 0,
            _ => panic!("=> {:?} is not an operator!", self),
        }
    }
}
