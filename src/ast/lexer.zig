const std = @import("std");
const print = std.debug.print;

pub const Token = union(enum) {
    ident: []const u8,
    number: i64,

    plus,
    minus,
    slash,
    star,

    eof,
    invalid,
};

pub const Lexer = struct {
    const Self = @This();

    position: usize = 0,
    pointer: usize = 0,
    cur: u8 = 0,
    input: []const u8,

    pub fn init(input: []const u8) Self {
        print("{s}\n", .{input});
        var lex = Self{
            .input = input,
        };

        lex.read_char();
        return lex;
    }

    pub fn next_token(self: *Self) Token {
        while (self.cur == ' ') {
            self.read_char();
        }

        print("WHY {} \n", .{self.cur});
        var token: Token = switch (self.cur) {
            '+' => Token.plus,
            '-' => Token.minus,
            '/' => Token.slash,
            '*' => Token.star,
            '0'...'9' => {
                const number = std.fmt.parseInt(i64, self.read_number(), 10) catch |err| {
                    print("ERR: {}\n", .{err});
                    return Token.invalid;
                };
                return .{ .number = number };
            },
            else => return Token.eof,
        };

        print("{} \n", .{token});
        self.read_char();
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

    fn read_number(self: *Self) []const u8 {
        const start: usize = self.position;

        while (std.ascii.isAlphanumeric(self.cur)) {
            self.read_char();
        }

        return self.input[start..self.position];
    }
};
