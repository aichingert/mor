const std = @import("std");
const Ast = @import("Ast.zig");
const Token = @import("lexer.zig").Token;

const Self = @This();

gpa: std.mem.Allocator,

tok_i: usize,
tok_tags: []const Token.Tag,
tok_locs: []const Token.Loc,
nodes: Ast.NodeList,

pub fn init(
    gpa: std.mem.Allocator,
    tok_tags: []const Token.Tag,
    tok_locs: []const Token.Loc,
) Self {
    return .{
        .gpa = gpa,
        .tok_i = 0,
        .tok_tags = tok_tags,
        .tok_locs = tok_locs,
        .nodes = Ast.NodeList{},
    };
}

pub fn deinit(self: *Self) void {
    self.nodes.deinit(self.gpa);
}

pub fn parse(self: *Self) void {
    if (self.tok_tags[self.tok_i] != .number) {
        @panic("expression has to start with a number");
    }

    return;
}
