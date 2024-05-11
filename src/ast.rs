#[derive(Debug)]
pub enum Expr<'e> {
    Number  (&'e str),
    SubExpr (Box<Expr<'e>>),
    UnOp    (Box<UnOpEx<'e>>),
    BiOp    (Box<BiOpEx<'e>>),
}

#[derive(Debug)]
pub enum UnOpKind {
    Not,
    Negate,
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
