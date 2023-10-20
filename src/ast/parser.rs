use crate::ast::{Lexer, Token, BinaryExpr};

#[derive(Debug)]
pub struct Parser {
    tokens: Vec<Token>,
    loc: usize,
}

impl Parser {
    pub fn new(source: &String) -> Self {
        let mut lexer = Lexer::new(source.chars().collect::<Vec<_>>());
        let mut token = lexer.next_token();
        let mut tokens = vec![token];

        while token != Token::Eof {
            token = lexer.next_token();
            tokens.push(token);
        }

        Self {
            tokens,
            loc: 0,
        }
    }

    fn next_token(&mut self) -> Token {
        if self.loc + 1 >= self.tokens.len() {
            return self.tokens[self.tokens.len() - 1];
        }

        self.loc += 1;
        self.tokens[self.loc - 1]
    }

    fn peek(&self, offset: usize) -> Token {
        if self.loc + offset >= self.tokens.len() {
            return self.tokens[self.tokens.len() - 1];
        }

        self.tokens[self.loc + offset]
    }

    pub fn parse(&mut self) -> BinaryExpr { 
        let lhs = self.parse_primary_expression();
        self.parse_expression(lhs, 1)
    }

    fn parse_expression(&mut self, mut lhs: BinaryExpr, min_precedence: u8) -> BinaryExpr {
        let mut look_ahead= self.peek(0).get_precedence();

        while look_ahead >= min_precedence {
            let op = self.next_token();
            let mut rhs = self.parse_primary_expression();
            look_ahead = self.peek(0).get_precedence();

            let cur_precedence = op.get_precedence();

            while look_ahead > cur_precedence {
                rhs = self.parse_expression(rhs, cur_precedence + 1);
                look_ahead = self.peek(0).get_precedence();
            }

            lhs = BinaryExpr::Expr(Box::new(lhs), op, Box::new(rhs));
        }

        lhs
    }

    fn parse_primary_expression(&mut self) -> BinaryExpr {
        BinaryExpr::Lit(match self.next_token() {
            Token::Number(n) => n,
            token => panic!("failed to parse expression! {:?}", token),
        })
    }
}


