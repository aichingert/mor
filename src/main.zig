const std = @import("std");
const lexer = @import("lexer.zig");

pub fn main() !void {
    var buffer: [1024]u8 = undefined;
    const data = try std.fs.cwd().readFile("foo.txt", &buffer);

    var m_lexer = lexer.Lexer.init(data);

    var token: lexer.Token = m_lexer.next_token();

    while (token != lexer.Token.eof) {
        lexer.show(token);
        token = m_lexer.next_token();
    }
}
