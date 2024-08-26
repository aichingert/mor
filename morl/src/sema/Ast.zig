const std = @import("std");
const lex = @import("lexer.zig");
const Lexer = lex.Lexer;
const Token = lex.Token;
const Parser = @import("Parser.zig");

const Self = @This();

nodes: NodeList.Slice,
funcs: FuncList.Slice,
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
        identifier,
        number_expression,
        string_expression,

        unary_expression,
        binary_expression,

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

pub fn init(gpa: std.mem.Allocator, source: []const u8) std.mem.Allocator.Error!Self {
    var tokens = Self.TokenList{};
    defer tokens.deinit(gpa);

    var lexer = Lexer.init(source);

    while (true) {
        const token = lexer.next();
        std.debug.print("{any}\n", .{token.tag});
        try tokens.append(gpa, token);
        if (token.tag == .eof) break;
    }

    var parser = Parser.init(gpa, source, tokens.items(.tag), tokens.items(.loc));
    defer parser.deinit();
    try parser.parse();

    for (parser.stmts.items) |item| {
        std.debug.print("item: {d}\n", .{item});
        print(item, 0, source, parser.nodes, tokens);
    }

    return .{
        .source = source,
        .tokens = tokens.toOwnedSlice(),
        .stmts = parser.stmts,
        .nodes = parser.nodes.toOwnedSlice(),
        .funcs = parser.funcs.toOwnedSlice(),
    };
}

pub fn print(idx: usize, indent: u8, source: []const u8, nodes: NodeList, tokens: TokenList) void {
    switch (nodes.items(.tag)[idx]) {
        .unary_expression => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }
            std.debug.print("{any}\n", .{tokens.items(.tag)[nodes.items(.main)[idx]]});
            print(nodes.items(.data)[idx].lhs, indent, source, nodes, tokens);
        },
        .binary_expression => {
            print(nodes.items(.data)[idx].lhs, indent + 2, source, nodes, tokens);
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }
            std.debug.print("{any}\n", .{tokens.items(.tag)[nodes.items(.main)[idx]]});
            print(nodes.items(.data)[idx].rhs, indent + 2, source, nodes, tokens);
        },
        .number_expression => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }

            const loc = tokens.items(.loc)[nodes.items(.main)[idx]];
            std.debug.print("{s} [{}-{}]\n", .{ source[loc.start..loc.end], loc.start, loc.end });
        },
        .identifier => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }

            const loc = tokens.items(.loc)[nodes.items(.main)[idx]];
            std.debug.print("{s}\n", .{source[loc.start..loc.end]});
        },
        .string_expression => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }

            const loc = tokens.items(.loc)[nodes.items(.main)[idx]];
            std.debug.print("{s}\n", .{source[loc.start..loc.end]});
        },
        .type_declare => {
            print(nodes.items(.data)[idx].lhs, indent + 4, source, nodes, tokens);

            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }
            std.debug.print(" : \n", .{});

            print(nodes.items(.data)[idx].rhs, indent + 4, source, nodes, tokens);
        },
        .constant_declare => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }
            std.debug.print("const \n", .{});

            print(nodes.items(.data)[idx].lhs, indent + 2, source, nodes, tokens);
            print(nodes.items(.data)[idx].rhs, indent + 4, source, nodes, tokens);
        },
        .mutable_declare => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }
            std.debug.print("mut  \n", .{});

            print(nodes.items(.data)[idx].lhs, indent + 2, source, nodes, tokens);
            print(nodes.items(.data)[idx].rhs, indent + 4, source, nodes, tokens);
        },
        else => std.debug.print("{any}\n", .{nodes.items(.tag)[idx]}),
    }
}

pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
    self.stmts.deinit();
    self.nodes.deinit(gpa);

    for (self.funcs.items(.args), 0..) |_, i| {
        self.funcs.items(.args)[i].deinit();
        self.funcs.items(.body)[i].deinit();
    }

    self.funcs.deinit(gpa);
    self.tokens.deinit(gpa);
    self.* = undefined;
}
