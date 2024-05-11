#[derive(Debug)]
pub enum Stmt<'s> {
    Expr    (Expr<'s>),
    Local   (Local<'s>),
}

#[derive(Debug)]
pub struct Local<'l> {
    pub name: &'l str,
    // Option to support => let x;
    pub value: Option<Expr<'l>>,
}

impl<'l> Local<'l> {
    pub fn new(name: &'l str, value: Option<Expr<'l>>) -> Self {
        Self { name, value }
    }
}

#[derive(Debug)]
pub enum Expr<'e> {
    Number  (&'e str),
    Ident   (Ident<'e>),
    SubExpr (Box<Expr<'e>>),
    UnOp    (Box<UnOpEx<'e>>),
    BiOp    (Box<BiOpEx<'e>>),
}

#[derive(Debug)]
pub struct Ident<'i> {
    pub value: &'i str,
}

impl<'i> Ident<'i> {
    pub fn new(value: &'i str) -> Self {
        Ident { value }
    }
}

#[derive(Debug)]
pub enum UnOpKind {
    Not,
    Neg,
}

#[derive(Debug)]
pub struct UnOpEx<'u> {
    pub kind: UnOpKind,
    pub child: Expr<'u>,
}

#[derive(Debug)]
pub enum BiOpKind {
    Add,
    Sub,
    Mul,
    Div,
}

impl BiOpKind {
    pub fn lprec(&self) -> u16 {
        match self {
            BiOpKind::Add => 100,
            BiOpKind::Sub => 100,
            BiOpKind::Mul => 200,
            BiOpKind::Div => 200,
        }
    }
    
    pub fn rprec(&self) -> u16 {
        match self {
            BiOpKind::Add => 101,
            BiOpKind::Sub => 101,
            BiOpKind::Mul => 201,
            BiOpKind::Div => 201,
        }
    }
}

#[derive(Debug)]
pub struct BiOpEx<'b> {
    pub kind: BiOpKind,
    pub children: [Expr<'b>; 2],
}
