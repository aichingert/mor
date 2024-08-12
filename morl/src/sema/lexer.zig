const std = @import("std");

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const Tag = enum {
        number_lit,
        string_lit,
        plus,
        minus,
        slash,
        asterisk,
        invalid,
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
        return self.index + 1 < self.source.len and self.source[self.index + 1] >= '0' and self.source[self.index + 1] <= '9';
    }

    // zig fmt: off
    fn is_string(self: *Self) bool {
        return self.index + 1 < self.source.len and 
            (self.source[self.index + 1] >= 'a' and self.source[self.index + 1] <= 'z')
            or
            (self.source[self.index + 1] >= 'A' and self.source[self.index + 1] <= 'Z')
            or 
            self.source[self.index + 1] == '_';
    }
    // zig fmt: on

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
                    self.index += 1;
                    result.loc.end = self.index;
                    return result;
                },
                '-' => {
                    result.tag = .minus;
                    self.index += 1;
                    result.loc.end = self.index;
                    return result;
                },
                '/' => {
                    result.tag = .slash;
                    self.index += 1;
                    result.loc.end = self.index;
                    return result;
                },
                '*' => {
                    result.tag = .asterisk;
                    self.index += 1;
                    result.loc.end = self.index;
                    return result;
                },
                '0'...'9' => {
                    while (self.is_number()) : (self.index += 1) {}
                    result.tag = .number_lit;
                    self.index += 1;
                    result.loc.end = self.index;
                    return result;
                },
                'a'...'z', 'A'...'Z' => {
                    while (self.is_string()) : (self.index += 1) {}
                    result.tag = .string_lit;
                    result.loc.end = self.index;
                    return result;
                },
                ' ', '\n' => result.loc.start = self.index + 1,
                else => {
                    @panic("internal lexer panic");
                },
            }
        }

        return result;
    }
};
