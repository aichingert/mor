const lex = @import("lexer.zig");
const std = @import("std");

const BinaryExpr = union(enum) {};

const ExprType = union(enum) {
    bin_expr: BinaryExpr,
};

const NumberExpr = union(enum) {
    lit: i64,
    rec: BinaryExpr,
};

pub const Parser = struct {
    const Self = @This();
    tokens: [3]lex.Token = undefined,

    pub fn new(data: []const u8) Self {
        std.debug.print("Parser: {s} \n", .{data});

        var l = lex.Lexer.init(data);

        var parser = Self{
            .tokens = .{ l.next_token(), l.next_token(), l.next_token() },
        };

        return parser;
    }

    pub fn get(self: *Self, i: usize) lex.Token {
        return self.tokens[i];
    }
};
