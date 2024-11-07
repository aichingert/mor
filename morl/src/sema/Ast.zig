const std = @import("std");

const lex = @import("lexer.zig");
const Lexer = lex.Lexer;
const Token = lex.Token;
const Parser = @import("Parser.zig");

const Self = @This();

nodes: NodeList.Slice,
funcs: FuncList.Slice,
calls: std.ArrayList(Call),
stmts: std.ArrayList(usize),

source: []const u8,
tokens: TokenList.Slice,

pub const NodeList = std.MultiArrayList(Node);
pub const FuncList = std.MultiArrayList(Func);
pub const TokenList = std.MultiArrayList(Token);

pub const Node = struct {
    tag: Tag,
    main: usize,
    data: Data,

    const Data = struct {
        lhs: usize,
        rhs: usize,
    };

    const Tag = enum {
        ident,
        num_expr,
        str_expr,

        unary_expr,
        binary_expr,
        call_expr,
        macro_call_expr,

        assign_stmt,
        return_stmt,

        type_declare,
        mutable_declare,
        constant_declare,
        function_declare,
    };
};

pub const Func = struct {
    args: std.ArrayList(usize),
    body: std.ArrayList(usize),

    return_type: Token.Tag,
};

pub const Call = struct {
    args: std.ArrayList(usize),
};

pub fn init(gpa: std.mem.Allocator, source: []const u8) std.mem.Allocator.Error!Self {
    var tokens = Self.TokenList{};
    defer tokens.deinit(gpa);

    var lexer = Lexer.init(source);

    while (true) {
        const token = lexer.genNext();
        try tokens.append(gpa, token);
        if (token.tag == .eof) break;
    }

    var parser = Parser.init(gpa, source, tokens.items(.tag), tokens.items(.loc));
    defer parser.deinit();
    try parser.parse();

    return .{
        .source = source,
        .tokens = tokens.toOwnedSlice(),
        .stmts = parser.stmts,
        .calls = parser.calls,
        .nodes = parser.nodes.toOwnedSlice(),
        .funcs = parser.funcs.toOwnedSlice(),
    };
}

pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
    self.stmts.deinit();

    for (self.calls.items) |call| {
        call.args.deinit();
    }

    for (self.funcs.items(.args), 0..) |_, i| {
        self.funcs.items(.args)[i].deinit();
        self.funcs.items(.body)[i].deinit();
    }

    self.calls.deinit();
    self.nodes.deinit(gpa);
    self.funcs.deinit(gpa);
    self.tokens.deinit(gpa);
    self.* = undefined;
}
