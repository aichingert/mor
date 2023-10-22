use crate::ast::{Lexer, Token, Expr};

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

        println!("{:?}", tokens);

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

    pub fn parse(&mut self) -> Expr { 
        self.parse_expression(1)
    }

    fn parse_unary_expression(&mut self, parent: u8) -> Expr {
        let look_ahead = self.peek(0).get_unary_precedence();

        if look_ahead != 0 && look_ahead > parent {
            let op = self.next_token();
            let expr = self.parse_expression(look_ahead);
            Expr::UnaryExpr(op, Box::new(expr))
        } else {
            self.parse_primary_expression()
        }
    }

    fn parse_expression(&mut self, parent: u8) -> Expr {
        let mut lhs = self.parse_unary_expression(parent);
        let mut look_ahead = self.peek(0).get_precedence();

        while look_ahead >= parent {
            let op = self.next_token();
            let mut rhs = self.parse_unary_expression(look_ahead);

            look_ahead = self.peek(0).get_precedence();
            let cur_precedence = op.get_precedence();

            while look_ahead > cur_precedence {
                rhs = Expr::BinaryExpr(Box::new(rhs), op, Box::new(self.parse_expression(cur_precedence + 1)));
                look_ahead = self.peek(0).get_precedence();
            }

            lhs = Expr::BinaryExpr(Box::new(lhs), op, Box::new(rhs));
        }

        lhs
    }

    fn parse_primary_expression(&mut self) -> Expr {
        match self.next_token() {
            Token::Number(n) => Expr::NumberExpr(n),
            Token::LParen    => {
                let expr = Expr::ParenExpr(Box::new(self.parse_expression(1)));
                _ = self.next_token(); // => RParen
                expr
            }
            token => panic!("failed to parse expression! {:?}", token),
        }
    }
}


