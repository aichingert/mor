#[derive(Clone,Debug)]
pub enum Obj {
    Str(String),
    Num(i64),
    Bool(bool),
}
