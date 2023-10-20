use crate::ast::{Lexer, Token, BinaryExpr};

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
        let mut left = self.parse_primary_expression();

        while self.peek(0) == Token::Plus   || self.peek(0) == Token::Minus
            || self.peek(0) == Token::Slash || self.peek(0) == Token::Star 
        {
            let op = self.next_token();
            let right = self.parse_primary_expression();

            left = BinaryExpr::Expr(Box::new(left), op, Box::new(right));
        }

        left
    }

    pub fn parse_primary_expression(&mut self) -> BinaryExpr {
        BinaryExpr::Lit(match self.next_token() {
            Token::Number(n) => n,
            token => panic!("failed to parse expression! {:?}", token),
        })
    }
}


