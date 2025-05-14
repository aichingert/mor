pub mod parse;

#[derive(Debug, PartialEq, Eq, Copy, Clone)]
pub enum TokenKind {
    Literal,
    Numeral,

    LParen,
    RParen,
    LBrace,
    RBrace,
    LBracket,
    RBracket,
    Colon,
    ColonEq,
    SemiColon,
    DbColon,
    Comma,
    Arrow,
    Dot,
    Star,
    Plus,
    Minus,
    Slash,
    Eq,
    MinusEq,
    PlusEq,

    KwSelf,
    KwStruct,
    KwReturn,

    EOF,
    Unknown,
}

#[derive(Debug, PartialEq, Eq)]
pub struct Token {
    begin: usize,
    end: usize,
    line: u32,
    kind: TokenKind,
}

#[macro_export]
macro_rules! m_error {
    ($s:expr)   => {
        println!("{}", $s);
        std::process::exit(1);
    };
    (r $s:expr) => {
        println!("{}", format!("\x1b[31m{}\x1b[0m", $s));
        std::process::exit(1);
    };
    ($s:expr, r $($r:expr),+) => {
        print!("{}", $s); m_error!(r $($r),+);
    };
    ($s:expr, $($r:expr),+) => {
        print!("{}", $s); m_error!($($r),+);
    };
    (r $s:expr, $($r:expr),+) => {
        print!("{}", format!("\x1b[31m{}\x1b[0m", $s)); m_error!($($r),+);
    };
    (r $s:expr, r $($r:expr),+) => {
        print!("{}", format!("\x1b[31m{}\x1b[0m", $s)); m_error!(r $($r),+);
    };
}
