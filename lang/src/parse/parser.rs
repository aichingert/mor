use crate::{MStruct, Stmt, Token, TokenKind, m_error};

fn is_func(pos: usize, toks: &[Token]) -> bool {
    let func = toks[pos].kind == TokenKind::Literal
        && toks[pos + 1].kind == TokenKind::DbColon
        && toks[pos + 2].kind == TokenKind::LParen
        && {
            let mut mov = pos + 3;

            while toks[mov].kind != TokenKind::EOF && toks[mov].kind != TokenKind::RParen {
                mov += 1;
            }

            toks[mov].kind != TokenKind::EOF && toks[mov + 1].kind == TokenKind::LBrace
        };
    let method = false;

    func || method
}

fn is_struct(pos: usize, toks: &[Token]) -> bool {
    toks[pos].kind == TokenKind::Literal
        && toks[pos + 1].kind == TokenKind::DbColon
        && toks[pos + 2].kind == TokenKind::KwStruct
}

fn process_func<'a>(pos: &mut usize, toks: &'a [Token]) -> Stmt<'a> {
    *pos += 1;
    Stmt::Function
}

fn process_struct<'a>(pos: &mut usize, toks: &'a [Token]) -> Stmt<'a> {
    let mut s = MStruct { ident: &toks[*pos] };
    *pos += 4;

    while toks[*pos].kind != TokenKind::RBrace {
        todo!("implement parse struct");
    }

    *pos += 1;
    Stmt::Struct(s)
}

fn process_stmt<'a>(pos: &mut usize, source: &'a str, toks: &'a [Token]) -> Stmt<'a> {
    Stmt::Function
}

pub fn process<'a>(source: &'a str, toks: &'a [Token]) -> Vec<Stmt<'a>> {
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
                if is_func(pos, toks) {
                    process_func(&mut pos, toks)
                } else if is_struct(pos, toks) {
                    process_struct(&mut pos, toks)
                } else {
                    todo!("parse global declare")
                }
                /* TODO: else if with condition and else with m_error
                    format_err(
                        source,
                        &[TokenKind::KwStruct, TokenKind::LParen],
                        &toks[pos + 2],
                    ),
                */
            }
            TokenKind::EOF => return stmts,
            _ => format_err(source, &[TokenKind::Literal], &toks[pos]),
        });
    }

    unreachable!("has to hit eof");
}

fn format_err(source: &str, expected: &[TokenKind], tok: &Token) -> ! {
    let s = &source[tok.begin..tok.end];
    let err = if expected.len() == 1 {
        format!(
            "expected {:?} - found: {s:?} on line {}",
            expected[0], tok.line
        )
    } else {
        format!(
            "expected one of {:?} - found: {s:?} on line {}",
            expected, tok.line
        )
    };

    m_error!("mor: ", r "fatal error: ", err);
}

#[cfg(test)]
mod test {
    use super::*;

    use crate::parse::lexer;

    #[test]
    fn test_parser_struct_empty() {
        let source = "sv :: struct {}";
        let tokens = lexer::process(source);
        assert_eq!(process(source, &tokens), &[Stmt::Struct(MStruct {
            ident: &Token {
                begin: 0,
                end: 2,
                line: 0,
                kind: TokenKind::Literal
            }
        })]);
    }

    #[test]
    fn test_parser_struct_variables() {
        let source = "sv :: struct {\n\
                      data: i32;
                      len: i32 = 10;
        }";
        let tokens = lexer::process(source);
        assert_eq!(process(source, &tokens), &[]);
    }
}
