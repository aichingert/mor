const std = @import("std");
const lexer = @import("lexer.zig");

pub fn main() !void {
    var buffer: [1024]u8 = undefined;
    const data = try std.fs.cwd().readFile("foo.txt", &buffer);

    (lexer.Lexer{ .token_stream = data, .index = 0 }).lex();
}
