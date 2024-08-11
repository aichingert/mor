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
        number,
        eof,
    };
};

pub const Lexer = struct {
    source: []const u8,
    index: usize,

    const Self = @This();

    pub fn init(source: []const u8) Self {
        return .{
            .source = source,
            .index = 0,
        };
    }

    fn is_number(self: *Self) bool {
        return self.index < self.source.len and self.source[self.index] >= '0' and self.source[self.index] <= '9';
    }

    pub fn next(self: *Self) Token {
        var result: Token = .{
            .tag = .eof,
            .loc = .{
                .start = self.index,
                .end = self.index + 1,
            },
        };

        while (self.index < self.source.len) : (self.index += 1) {
            switch (self.source[self.index]) {
                '+' => {
                    result.tag = .plus;
                    result.loc.end = self.index;
                    self.index += 1;
                    return result;
                },
                '-' => {
                    result.tag = .minus;
                    result.loc.end = self.index;
                    self.index += 1;
                    return result;
                },
                '/' => {
                    result.tag = .slash;
                    result.loc.end = self.index;
                    self.index += 1;
                    return result;
                },
                '*' => {
                    result.tag = .asterisk;
                    result.loc.end = self.index;
                    self.index += 1;
                    return result;
                },
                '0'...'9' => {
                    while (self.is_number()) : (self.index += 1) {}
                    result.tag = .number;
                    result.loc.end = self.index - 1;
                    return result;
                },
                ' ', '\n' => result.loc.start = self.index,
                else => {
                    std.debug.print("{d}\n", .{self.source[self.index]});
                    @panic("internal lexer panic");
                },
            }
        }

        return result;
    }
};
