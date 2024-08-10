const std = @import("std");

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const Tag = enum {
        plus,
        minus,
        slash,
        asterisk,
        invalid,
        number_literal,
        eof,
    };
};

pub const Lexer = struct {
    source: []const u8,
    index: usize,

    const Self = @This();

    pub fn init(source: []const u8) Lexer {
        return .{
            .source = source,
            .index = 0,
        };
    }

    pub fn next(self: *Self) Token {
        var result: Token = .{
            .tag = .eof,
            .loc = .{
                .start = self.index,
                .end = self.index,
            },
        };

        while (self.index < self.source.len) : (self.index += 1) {
            std.debug.print("{d}\n", .{self.index});

            switch (self.source[self.index]) {
                '+' => {
                    result.tag = .plus;
                    result.loc.end = self.index;
                    return result;
                },
                '-' => {},
                '/' => {},
                '*' => {},
                '0'...'9' => {},
                ' ', '\n' => {},
                else => {
                    std.debug.print("{d}\n", .{self.source[self.index]});
                    @panic("internal lexer panic");
                },
            }
        }

        return result;
    }
};
