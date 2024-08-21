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

fn expectNext(self: *Self, tag: Token.Tag) void {
    if (self.tok_tags[self.nextToken()] != tag) {
        std.debug.print("expected {any} got {any}\n", .{ tag, self.tok_tags[self.tok_i - 1] });
        @panic("Expect next failed.");
    }
}

fn checkIndexOutOfBounds(self: *Self, msg: []const u8) void {
    if (self.tok_i >= self.tok_tags.len) @panic(msg);
}

fn addNode(self: *Self, node: Ast.Node) !usize {
    try self.nodes.append(self.gpa, node);
    return self.nodes.len - 1;
}

pub fn parse(self: *Self) !usize {
    var latest: usize = 0;

    while (self.peekTag() != .eof) {
        latest = switch (self.peekTag()) {
            .identifier => try self.parseDeclare(),
            else => {
                std.debug.print("{any}\n", .{self.peekTag()});
                @panic("expected string literal but got ^");
            },
        };
        std.debug.print("{d}\n", .{latest});
    }

    return latest;
}

fn parseDeclare(self: *Self) !usize {
    const ident = try self.parsePrefix();
    self.expectNext(.colon);
    const next = self.nextToken();

    return switch (self.tok_tags[next]) {
        .colon, .equal => try self.addNode(.{
            .tag = if (self.tok_tags[next] == .colon) .constant_declare else .mutable_declare,
            .main = undefined,
            .data = .{
                .lhs = ident,
                .rhs = try self.parseDeclareExpression(),
            },
        }),
        else => {
            std.debug.print("{any}\n", .{self.tok_tags[next]});
            @panic("expected constant or mutable declare but got ^");
        },
    };
}

fn parseDeclareExpression(self: *Self) !usize {
    switch (self.peekTag()) {
        .kw_fn => @panic("fn"),
        .string_lit => return self.parsePrefix(),
        else => return self.parseExpr(0),
    }
}

pub fn parseExpr(self: *Self, prec: u8) !usize {
    var node = try self.parsePrefix();

    while (self.peekTag() != .eof) {
        const tag = self.peekTag();

        if (tag.isBinaryOp() and tag.precedence() >= prec) {
            const binary = self.nextToken();
            const rhs = try self.parseExpr(tag.precedence());

            node = try self.addNode(.{
                .tag = .binary_expression,
                .main = binary,
                .data = .{
                    .lhs = node,
                    .rhs = rhs,
                },
            });

            continue;
        }

        break;
    }

    return node;
}

fn parsePrefix(self: *Self) !usize {
    self.checkIndexOutOfBounds("finding leading expr failed");

    switch (self.peekTag()) {
        .identifier => return self.addNode(.{
            .tag = .identifier,
            .main = self.nextToken(),
            .data = undefined,
        }),
        .string_lit => return self.addNode(.{
            .tag = .string_expression,
            .main = self.nextToken(),
            .data = undefined,
        }),
        .number_lit => return self.addNode(.{
            .tag = .number_expression,
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
