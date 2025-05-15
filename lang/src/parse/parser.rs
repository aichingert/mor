use crate::{Stmt, Token, TokenKind, m_error};

fn process_struct(pos: &mut usize, toks: &[Token]) -> Stmt {
    *pos += 1;
    Stmt::Struct
}

fn process_function(pos: &mut usize, toks: &[Token]) -> Stmt {
    *pos += 1;
    Stmt::Function
}

fn format_err(source: &str, expected: &[TokenKind], tok: &Token) -> ! {
    let s = &source[tok.begin..tok.end];
    let err = if expected.len() == 1 { 
        format!("expected {:?} - found: {s:?} on line {}", expected[0], tok.line)
    } else {
        format!("expected one of {:?} - found: {s:?} on line {}", expected, tok.line)
    };
    
    m_error!("mor: ", r "fatal error: ", err);
}

pub fn process(source: &str, toks: &[Token]) -> Vec<Stmt> {
    // Statements
    //
    // Struct =>
    // | ident :: struct { ... }
    //
    // ----------
    // Declare =>
    // | ident : (type expr) :|: (type expr) = expr ;
    //
    // ----------
    // Function =>
    // | ident (. ident) :: ((*self), ident : type expr, *) (-> type expr) { ... }

    let mut pos = 0;
    let mut stmts = Vec::<Stmt>::new();

    while pos < toks.len() {
        stmts.push(match toks[pos].kind {
            TokenKind::Literal => {
                if toks[pos + 1].kind != TokenKind::Dot && toks[pos + 1].kind != TokenKind::DbColon {
                    format_err(source, &[TokenKind::DbColon], &toks[pos + 1]);
                }

                match toks[pos + 2].kind {
                    TokenKind::KwStruct => process_struct(&mut pos, toks),
                    TokenKind::Literal | TokenKind::LParen => process_function(&mut pos, toks),
                    _ => {
                        let kinds = [TokenKind::KwStruct, TokenKind::Literal, TokenKind::LParen];
                        format_err(source, &kinds, &toks[pos + 2]);
                    },
                }
            }
            TokenKind::EOF => return stmts,
            _ => format_err(source, &[TokenKind::Literal], &toks[pos]),
        });
    }

    unreachable!("has to hit eof");
}
