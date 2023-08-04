const std = @import("std");
const list = @import("utils/structures/list.zig");
const print = std.debug.print;

pub const TokenType = enum { Let, Assign, Semicolon, Ident };

pub const Token = union(TokenType) {
    Let: void,
    Assign: void,
    Semicolon: void,
    Ident: []const u8,
};

pub fn show(token: Token) void {
    switch (token) {
        .Assign => print("=", .{}),
        .Semicolon => print(";", .{}),
        .Let => print("let", .{}),
        .Ident => |ident| print("{s}", .{ident}),
    }
}

pub const Lexer = struct {
    token_stream: []u8,
    index: u16,

    pub fn lex(self: *Lexer) void {
        const L = list.List(Token);
        var tokens = L{};

        while (self.index < self.token_stream.len) {
            const idx = self.index;

            switch (self.token_stream[idx]) {
                '\n', ' ' => {},
                ':' => {
                    const node = std.heap.page_allocator.create(L.Node) catch {
                        return;
                    };
                    node.* = L.Node{
                        .data = Token.Assign,
                    };
                    tokens.pushBack(node);
                },
                ';' => {
                    const node = std.heap.page_allocator.create(L.Node) catch {
                        return;
                    };
                    node.* = L.Node{
                        .data = Token.Semicolon,
                    };
                    tokens.pushBack(node);
                },
                else => {},
            }

            self.index += 1;
        }

        var it: ?*L.Node = tokens.head;

        print("{d}\n", .{tokens.len});

        while (it) |node| : (it = node.next) {
            show(node.data);
        }
    }
};
