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
