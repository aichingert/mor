const std = @import("std");
const print = std.debug.print;

pub const Token = union(enum) {
    ident: []const u8,
    assign,
    semicolon,

    eof,
    invalid,
};

pub fn show(token: Token) void {
    switch (token) {
        .assign => print("\n=\n", .{}),
        .semicolon => print("\n;\n", .{}),
        .eof => print("\neof\n", .{}),
        .invalid => print("inv", .{}),
        .ident => |ident| print("ident[ {s} ]", .{ident}),
    }
}

pub const Lexer = struct {
    const Self = @This();

    position: usize = 0,
    pointer: usize = 0,
    cur: u8 = 0,
    input: []const u8,

    pub fn init(input: []const u8) Self {
        var lex = Self{
            .input = input,
        };

        lex.read_char();

        return lex;
    }

    pub fn next_token(self: *Self) Token {
        self.skip_whitespace();
        print("{c}\n", .{self.cur});
        var token: Token = switch (self.cur) {
            ':' => blk: {
                self.read_char();
                if (self.peak_char() == '=') {
                    break :blk .assign;
                } else {
                    break :blk .invalid;
                }
            },
            'a'...'z', 'A'...'Z', '_' => {
                const ident = self.read_identifier();
                return .{ .ident = ident };
            },
            else => return Token.eof,
        };

        return token;
    }

    fn read_char(self: *Self) void {
        if (self.pointer >= self.input.len) {
            self.cur = 0;
        } else {
            self.cur = self.input[self.pointer];
        }

        self.position = self.pointer;
        self.pointer += 1;
    }

    fn peak_char(self: *Self) u8 {
        if (self.pointer >= self.input.len) {
            return 0;
        } else {
            return self.input[self.pointer];
        }
    }

    fn read_identifier(self: *Self) []const u8 {
        const start: usize = self.position;

        while (std.ascii.isAlphabetic(self.cur) or self.cur == '_') {
            self.read_char();
        }

        return self.input[start..self.position];
    }

    fn skip_whitespace(self: *Self) void {
        while (std.ascii.isWhitespace(self.cur)) {
            self.read_char();
        }
    }
};
