// Eval - used for running the code
// (c) aichingert

use crate::lex::*;

use std::collections::HashMap;

#[derive(Debug, Clone)]
pub enum Obj {
    S(String),
    I(i32),
    F(f32),
    B(bool),
}

#[derive(Debug, Clone)]
pub struct Runtime {
    variables: HashMap<String, Obj>,
    code: Vec<Token>
}

impl Runtime {
    pub fn new(code: Vec<Token>) -> Self {
        Runtime { variables: HashMap::new(), code }
    }
    
    pub fn run(&mut self) {
        let mut i: usize = 0;

        while i < self.code.len() {
            match &self.code[i] {
                Token::Indent(new) => {
                    if i+2 < self.code.len() && self.code[i+1] == Token::Assign {
                        match &self.code[i+2] {
                            Token::Indent(var) => {
                                if let Some(obj) = self.variables.get(var) {
                                    self.variables.insert(new.clone(), obj.clone());
                                } else {
                                    panic!("TODO: NOT ASSIGNED VARIABLE REASSIGN");
                                }
                            },
                            Token::StringLit(s) => {
								self.variables.insert(new.clone(), Obj::S(s.clone()));
							},
							_ => panic!("TODO: more types"),
						}
						i += 2;
                    }
                },
				_ => panic!("TODO: Other actions"),
            }
			i += 1;
        }

		println!("{:?}", self);
    }
}

