const std = @import("std");
const Ast = @import("Ast.zig");
const Token = @import("lexer.zig").Token;

const Self = @This();

gpa: std.mem.Allocator,

tok_i: usize,
tok_tags: []const Token.Tag,
tok_locs: []const Token.Loc,

source: []const u8,
nodes: Ast.NodeList,

pub fn init(
    gpa: std.mem.Allocator,
    source: []const u8,
    tok_tags: []const Token.Tag,
    tok_locs: []const Token.Loc,
) Self {
    return .{
        .gpa = gpa,
        .tok_i = 0,
        .tok_tags = tok_tags,
        .tok_locs = tok_locs,
        .nodes = Ast.NodeList{},
        .source = source,
    };
}

pub fn deinit(self: *Self) void {
    self.nodes.deinit(self.gpa);
}

pub fn parse(self: *Self) !void {
    var stack = std.ArrayList(usize).init(self.gpa);
    defer stack.deinit();

    while (self.tok_tags[self.tok_i] != .eof) : (self.tok_i += 1) {
        switch (self.tok_tags[self.tok_i]) {
            .number_lit => {
                try stack.append(self.tok_i);
            },
            .string_lit => {
                try stack.append(self.tok_i);
            },
            else => {},
        }
    }
}
