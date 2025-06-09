const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Lexer = @import("Lexer.zig");
const Token = Lexer.Token;
// const Parser = @import("Parser.zig");

const Self = @This();

stmts: ArrayList(Stmt),
vars: ArrayList(Var),
funcs: ArrayList(Func),

pub const Stmt = struct {
    tag: Tag,
    idx: usize,

    const Tag = enum {
        s_variable,
        s_function,
    };
};

pub const MorType = union(enum) {
    m_infer,
    m_basic: MorPrimitive,
    m_array: *Stmt,
    m_struct: *Token,
};

pub const MorPrimitive = enum {
    m_s8,
    m_u8,
    m_s16,
    m_u16,
    m_s32,
    m_u32,
    m_s64,
    m_u64,
};

pub const Var = struct {
    v_type: MorType,
    v_ident: Token,
};

pub const Func = struct {
    args: std.ArrayList(Stmt),
    body: std.ArrayList(Stmt),

    return_type: Token.Tag,
};

pub const Call = struct {
    args: std.ArrayList(usize),
};

pub const Loop = struct {
    cond: usize,
    body: std.ArrayList(usize),

    fn deinit(self: *const Loop) void {
        self.body.deinit();
    }
};

pub const Array = struct {
    elements: std.ArrayList(usize),

    fn deinit(self: *const Array) void {
        self.elements.deinit();
    }
};

pub const Cond = struct {
    if_cond: usize,
    if_body: std.ArrayList(usize),
    elif_ex: std.ArrayList(usize),
    el_body: std.ArrayList(usize),

    fn deinit(self: *const Cond) void {
        self.if_body.deinit();
        self.elif_ex.deinit();
        self.el_body.deinit();
    }
};

pub fn init(gpa: Allocator, source: []const u8) Allocator.Error!Self {
    const toks = try Lexer.parse(gpa, source);
    defer toks.deinit();

    //var parser = Parser.init(gpa, source, tokens.items(.tag), tokens.items(.loc));
    //defer parser.deinit();
    //try parser.parse();

    return .{
        .stmts = ArrayList(Stmt).init(gpa),
        .funcs = ArrayList(Func).init(gpa),
        .vars = ArrayList(Var).init(gpa),
    };
}

pub fn getIdent(self: *const Self, idx: usize) []const u8 {
    const ident = self.nodes.items(.main)[idx];
    const loc = self.tokens.items(.loc)[ident];
    return self.source[loc.start..loc.end];
}

pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
    _ = self;
    _ = gpa;
}
