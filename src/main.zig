const std = @import("std");
const lexer = @import("ast/lexer.zig");

pub fn get_input() ![]u8 {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var buf: [100]u8 = undefined;

    try stdout.print("> ", .{});

    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
        return user_input;
    } else {
        return "";
    }
}

pub fn main() !void {
    const data = try get_input();

    var m_lexer = lexer.Lexer.init(data);

    var token: lexer.Token = m_lexer.next_token();

    while (token != lexer.Token.eof) {
        //lexer.show(token);
        std.debug.print("{}\n", .{token});
        token = m_lexer.next_token();
    }
    std.debug.print("{}\n", .{token});
}
