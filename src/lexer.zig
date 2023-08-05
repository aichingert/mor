const std = @import("std");
const list = @import("utils/structures/list.zig");
const print = std.debug.print;

const TokenList = list.List(Token);

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
        var tokens: TokenList = TokenList{};
        while (self.index < self.token_stream.len) {
            const idx = self.index;

            switch (self.token_stream[idx]) {
                '\n', ' ' => {},
                ';' => Lexer.append_token(&tokens, Token.Semicolon) catch {
                    return;
                },
                else => {
                    var buf: [512]u8 = .{};
                    var src: usize = 0;

                    while (self.token_stream[src] != '\n' and self.token_stream[src] != ' ') {
                        buf[src] = self.token_stream[src];
                        src += 1;
                    }

                    print("{s} \n", .{buf[0..10]});
                },
            }

            self.index += 1;
        }
    }

    fn append_token(token_list: *TokenList, token: Token) !void {
        const node = try std.heap.page_allocator.create(TokenList.Node);
        node.* = TokenList.Node{
            .data = token,
        };
        token_list.pushBack(node);
    }
};
