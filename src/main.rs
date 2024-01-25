use std::io::{self, Write};

mod ast;
use ast::Parser;

mod eval;
use eval::Environment;

fn repl() -> io::Result<()> {
    let mut env = Environment::new();
    let stdin = io::stdin();

    loop {
        print!("> ");
        let mut buf = String::new();

        io::stdout().flush()?;
        stdin.read_line(&mut buf)?;
        buf = buf.trim().to_string();

        if buf == "q" {
            break;
        }

        let tokens = Parser::new(&buf).parse();
        let value = tokens.evaluate(&mut env);

        println!("{:?}", value);
    }

    Ok(())
}

fn main() -> io::Result<()> {
    repl()?;

    Ok(())
}
