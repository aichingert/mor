const std = @import("std");
const lexer = @import("ast/lexer.zig");
const parser = @import("ast/parser.zig");

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

    var m_parser = parser.Parser.new(data);
    var i: usize = 0;

    while (i < 3) {
        std.debug.print("{}\n", .{m_parser.get(i)});
        i += 1;
    }
}
