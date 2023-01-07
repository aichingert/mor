use std::fs::{self, File};
use std::io::Read;

fn run(arg: &String) {
    let canonicalize = fs::canonicalize(arg);
    let mut code = String::new();

    match canonicalize {
        Ok(filename) => match File::open(&filename) {
            Ok(mut file) => match file.read_to_string(&mut code) {
                Ok(_) => {},
                Err(e) => {
                    println!("Unable to open file {e:?}");
                    return;
                }
            },
            Err(_) => {}
        },
        Err(_) => {
            println!("File: \"{arg}\" not found!");
            return;
        }
    }

    println!("{code:?}");
}

fn main() {
    let mut args =  std::env::args().collect::<Vec<String>>();

    if args.len() <= 1 {
        // TODO: CLI repl
    } else {
        args.remove(0);
        run(&args[0]);
    }
}
