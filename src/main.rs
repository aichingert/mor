mod ast;
use ast::Parser;

fn main() {
    let mut parser = Parser::new("10 + 3 * 4".to_string());

    println!("{:?}", parser.parse());

}
