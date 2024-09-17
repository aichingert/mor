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
        identifier,
        number_expression,
        string_expression,

        call_expression,
        unary_expression,
        binary_expression,
        return_expression,

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

    for (parser.stmts.items) |item| {
        print(
            item,
            0,
            source,
            parser.funcs,
            parser.nodes,
            tokens,
            parser.calls,
        );
        std.debug.print("------\n", .{});
    }

    return .{
        .source = source,
        .tokens = tokens.toOwnedSlice(),
        .stmts = parser.stmts,
        .calls = parser.calls,
        .nodes = parser.nodes.toOwnedSlice(),
        .funcs = parser.funcs.toOwnedSlice(),
    };
}

pub fn print(
    idx: usize,
    indent: u8,
    source: []const u8,
    funcs: FuncList,
    nodes: NodeList,
    tokens: TokenList,
    calls: std.ArrayList(Call),
) void {
    switch (nodes.items(.tag)[idx]) {
        .unary_expression => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }
            std.debug.print("({s} ", .{std.enums.tagName(
                Token.Tag,
                tokens.items(.tag)[nodes.items(.main)[idx]],
            ).?});

            print(nodes.items(.data)[idx].lhs, 0, source, funcs, nodes, tokens, calls);
            std.debug.print(")", .{});
        },
        .binary_expression => {
            std.debug.print("(", .{});
            print(nodes.items(.data)[idx].lhs, 0, source, funcs, nodes, tokens, calls);

            std.debug.print(" {s} ", .{std.enums.tagName(
                Token.Tag,
                tokens.items(.tag)[nodes.items(.main)[idx]],
            ).?});

            print(nodes.items(.data)[idx].rhs, 0, source, funcs, nodes, tokens, calls);
            std.debug.print(")", .{});
        },
        .return_expression => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }
            std.debug.print("return ", .{});
            print(nodes.items(.data)[idx].lhs, 0, source, funcs, nodes, tokens, calls);
            std.debug.print("\n", .{});
        },
        .number_expression => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }

            const loc = tokens.items(.loc)[nodes.items(.main)[idx]];
            std.debug.print("{s}", .{source[loc.start..loc.end]});
        },
        .identifier => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }

            const loc = tokens.items(.loc)[nodes.items(.main)[idx]];
            std.debug.print("{s}", .{source[loc.start..loc.end]});
        },
        .string_expression => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }

            const loc = tokens.items(.loc)[nodes.items(.main)[idx]];
            std.debug.print("{s}", .{source[loc.start..loc.end]});
        },
        .call_expression => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }

            const data = nodes.items(.data)[idx];
            const loc = tokens.items(.loc)[nodes.items(.main)[data.lhs]];
            const call = calls.items[data.rhs];

            std.debug.print("{s}(", .{source[loc.start..loc.end]});

            for (call.args.items) |arg| {
                print(arg, 0, source, funcs, nodes, tokens, calls);
            }
            std.debug.print(")", .{});
        },
        .type_declare => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }

            const data = nodes.items(.data)[idx];
            const lhs = tokens.items(.loc)[data.lhs];
            const rhs = tokens.items(.loc)[data.rhs];

            std.debug.print("{s}: {s},", .{
                source[lhs.start..lhs.end],
                source[rhs.start..rhs.end],
            });
        },
        .function_declare => {
            print(nodes.items(.data)[idx].lhs, 0, source, funcs, nodes, tokens, calls);

            std.debug.print("\n", .{});
            for (funcs.items(.args)[nodes.items(.data)[idx].rhs].items) |arg| {
                print(arg, 2, source, funcs, nodes, tokens, calls);
            }

            std.debug.print("\n", .{});
            std.debug.print("\n", .{});

            for (funcs.items(.body)[nodes.items(.data)[idx].rhs].items) |stmt| {
                print(stmt, 2, source, funcs, nodes, tokens, calls);
            }
        },
        .constant_declare => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }
            std.debug.print("const ", .{});

            print(nodes.items(.data)[idx].lhs, 0, source, funcs, nodes, tokens, calls);
            std.debug.print(" :: ", .{});
            print(nodes.items(.data)[idx].rhs, 0, source, funcs, nodes, tokens, calls);
            std.debug.print("\n", .{});
        },
        .mutable_declare => {
            var i: u8 = 0;
            while (i < indent) : (i += 1) {
                std.debug.print(" ", .{});
            }
            std.debug.print("mut ", .{});

            print(nodes.items(.data)[idx].lhs, 0, source, funcs, nodes, tokens, calls);
            std.debug.print(" := ", .{});
            print(nodes.items(.data)[idx].rhs, 0, source, funcs, nodes, tokens, calls);
            std.debug.print("\n", .{});
        },
    }
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
