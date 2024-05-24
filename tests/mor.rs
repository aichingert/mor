use mor::*;

#[test]
fn lex_given_a_simple_calculation_then_expect_tokens() {
    let source = "1           +  2 *   3;";

    let result = Tokenizer::tokenize(source.as_bytes());
    let expect = vec![Token::Number("1"), Token::Plus, Token::Number("2"), Token::Star, Token::Number("3"), Token::Semicolon];

    assert_eq!(expect, result);
}

#[test]
fn par_given_a_simple_calculation_then_expect_ast() {
    let source = "1           +  2 *   3;";

    let result = parse(source.as_bytes());
    let expect = Some(vec![
        Stmt::Expr(
            Expr::BiOp(
                Box::new(BiOpEx { 
                    kind: BiOpKind::Add, 
                    children: [
                        Expr::Number("1"), 
                        Expr::BiOp(Box::new(BiOpEx { 
                            kind: BiOpKind::Mul, 
                            children: [
                                Expr::Number("2"), 
                                Expr::Number("3")
                            ] 
                        }))
                    ] 
                })
            )
        )
    ]);

    assert!(result.is_some());
    assert_eq!(expect, result);
}
