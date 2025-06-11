const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Ast = @import("Ast.zig");
const Token = @import("Lexer.zig").Token;

const Self = @This();

pos: usize,
gpa: Allocator,
toks: *const ArrayList(Token),

pub const ParseError = error {
    InvalidToken,
    AllocatorError,
};

fn assert_inc(self: *Self, kind: Token.Tag) ParseError!void {
    defer self.pos += 1;
    const tag = (try self.token()).tag;

    if (tag != kind) {
        return ParseError.InvalidToken;
    }
}

fn token(self: *Self) ParseError!Token {
    if (self.pos >= self.toks.items.len) {
        return ParseError.InvalidToken;
    }

    return self.toks.items[self.pos];
}

pub fn from_tokens(gpa: Allocator, toks: *const ArrayList(Token)) ParseError!Ast {
    const ast = Ast {
        .stmts = ArrayList(Ast.Stmt).init(gpa),
        .funcs = ArrayList(Ast.Func).init(gpa),
        .vars = ArrayList(Ast.Var).init(gpa),
    };

    var parser: Self = .{
        .pos = 0,
        .gpa = gpa,
        .toks = toks,
    };

    while (true) {
        var tag = (try parser.token()).tag;
        if (tag == .eof) {
            return ast;
        }

        const id = parser.pos;
        try parser.assert_inc(.identifier);
        try parser.assert_inc(.colon);
        try parser.assert_inc(.colon);

        tag = (try parser.token()).tag;

        switch (tag) {
            .lparen => {
                const func = try parser.consume_func(id);
                _ = func;
            },
            else => return ParseError.InvalidToken,
        }
    }
}

fn consume_func(self: *Self, ident: usize) ParseError!Ast.Func {
    try self.assert_inc(.lparen);

    // consume arguments


    _ = ident;
    return ParseError.InvalidToken;
}

// gpa: std.mem.Allocator,
// 
// tok_i: usize,
// tok_tags: []const Token.Tag,
// tok_locs: []const Token.Loc,
// 
// source: []const u8,
// nodes: Ast.NodeList,
// funcs: Ast.FuncList,
// calls: std.ArrayList(Ast.Call),
// conds: std.ArrayList(Ast.Cond),
// loops: std.ArrayList(Ast.Loop),
// stmts: std.ArrayList(usize),
// arras: std.ArrayList(Ast.Array),
// func_res: std.StringHashMap(usize),
// 
// 
// 
// 
// pub fn init(
//     gpa: std.mem.Allocator,
//     source: []const u8,
//     tok_tags: []const Token.Tag,
//     tok_locs: []const Token.Loc,
// ) Self {
//     return .{
//         .gpa = gpa,
//         .tok_i = 0,
//         .tok_tags = tok_tags,
//         .tok_locs = tok_locs,
//         .stmts = std.ArrayList(usize).init(gpa),
//         .conds = std.ArrayList(Ast.Cond).init(gpa),
//         .loops = std.ArrayList(Ast.Loop).init(gpa),
//         .calls = std.ArrayList(Ast.Call).init(gpa),
//         .arras = std.ArrayList(Ast.Array).init(gpa),
//         .nodes = Ast.NodeList{},
//         .funcs = Ast.FuncList{},
//         .func_res = std.StringHashMap(usize).init(gpa),
//         .source = source,
//     };
// }
// 
// pub fn deinit(self: *Self) void {
//     self.nodes.deinit(self.gpa);
// }
// 
// fn peekTag(self: *Self) Token.Tag {
//     return self.tok_tags[self.tok_i];
// }
// 
// fn nextToken(self: *Self) usize {
//     self.tok_i += 1;
//     return self.tok_i - 1;
// }
// 
// fn expectNext(self: *Self, tag: Token.Tag) void {
//     if (self.tok_tags[self.nextToken()] != tag) {
//         std.debug.print("expected {any} got {any}\n", .{ tag, self.tok_tags[self.tok_i - 1] });
//         std.debug.print("error happened at {any}:{any}\n", .{
//             self.tok_locs[self.tok_i - 1].start,
//             self.tok_locs[self.tok_i - 1].end,
//         });
//         @panic("Expect next failed.");
//     }
// }
// 
// fn checkIndexOutOfBounds(self: *Self, msg: []const u8) void {
//     if (self.tok_i >= self.tok_tags.len) @panic(msg);
// }
// 
// fn addNode(self: *Self, node: Ast.Node) std.mem.Allocator.Error!usize {
//     try self.nodes.append(self.gpa, node);
//     return self.nodes.len - 1;
// }
// 
// fn addFunc(self: *Self, func: Ast.Func) std.mem.Allocator.Error!usize {
//     try self.funcs.append(self.gpa, func);
//     return self.funcs.len - 1;
// }
// 
// fn addCall(self: *Self, call: Ast.Call) std.mem.Allocator.Error!usize {
//     try self.calls.append(call);
//     return self.calls.items.len - 1;
// }
// 
// fn addCond(self: *Self, cond: Ast.Cond) std.mem.Allocator.Error!usize {
//     try self.conds.append(cond);
//     return self.conds.items.len - 1;
// }
// 
// fn addLoop(self: *Self, loop: Ast.Loop) std.mem.Allocator.Error!usize {
//     try self.loops.append(loop);
//     return self.loops.items.len - 1;
// }
// 
// fn addArray(self: *Self, array: Ast.Array) std.mem.Allocator.Error!usize {
//     try self.arras.append(array);
//     return self.arras.items.len - 1;
// }
// 
// pub fn parse(self: *Self) std.mem.Allocator.Error!void {
//     while (self.peekTag() != .eof) {
//         var res: usize = std.math.maxInt(usize);
// 
//         switch (self.peekTag()) {
//             .identifier => {
//                 res = try self.parseDeclare();
// 
//                 if (self.nodes.items(.tag)[res] != .function_declare) {
//                     continue;
//                 }
// 
//                 const ident = self.nodes.items(.main)[self.nodes.items(.data)[res].lhs];
//                 const loc = self.tok_locs[ident];
//                 const val = self.source[loc.start..loc.end];
// 
//                 try self.func_res.put(val, res);
//             },
//             else => {
//                 std.debug.print("ERROR(parser/stmt): invalid tag for stmt begin [{any}]", .{self.peekTag()});
//                 @panic("ERROR(parser/stmt): only ident is valid stmt begin");
//             },
//         }
// 
//         try self.stmts.append(res);
//     }
// }
// 
// fn parseCondition(self: *Self) std.mem.Allocator.Error!usize {
//     self.expectNext(.kw_if);
// 
//     const expr = try self.parseExpr(0);
//     self.expectNext(.lbrace);
//     const body = try self.parseBody();
//     var elif_ex = std.ArrayList(usize).init(self.gpa);
//     var el_body = std.ArrayList(usize).init(self.gpa);
// 
//     while (self.peekTag() == .kw_elif) {
//         self.expectNext(.kw_elif);
//         const elif_expr = try self.parseExpr(0);
//         self.expectNext(.lbrace);
//         const elif_body = try self.parseBody();
// 
//         try elif_ex.append(try self.addCond(.{
//             .if_cond = elif_expr,
//             .if_body = elif_body,
//             .elif_ex = undefined,
//             .el_body = undefined,
//         }));
//     }
// 
//     if (self.peekTag() == .kw_else) {
//         self.expectNext(.kw_else);
//         self.expectNext(.lbrace);
// 
//         el_body.deinit();
//         el_body = try self.parseBody();
//     }
// 
//     return self.addNode(.{
//         .tag = .if_expr,
//         .main = undefined,
//         .data = .{
//             .lhs = try self.addCond(.{
//                 .if_cond = expr,
//                 .if_body = body,
//                 .elif_ex = elif_ex,
//                 .el_body = el_body,
//             }),
//             .rhs = undefined,
//         },
//     });
// }
// 
// fn parseWhile(self: *Self) std.mem.Allocator.Error!usize {
//     self.expectNext(.kw_while);
// 
//     const cond = try self.parseExpr(0);
// 
//     self.expectNext(.lbrace);
//     const body = try self.parseBody();
// 
//     return self.addNode(.{
//         .tag = .while_expr,
//         .main = undefined,
//         .data = .{
//             .lhs = try self.addLoop(.{
//                 .cond = cond,
//                 .body = body,
//             }),
//             .rhs = undefined,
//         },
//     });
// }
// 
// fn parseCompMacroCall(self: *Self) std.mem.Allocator.Error!usize {
//     self.expectNext(.dollar);
//     const ident = try self.parsePrefix();
// 
//     const call = try self.addNode(.{
//         .tag = .macro_call_expr,
//         .main = undefined,
//         .data = .{ .lhs = ident, .rhs = undefined },
//     });
// 
//     self.expectNext(.lparen);
// 
//     var args = std.ArrayList(usize).init(self.gpa);
// 
//     while (self.peekTag() != .rparen) {
//         try args.append(try self.parseExpr(0));
// 
//         if (self.peekTag() != .rparen) {
//             self.expectNext(.comma);
//         }
//     }
// 
//     self.expectNext(.rparen);
//     self.nodes.items(.data)[call].rhs = try self.addCall(.{ .args = args });
// 
//     return call;
// }
// 
// fn parseDeclare(self: *Self) std.mem.Allocator.Error!usize {
//     const node = try self.parseExpr(0);
// 
//     if (self.nodes.items(.tag)[node] == .call_expr) {
//         return node;
//     }
// 
//     if (self.peekTag() == .equal) {
//         return self.addNode(.{
//             .tag = .assign_stmt,
//             .main = self.nextToken(),
//             .data = .{ .lhs = node, .rhs = try self.parseExpr(0) },
//         });
//     }
// 
//     self.expectNext(.colon);
// 
//     var type_ident: i32 = -1;
//     if (self.peekTag() == .identifier) {
//         type_ident = @as(i32, @intCast(self.nextToken()));
//     }
// 
//     const next = self.nextToken();
//     switch (self.tok_tags[next]) {
//         .colon, .equal => {
//             const expr = try self.parseDeclareExpression();
// 
//             if (self.nodes.items(.tag)[expr] == .function_declare) {
//                 self.nodes.items(.data)[expr].lhs = node;
//                 return expr;
//             }
// 
//             return self.addNode(.{
//                 .tag = if (self.tok_tags[next] == .colon) .constant_declare else .mutable_declare,
//                 .main = undefined,
//                 .data = .{
//                     .lhs = node,
//                     .rhs = expr,
//                 },
//             });
//         },
//         .semicolon => {
//             // TODO: create own error types
//             if (type_ident == -1) return std.mem.Allocator.Error.OutOfMemory;
// 
//             return self.addNode(.{
//                 .tag = .type_declare,
//                 .main = undefined,
//                 .data = .{
//                     .lhs = node,
//                     .rhs = @intCast(type_ident),
//                 },
//             });
//         },
//         else => {
//             @panic("expected constant or mutable declare but got ^");
//         },
//     }
// }
// 
// fn parseDeclareExpression(self: *Self) std.mem.Allocator.Error!usize {
//     switch (self.peekTag()) {
//         .identifier => {
//             const val = self.source[self.tok_locs[self.tok_i].start..self.tok_locs[self.tok_i].end];
// 
//             if (!std.mem.eql(u8, val, "fn")) {
//                 return self.parseExpr(0);
//             }
// 
//             self.expectNext(.identifier);
//             return self.parseFunc();
//         },
//         else => return self.parseExpr(0),
//     }
// }
// 
// // TODO: use actual types instead of identifiers
// fn parseFunc(self: *Self) !usize {
//     self.expectNext(.lparen);
// 
//     var args = std.ArrayList(usize).init(self.gpa);
// 
//     while (self.peekTag() == .identifier) {
//         const param = self.nextToken();
//         self.expectNext(.colon);
//         const param_type = self.nextToken();
// 
//         try args.append(try self.addNode(.{
//             .tag = .type_declare,
//             .main = undefined,
//             .data = .{
//                 .lhs = param,
//                 .rhs = param_type,
//             },
//         }));
// 
//         if (self.peekTag() == .comma) {
//             self.expectNext(.comma);
//         } else {
//             break;
//         }
//     }
// 
//     self.expectNext(.rparen);
// 
//     // TODO: implement actual types
//     var default_ret_typ: Token.Tag = .invalid;
// 
//     if (self.tok_tags[self.nextToken()] == .arrow) {
//         default_ret_typ = self.tok_tags[self.nextToken()];
//         self.expectNext(.lbrace);
//     }
// 
//     const body = try self.parseBody();
// 
//     return self.addNode(.{
//         .tag = .function_declare,
//         .main = undefined,
//         .data = .{
//             .lhs = 0,
//             .rhs = try self.addFunc(.{
//                 .args = args,
//                 .body = body,
//                 .return_type = default_ret_typ,
//             }),
//         },
//     });
// }
// 
// fn parseArray(self: *Self) !usize {
//     self.expectNext(.lbracket);
// 
//     var array: Ast.Array = .{
//         .elements = std.ArrayList(usize).init(self.gpa),
//     };
// 
//     while (self.peekTag() != .eof) {
//         try array.elements.append(try self.parseExpr(0));
// 
//         if (self.peekTag() == .comma) {
//             self.expectNext(.comma);
//         } else {
//             break;
//         }
//     }
// 
//     self.expectNext(.rbracket);
//     return try self.addArray(array);
// }
// 
// fn parseBody(self: *Self) std.mem.Allocator.Error!std.ArrayList(usize) {
//     var body = std.ArrayList(usize).init(self.gpa);
// 
//     while (self.peekTag() != .rbrace) {
//         try body.append(switch (self.peekTag()) {
//             .kw_if => try self.parseCondition(),
//             .kw_while => try self.parseWhile(),
//             .kw_return => try self.addNode(.{
//                 .tag = .return_stmt,
//                 .main = self.nextToken(),
//                 .data = .{ .lhs = try self.parseExpr(0), .rhs = undefined },
//             }),
//             .dollar => try self.parseCompMacroCall(),
//             .identifier => try self.parseDeclare(),
//             else => {
//                 std.debug.print("{any}\n", .{self.peekTag()});
//                 @panic("expected string literal but got ^");
//             },
//         });
//     }
// 
//     self.expectNext(.rbrace);
//     return body;
// }
// 
// fn parseExpr(self: *Self, prec: u8) std.mem.Allocator.Error!usize {
//     var node = try self.parsePrefix();
// 
//     if (node == std.math.maxInt(usize)) {
//         return node;
//     }
// 
//     while (self.peekTag() != .eof) {
//         const tag = self.peekTag();
// 
//         if (tag.isBinaryOp() and tag.precedence() > prec) {
//             const binary = self.nextToken();
//             const rhs = try self.parseExpr(tag.precedence());
// 
//             node = try self.addNode(.{
//                 .tag = .binary_expr,
//                 .main = binary,
//                 .data = .{
//                     .lhs = node,
//                     .rhs = rhs,
//                 },
//             });
// 
//             continue;
//         }
// 
//         if (self.nodes.items(.tag)[node] == .ident and tag == .lparen) {
//             const call = try self.addNode(.{
//                 .tag = .call_expr,
//                 .main = self.nextToken(),
//                 .data = .{ .lhs = node, .rhs = undefined },
//             });
//             var args = std.ArrayList(usize).init(self.gpa);
//             node = call;
// 
//             while (self.peekTag() != .rparen) {
//                 try args.append(try self.parseExpr(0));
// 
//                 if (self.peekTag() != .rparen) {
//                     self.expectNext(.comma);
//                 }
//             }
// 
//             self.expectNext(.rparen);
//             self.nodes.items(.data)[call].rhs = try self.addCall(.{ .args = args });
//             continue;
//         }
// 
//         if (self.nodes.items(.tag)[node] == .ident and tag == .lbracket) {
//             const bracket = self.nextToken();
// 
//             const eval = try self.parseExpr(0);
//             node = try self.addNode(.{
//                 .tag = .index_expr,
//                 .main = bracket,
//                 .data = .{
//                     .lhs = node,
//                     .rhs = eval,
//                 },
//             });
// 
//             self.expectNext(.rbracket);
//             continue;
//         }
// 
//         break;
//     }
// 
//     return node;
// }
// 
// fn parsePrefix(self: *Self) std.mem.Allocator.Error!usize {
//     self.checkIndexOutOfBounds("finding leading expr failed");
//     const tag = self.peekTag();
// 
//     switch (tag) {
//         .identifier, .string_lit, .number_lit => {
//             return self.addNode(.{
//                 .tag = if (tag == .string_lit)
//                     .str_expr
//                 else if (tag == .number_lit)
//                     .num_expr
//                 else
//                     .ident,
//                 .main = self.nextToken(),
//                 .data = undefined,
//             });
//         },
//         .lbracket => return self.addNode(.{
//             .tag = .array_declare,
//             .main = try self.parseArray(),
//             .data = undefined,
//         }),
//         .lparen => {
//             self.expectNext(.lparen);
//             const expr = try self.parseExpr(0);
//             self.expectNext(.rparen);
// 
//             return self.addNode(.{
//                 .tag = .paren_expr,
//                 .main = expr,
//                 .data = undefined,
//             });
//         },
//         else => {},
//     }
// 
//     if (tag.isUnaryOp()) {
//         const unary = self.nextToken();
//         const node = try self.parsePrefix();
// 
//         return self.addNode(.{
//             .tag = .unary_expr,
//             .main = unary,
//             .data = .{
//                 .lhs = node,
//                 .rhs = undefined,
//             },
//         });
//     }
// 
//     // TODO: replace with unit type or void
//     // _ = self.nextToken();
//     return std.math.maxInt(usize);
// }
