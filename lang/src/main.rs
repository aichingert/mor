use std::{env::args, fs};

use lang::{
    m_error,
    parse::{lexer, parser, semantic},
};

fn main() {
    let args = args().skip(1);
    if args.len() == 0 {
        m_error!("mor: ", r "fatal error: ", "no input file[s] provided");
    }

    for arg in args {
        let Ok(source) = fs::read_to_string(&arg) else {
            m_error!("mor: ", r "fatal error: ", "failed to read \"", arg, "\"");
        };

        let toks = lexer::process(&source);
        let stmts = parser::process(&source, &toks);

        println!("{source:?}");
    }
}
