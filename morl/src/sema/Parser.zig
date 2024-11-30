const std = @import("std");
const Ast = @import("Ast.zig");
const Token = @import("lexer.zig").Token;

const Self = @This();

gpa: std.mem.Allocator,

tok_i: usize,
entry: usize,
tok_tags: []const Token.Tag,
tok_locs: []const Token.Loc,

source: []const u8,
nodes: Ast.NodeList,
funcs: Ast.FuncList,
calls: std.ArrayList(Ast.Call),
conds: std.ArrayList(Ast.Cond),
loops: std.ArrayList(Ast.Loop),
stmts: std.ArrayList(usize),

pub fn init(
    gpa: std.mem.Allocator,
    source: []const u8,
    tok_tags: []const Token.Tag,
    tok_locs: []const Token.Loc,
) Self {
    return .{
        .gpa = gpa,
        .entry = std.math.maxInt(usize),
        .tok_i = 0,
        .tok_tags = tok_tags,
        .tok_locs = tok_locs,
        .stmts = std.ArrayList(usize).init(gpa),
        .conds = std.ArrayList(Ast.Cond).init(gpa),
        .loops = std.ArrayList(Ast.Loop).init(gpa),
        .calls = std.ArrayList(Ast.Call).init(gpa),
        .funcs = Ast.FuncList{},
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
        std.debug.print("error happened at {any}:{any}\n", .{
            self.tok_locs[self.tok_i - 1].start,
            self.tok_locs[self.tok_i - 1].end,
        });
        @panic("Expect next failed.");
    }
}

fn checkIndexOutOfBounds(self: *Self, msg: []const u8) void {
    if (self.tok_i >= self.tok_tags.len) @panic(msg);
}

fn addNode(self: *Self, node: Ast.Node) std.mem.Allocator.Error!usize {
    try self.nodes.append(self.gpa, node);
    return self.nodes.len - 1;
}

fn addFunc(self: *Self, func: Ast.Func) std.mem.Allocator.Error!usize {
    try self.funcs.append(self.gpa, func);
    return self.funcs.len - 1;
}

fn addCall(self: *Self, call: Ast.Call) std.mem.Allocator.Error!usize {
    try self.calls.append(call);
    return self.calls.items.len - 1;
}

fn addCond(self: *Self, cond: Ast.Cond) std.mem.Allocator.Error!usize {
    try self.conds.append(cond);
    return self.conds.items.len - 1;
}

fn addLoop(self: *Self, loop: Ast.Loop) std.mem.Allocator.Error!usize {
    try self.loops.append(loop);
    return self.loops.items.len - 1;
}

pub fn parse(self: *Self) std.mem.Allocator.Error!void {
    while (self.peekTag() != .eof) {
        try self.stmts.append(switch (self.peekTag()) {
            .identifier => try self.parseDeclare(),
            else => {
                std.debug.print("{any}\n", .{self.peekTag()});
                @panic("expected string literal but got ^");
            },
        });
    }
}

fn parseCondition(self: *Self) std.mem.Allocator.Error!usize {
    self.expectNext(.kw_if);

    const expr = try self.parseExpr(0);
    self.expectNext(.lbrace);
    const body = try self.parseFuncBody();
    var elif_ex = std.ArrayList(usize).init(self.gpa);
    var el_body = std.ArrayList(usize).init(self.gpa);

    while (self.peekTag() == .kw_elif) {
        self.expectNext(.kw_elif);
        const elif_expr = try self.parseExpr(0);
        self.expectNext(.lbrace);
        const elif_body = try self.parseFuncBody();

        try elif_ex.append(try self.addCond(.{
            .if_cond = elif_expr,
            .if_body = elif_body,
            .elif_ex = undefined,
            .el_body = undefined,
        }));
    }

    if (self.peekTag() == .kw_else) {
        self.expectNext(.kw_else);
        self.expectNext(.lbrace);

        el_body.deinit();
        el_body = try self.parseFuncBody();
    }

    return self.addNode(.{
        .tag = .if_expr,
        .main = undefined,
        .data = .{
            .lhs = try self.addCond(.{
                .if_cond = expr,
                .if_body = body,
                .elif_ex = elif_ex,
                .el_body = el_body,
            }),
            .rhs = undefined,
        },
    });
}

fn parseWhile(self: *Self) std.mem.Allocator.Error!usize {
    self.expectNext(.kw_while);

    const cond = try self.parseExpr(0);

    self.expectNext(.lbrace);
    const body = try self.parseFuncBody();

    return self.addNode(.{
        .tag = .while_expr,
        .main = undefined,
        .data = .{
            .lhs = try self.addLoop(.{
                .cond = cond,
                .body = body,
            }),
            .rhs = undefined,
        },
    });
}

fn parseCompMacroCall(self: *Self) std.mem.Allocator.Error!usize {
    self.expectNext(.dollar);

    const ident = try self.parsePrefix();
    std.debug.print("{any}\n", .{self.nodes.items(.tag)[ident]});

    const call = try self.addNode(.{
        .tag = .macro_call_expr,
        .main = undefined,
        .data = .{ .lhs = ident, .rhs = undefined },
    });

    self.expectNext(.lparen);

    var args = std.ArrayList(usize).init(self.gpa);

    while (self.peekTag() != .rparen) {
        try args.append(try self.parseExpr(0));

        if (self.peekTag() != .rparen) {
            self.expectNext(.comma);
        }
    }

    self.expectNext(.rparen);
    self.nodes.items(.data)[call].rhs = try self.addCall(.{ .args = args });

    return call;
}

fn parseDeclare(self: *Self) std.mem.Allocator.Error!usize {
    const ident = try self.parsePrefix();

    if (self.peekTag() == .equal) {
        return self.addNode(.{
            .tag = .assign_stmt,
            .main = self.nextToken(),
            .data = .{ .lhs = ident, .rhs = try self.parseExpr(0) },
        });
    }

    self.expectNext(.colon);

    var type_ident: i32 = -1;
    if (self.peekTag() == .identifier) {
        type_ident = @as(i32, @intCast(self.nextToken()));
    }

    const next = self.nextToken();

    switch (self.tok_tags[next]) {
        .colon, .equal => {
            const expr = try self.parseDeclareExpression();

            if (self.nodes.items(.tag)[expr] == .function_declare) {
                self.nodes.items(.data)[expr].lhs = ident;

                const loc = self.tok_locs[ident];
                const val = self.source[loc.start..loc.end];

                std.debug.print("{s}\n", .{val});

                if (std.mem.eql(u8, val, "main")) {
                    std.debug.print("{d}\n", .{self.nodes.items(.data)[expr].rhs});

                    self.entry = self.nodes.items(.data)[expr].rhs;
                }

                return expr;
            }

            return self.addNode(.{
                .tag = if (self.tok_tags[next] == .colon) .constant_declare else .mutable_declare,
                .main = undefined,
                .data = .{
                    .lhs = ident,
                    .rhs = expr,
                },
            });
        },
        .semicolon => {
            // TODO: create own error types
            if (type_ident == -1) return std.mem.Allocator.Error.OutOfMemory;

            return self.addNode(.{
                .tag = .type_declare,
                .main = undefined,
                .data = .{
                    .lhs = ident,
                    .rhs = @intCast(type_ident),
                },
            });
        },
        else => {
            std.debug.print("{any}\n", .{self.tok_tags[next]});
            @panic("expected constant or mutable declare but got ^");
        },
    }
}

fn parseDeclareExpression(self: *Self) std.mem.Allocator.Error!usize {
    switch (self.peekTag()) {
        .lparen => return self.parseFunc(),
        else => return self.parseExpr(0),
    }
}

// TODO: use actual types instead of identifiers
fn parseFunc(self: *Self) !usize {
    self.expectNext(.lparen);

    var args = std.ArrayList(usize).init(self.gpa);

    while (self.peekTag() == .identifier) {
        const param = self.nextToken();
        self.expectNext(.colon);
        const param_type = self.nextToken();

        try args.append(try self.addNode(.{
            .tag = .type_declare,
            .main = undefined,
            .data = .{
                .lhs = param,
                .rhs = param_type,
            },
        }));

        if (self.peekTag() == .comma) {
            self.expectNext(.comma);
        } else {
            break;
        }
    }

    self.expectNext(.rparen);

    // TODO: implement actual types
    var default_ret_typ: Token.Tag = .identifier;

    if (self.tok_tags[self.nextToken()] == .arrow) {
        default_ret_typ = self.tok_tags[self.nextToken()];
        self.expectNext(.lbrace);
    }

    const body = try self.parseFuncBody();

    return self.addNode(.{
        .tag = .function_declare,
        .main = undefined,
        .data = .{
            .lhs = 0,
            .rhs = try self.addFunc(.{
                .args = args,
                .body = body,
                .return_type = default_ret_typ,
            }),
        },
    });
}

fn parseFuncBody(self: *Self) std.mem.Allocator.Error!std.ArrayList(usize) {
    var body = std.ArrayList(usize).init(self.gpa);

    while (self.peekTag() != .rbrace) {
        try body.append(switch (self.peekTag()) {
            .kw_if => try self.parseCondition(),
            .kw_while => try self.parseWhile(),
            .kw_return => try self.addNode(.{
                .tag = .return_stmt,
                .main = self.nextToken(),
                .data = .{ .lhs = try self.parseExpr(0), .rhs = undefined },
            }),
            .dollar => try self.parseCompMacroCall(),
            .identifier => try self.parseDeclare(),
            else => {
                std.debug.print("{d}\n", .{self.tok_i});
                std.debug.print("{any}\n", .{self.peekTag()});
                @panic("expected string literal but got ^");
            },
        });
    }

    self.expectNext(.rbrace);
    return body;
}

fn parseExpr(self: *Self, prec: u8) std.mem.Allocator.Error!usize {
    var node = try self.parsePrefix();

    while (self.peekTag() != .eof) {
        const tag = self.peekTag();

        if (tag.isBinaryOp() and tag.precedence() >= prec) {
            const binary = self.nextToken();
            const rhs = try self.parseExpr(tag.precedence());

            node = try self.addNode(.{
                .tag = .binary_expr,
                .main = binary,
                .data = .{
                    .lhs = node,
                    .rhs = rhs,
                },
            });

            continue;
        }

        if (self.nodes.items(.tag)[node] == .ident and tag == .lparen) {
            const call = try self.addNode(.{
                .tag = .call_expr,
                .main = self.nextToken(),
                .data = .{ .lhs = node, .rhs = undefined },
            });
            var args = std.ArrayList(usize).init(self.gpa);
            node = call;

            while (self.peekTag() != .rparen) {
                try args.append(try self.parseExpr(0));

                if (self.peekTag() != .rparen) {
                    self.expectNext(.comma);
                }
            }

            self.expectNext(.rparen);
            self.nodes.items(.data)[call].rhs = try self.addCall(.{ .args = args });
            continue;
        }

        break;
    }

    return node;
}

fn parsePrefix(self: *Self) std.mem.Allocator.Error!usize {
    self.checkIndexOutOfBounds("finding leading expr failed");
    const tag = self.peekTag();

    switch (tag) {
        .identifier, .string_lit, .number_lit => {
            return self.addNode(.{
                .tag = if (tag == .string_lit) .str_expr else if (tag == .number_lit) .num_expr else .ident,
                .main = self.nextToken(),
                .data = undefined,
            });
        },
        else => {},
    }

    if (tag.isUnaryOp()) {
        const unary = self.nextToken();
        const node = try self.parsePrefix();

        return self.addNode(.{
            .tag = .unary_expr,
            .main = unary,
            .data = .{
                .lhs = node,
                .rhs = undefined,
            },
        });
    }

    std.debug.print("{any}\n", .{tag});
    // TODO: replace with unit type or void
    _ = self.nextToken();
    return 0;
}
