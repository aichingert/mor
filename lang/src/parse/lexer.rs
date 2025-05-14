use crate::{Token, TokenKind, m_error};

fn consume_token(
    pos: &mut usize,
    line: u32,
    bytes: &[u8],
    cond: fn(u8) -> bool,
    kind: TokenKind,
) -> Token {
    let begin = *pos;
    while cond(bytes[*pos]) {
        *pos += 1;
    }
    let end = *pos;

    Token {
        begin,
        end,
        line,
        kind,
    }
}

fn consume_single(pos: &mut usize, line: u32, kind: TokenKind) -> Token {
    *pos += 1;
    Token {
        begin: *pos - 1,
        end: *pos,
        line: line,
        kind: kind,
    }
}

fn consume_if(
    pos: &mut usize,
    line: u32,
    bytes: &[u8],
    next: &[(u8, TokenKind)],
    default: TokenKind,
) -> Token {
    *pos += 1;

    for (i, &(byte, kind)) in next.iter().enumerate() {
        if *pos < bytes.len() && byte == bytes[*pos] {
            *pos += 1;
            return Token {
                begin: *pos - 2,
                end: *pos,
                line: line,
                kind: kind,
            };
        }
    }

    Token {
        begin: *pos - 1,
        end: *pos,
        line: line,
        kind: default,
    }
}

pub fn process(source: &str) -> Vec<Token> {
    use TokenKind::*;
    let mut pos = 0;
    let mut line = 0;
    let bytes = source.as_bytes();
    let mut toks = Vec::new();

    while pos < bytes.len() {
        toks.push(match bytes[pos] {
            b'0'..=b'9' => consume_token(&mut pos, line, bytes, |c| c.is_ascii_digit(), Numeral),
            b'A'..=b'Z' | b'a'..=b'z' => consume_token(
                &mut pos,
                line,
                bytes,
                |c| c.is_ascii_alphanumeric() || c == b'_',
                Literal,
            ),
            b':' => consume_if(
                &mut pos,
                line,
                bytes,
                &[(b':', DbColon), (b'=', ColonEq)],
                Colon,
            ),
            b'.' => consume_single(&mut pos, line, Dot),
            b',' => consume_single(&mut pos, line, Comma),
            b';' => consume_single(&mut pos, line, SemiColon),
            b'=' => consume_single(&mut pos, line, Eq),
            b'+' => consume_if(&mut pos, line, bytes, &[(b'=', PlusEq)], Plus),
            b'-' => consume_if(&mut pos, line, bytes, &[(b'>', Arrow)], Minus),
            b'*' => consume_if(&mut pos, line, bytes, &[], Star),
            b'/' => consume_if(&mut pos, line, bytes, &[], Slash),
            b'{' => consume_single(&mut pos, line, LBrace),
            b'}' => consume_single(&mut pos, line, RBrace),
            b'(' => consume_single(&mut pos, line, LParen),
            b')' => consume_single(&mut pos, line, RParen),
            b' ' | b'\n' => {
                if bytes[pos] == b'\n' {
                    line += 1;
                }
                pos += 1;
                continue;
            }
            _ => {
                m_error!("mor: ", 
                    r "fatal error: ", 
                    "unknown symbol: '", 
                    (bytes[pos] as char), 
                    "' on line ", line);
            }
        });

        let last = toks.len() - 1;
        if toks[last].kind == TokenKind::Literal {
            match &source[toks[last].begin..toks[last].end] {
                "self" => toks[last].kind = TokenKind::KwSelf,
                "return" => toks[last].kind = TokenKind::KwReturn,
                "struct" => toks[last].kind = TokenKind::KwStruct,
                _ => (),
            }
        }
    }

    toks
}
