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

fn peekTag(self: *Self) Token.Tag {
    return self.tok_tags[self.tok_i];
}

fn nextToken(self: *Self) usize {
    self.tok_i += 1;
    return self.tok_i - 1;
}

fn addNode(self: *Self, node: Ast.Node) !usize {
    try self.nodes.append(self.gpa, node);
    return self.nodes.len - 1;
}

pub fn parse(self: *Self) !void {
    var stack = std.ArrayList(struct { prec: u32, node: usize }).init(self.gpa);
    defer stack.deinit();

    const node = try self.parsePrefix();

    while (self.peekTag() != .eof) {
        if (self.peekTag().isBinaryOp()) {
            const binary = self.nextToken();
            const rhs = try self.parsePrefix();

            if (stack.items.len == 0) {
                try stack.append(.{
                    .prec = self.tok_tags[binary].precedence(),
                    .node = try self.addNode(.{
                        .tag = .binary_expression,
                        .main = binary,
                        .data = .{
                            .lhs = node,
                            .rhs = rhs,
                        },
                    }),
                });
            } else {
                var prev = stack.pop();
                const prec = self.tok_tags[binary].precedence();
                while (prev.prec > prec and stack.items.len > 0) : (prev = stack.pop()) {}

                try stack.append(.{
                    .prec = prec,
                    .node = try self.addNode(.{
                        .tag = .binary_expression,
                        .main = binary,
                        .data = .{
                            .lhs = prev.node,
                            .rhs = rhs,
                        },
                    }),
                });
            }

            continue;
        }

        @panic("only binary operations for now");
    }
}

fn parsePrefix(self: *Self) !usize {
    self.checkIndexOutOfBounds("finding leading expr failed");

    switch (self.peekTag()) {
        .number_lit => return self.addNode(.{
            .tag = .number_literal,
            .main = self.nextToken(),
            .data = undefined,
        }),
        else => {},
    }

    if (self.peekTag().isUnaryOp()) {
        const unary = self.nextToken();
        const node = try self.parsePrefix();

        return self.addNode(.{
            .tag = .unary_expression,
            .main = unary,
            .data = .{
                .lhs = node,
                .rhs = undefined,
            },
        });
    }

    std.debug.print("{any}\n", .{self.peekTag()});
    @panic("should not get here");
}

fn checkIndexOutOfBounds(self: *Self, msg: []const u8) void {
    if (self.tok_i >= self.tok_tags.len) @panic(msg);
}
