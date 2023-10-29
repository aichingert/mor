use crate::ast::{Lexer, Token, Statement, Expr};

#[derive(Debug)]
pub struct Parser {
    tokens: Vec<Token>,
    loc: usize,
}

impl Parser {
    pub fn new(source: &String) -> Self {
        let mut lexer = Lexer::new(source.chars().collect::<Vec<_>>());
        let mut tokens = Vec::new();

        while let Some(token) = lexer.next_token() {
            tokens.push(token);
        }
        tokens.push(Token::Eof);

        Self {
            tokens,
            loc: 0,
        }
    }

    fn next_token(&mut self) -> Token {
        if self.loc + 1 >= self.tokens.len() {
            return self.tokens[self.tokens.len() - 1].clone();
        }

        self.loc += 1;
        self.tokens[self.loc - 1].clone()
    }

    fn peek(&self, offset: usize) -> Token {
        if self.loc + offset >= self.tokens.len() {
            return self.tokens[self.tokens.len() - 1].clone();
        }

        self.tokens[self.loc + offset].clone()
    }

    pub fn parse(&mut self) -> Statement { 
        self.parse_statement()
    }

    fn parse_statement(&mut self) -> Statement {
        match self.peek(0) {
            Token::KwLet => self.parse_declare_statement(),
            _ => Statement::AstExpr(self.parse_expression(1)),
        }
    }

    fn parse_declare_statement(&mut self) -> Statement {
        _ = self.next_token(); // KW_Let

        let ident = match self.next_token() {
            Token::Ident(s) => s,
            _ => panic!("invalid declare statement"),
        };

        _ = self.next_token(); // assign

        let expr = self.parse_expression(1);

        Statement::AstDecl(ident, expr)
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

            while look_ahead > op.get_precedence() {
                let binding_op = self.next_token();
                rhs = Expr::BinaryExpr(Box::new(rhs), binding_op, Box::new(self.parse_expression(op.get_precedence() + 1)));
                look_ahead = self.peek(0).get_precedence();
            }

            lhs = Expr::BinaryExpr(Box::new(lhs), op, Box::new(rhs));
        }

        lhs
    }

    fn parse_primary_expression(&mut self) -> Expr {
        match self.next_token() {
            Token::Ident(s) => Expr::IdentExpr(s),
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


