use crate::Token;

#[derive(Debug, Clone)]
pub enum Stmt<'s> {
    Expr    (Expr<'s>),
    Local   (Local<'s>),
}

#[derive(Debug, Clone)]
pub struct Local<'l> {
    pub name: &'l str,

    // TODO: support => auto x = Expr; 
    pub is_ptr: bool,
    pub typ: Option<Token<'l>>,

    // Option to support => i8 x;
    pub value: Option<Expr<'l>>,
}

impl<'l> Local<'l> {
    pub fn new(name: &'l str, is_ptr: bool, typ: Option<Token<'l>>, value: Option<Expr<'l>>) -> Self {
        Self { name, is_ptr, typ, value }
    }
}

#[derive(Debug, Clone)]
pub enum Expr<'e> {
    Number  (&'e str),
    Ident   (Ident<'e>),
    If      (Box<If<'e>>),

    SubExpr (Box<Expr<'e>>),

    UnOp    (Box<UnOpEx<'e>>),
    BiOp    (Box<BiOpEx<'e>>),
}

#[derive(Debug, Clone)]
pub struct If<'i> {
    pub condition:  Option<Expr<'i>>,
    pub on_true:    Block<'i>,
    pub on_false:   Option<Block<'i>>,
}

#[derive(Debug, Clone)]
pub struct Block<'b> {
    pub stmts: Vec<Stmt<'b>>,
}

#[derive(Debug, Clone)]
pub struct Ident<'i> {
    pub value: &'i str,
}

impl<'i> Ident<'i> {
    pub fn new(value: &'i str) -> Self {
        Ident { value }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum UnOpKind {
    Not,
    Neg,
    Ref,
    Deref,
}

#[derive(Debug, Clone)]
pub struct UnOpEx<'u> {
    pub kind: UnOpKind,
    pub child: Expr<'u>,
}

#[derive(Debug, Clone, Eq, PartialEq)]
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

    CmpE,
    CmpNe,
    CmpL,
    CmpG,
    CmpLe,
    CmpGe,
}

impl BiOpKind {
    pub fn lprec(&self) -> u16 {
        match self {
            BiOpKind::Add => 100,
            BiOpKind::Sub => 100,
            BiOpKind::Mul => 200,
            BiOpKind::Div => 200,

            BiOpKind::BiOr => 200,
            BiOpKind::BiAnd => 201,

            BiOpKind::BoOr => 200,
            BiOpKind::BoAnd => 201,

            BiOpKind::CmpE => 300,
            BiOpKind::CmpNe => 300,
            BiOpKind::CmpG => 300,
            BiOpKind::CmpL => 300,
            BiOpKind::CmpLe=> 300,
            BiOpKind::CmpGe=> 300,
            BiOpKind::Set => 900,
        }
    }
    
    pub fn rprec(&self) -> u16 {
        match self {
            BiOpKind::Add => 101,
            BiOpKind::Sub => 101,
            BiOpKind::Mul => 201,
            BiOpKind::Div => 201,

            BiOpKind::BiOr => 201,
            BiOpKind::BiAnd => 202,

            BiOpKind::BoOr => 201,
            BiOpKind::BoAnd => 202,

            BiOpKind::CmpE => 301,
            BiOpKind::CmpNe => 301,
            BiOpKind::CmpG => 301,
            BiOpKind::CmpL => 301,
            BiOpKind::CmpLe=> 301,
            BiOpKind::CmpGe=> 301,
            BiOpKind::Set => 901,
        }
    }
}

#[derive(Debug, Clone)]
pub struct BiOpEx<'b> {
    pub kind: BiOpKind,
    pub children: [Expr<'b>; 2],
}
