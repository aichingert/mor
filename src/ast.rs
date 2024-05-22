use crate::CompileError;
use crate::Token;

#[derive(Debug, Clone)]
pub enum Stmt<'s> {
    Local(Local<'s>),
    Expr(Expr<'s>),
}

#[derive(Debug, Clone)]
pub struct Local<'l> {
    pub name: &'l str,
    // TODO: support => auto x = Expr;
    pub typ: Option<Token<'l>>,
    // Option to support => i8 x;
    pub value: Option<Expr<'l>>,
}

impl<'l> Local<'l> {
    pub fn new(name: &'l str, typ: Option<Token<'l>>, value: Option<Expr<'l>>) -> Self {
        Self { name, typ, value }
    }
}

#[derive(Debug, Clone)]
pub enum Expr<'e> {
    Number(&'e str),
    Ident(Ident<'e>),
    If(Box<If<'e>>),
    While(Box<While<'e>>),

    SubExpr(Box<Expr<'e>>),

    UnOp(Box<UnOpEx<'e>>),
    BiOp(Box<BiOpEx<'e>>),
}

#[derive(Debug, Clone)]
pub struct If<'i> {
    pub condition: Expr<'i>,
    pub on_true: Block<'i>,
    pub on_false: Option<Block<'i>>,
}

#[derive(Debug, Clone)]
pub struct While<'w> {
    pub condition: Expr<'w>,
    pub body: Block<'w>,
}

pub type Block<'b> = Vec<Stmt<'b>>;

#[derive(Debug, Clone)]
pub struct Ident<'i> {
    pub value: &'i str,
}

impl<'i> Ident<'i> {
    pub fn new(value: &'i str) -> Self {
        Ident { value }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UnOpKind {
    Not,
    Neg,
}

#[derive(Debug, Clone)]
pub struct UnOpEx<'u> {
    pub kind: UnOpKind,
    pub child: Expr<'u>,
}

#[derive(Debug, Clone, Copy, Eq, PartialEq)]
pub enum BiOpKind {
    Add,
    Sub,
    Mul,
    Div,
    Set,

    BiOr,
    BiAnd,
    BoOr,
    BoAnd,

    CmpEq,
    CmpNe,
    CmpLt,
    CmpGt,
    CmpLe,
    CmpGe,
}

impl BiOpKind {
    pub fn lprec(&self) -> u16 {
        match self {
            BiOpKind::Set => 10,
            BiOpKind::Add => 100,
            BiOpKind::Sub => 100,
            BiOpKind::Mul => 200,
            BiOpKind::Div => 200,

            BiOpKind::BiOr => 200,
            BiOpKind::BiAnd => 201,

            BiOpKind::BoOr => 200,
            BiOpKind::BoAnd => 201,

            BiOpKind::CmpEq => 300,
            BiOpKind::CmpNe => 300,
            BiOpKind::CmpGt => 300,
            BiOpKind::CmpLt => 300,
            BiOpKind::CmpLe => 300,
            BiOpKind::CmpGe => 300,
        }
    }

    pub fn rprec(&self) -> u16 {
        match self {
            BiOpKind::Set => 11,
            BiOpKind::Add => 101,
            BiOpKind::Sub => 101,
            BiOpKind::Mul => 201,
            BiOpKind::Div => 201,

            BiOpKind::BiOr => 201,
            BiOpKind::BiAnd => 202,

            BiOpKind::BoOr => 201,
            BiOpKind::BoAnd => 202,

            BiOpKind::CmpEq => 301,
            BiOpKind::CmpNe => 301,
            BiOpKind::CmpGt => 301,
            BiOpKind::CmpLt => 301,
            BiOpKind::CmpLe => 301,
            BiOpKind::CmpGe => 301,
        }
    }

    pub fn to_jmp(&self) -> Result<String, CompileError> {
        match self {
            BiOpKind::CmpEq => Ok("jne".to_string()),
            BiOpKind::CmpNe => Ok("je".to_string()),
            BiOpKind::CmpLt => Ok("jge".to_string()),
            BiOpKind::CmpLe => Ok("jg".to_string()),
            BiOpKind::CmpGt => Ok("jle".to_string()),
            BiOpKind::CmpGe => Ok("jl".to_string()),
            _ => Err(CompileError::new("invalid cmp for jmp")),
        }
    }
}

#[derive(Debug, Clone)]
pub struct BiOpEx<'b> {
    pub kind: BiOpKind,
    pub children: [Expr<'b>; 2],
}

pub fn print(stmt: &Stmt<'_>, ident: usize) {
    let id = format!("{:01$}", ' ', ident);
    match stmt {
        Stmt::Expr(ex) => print_ex(ex, ident),
        Stmt::Local(loc) => {
            print!("{id}{}", loc.name);
            if let Some(ex) = &loc.value {
                println!(" = {{");
                print_ex(ex, ident + 2);
                println!("{id}}}");
            } else {
                println!();
            }
        }
    }
}

pub fn print_ex(ex: &Expr<'_>, ident: usize) {
    let id = format!("{:01$}", ' ', ident);
    match ex {
        Expr::Number(n) => println!("{id}{n}"),
        Expr::Ident(Ident { value }) => println!("{id}{value}"),
        Expr::If(ife) => {
            println!("{id}if");
            print_ex(&ife.condition, ident + 2);
            println!("{id}then:");
            ife.on_true.iter().for_each(|s| print(s, ident + 2));
            if let Some(f) = ife.on_false.as_ref() {
                println!("{id}else {{");
                f.iter().for_each(|s| print(s, ident + 2));
                println!("{id}}}");
            }
        }
        Expr::While(whl) => {
            println!("{id}while");
            print_ex(&whl.condition, ident + 2);
            println!("{id}{{");
            whl.body.iter().for_each(|s| print(s, ident + 2));
            println!("{id}}}");
        }
        Expr::SubExpr(sub) => print_ex(sub, ident),
        Expr::BiOp(bi) => {
            let [a, b] = &bi.children;
            println!("{id}{{");
            println!("{id} kind: {:?}", bi.kind);
            print_ex(a, ident + 2);
            print_ex(b, ident + 2);
            println!("{id}}}");
        }
        Expr::UnOp(un) => {
            println!("{id}{{");
            println!("{id}  kind: {:?}", un.kind);
            print_ex(&un.child, ident + 2);
            println!("{id}}}");
        }
    }
}
