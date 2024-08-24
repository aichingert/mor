const std = @import("std");

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const Tag = enum {
        identifier,
        number_lit,
        string_lit,
        plus,
        minus,
        slash,
        asterisk,

        lparen,
        rparen,
        lbrace,
        rbrace,
        lbracket,
        rbracket,

        equal,
        colon,
        comma,

        kw_fn,
        kw_return,

        invalid,
        eof,

        pub fn isUnaryOp(self: Tag) bool {
            return switch (self) {
                .minus => true,
                else => false,
            };
        }

        pub fn isBinaryOp(self: Tag) bool {
            return switch (self) {
                .plus, .minus, .slash, .asterisk => true,
                else => false,
            };
        }

        pub fn precedence(self: Tag) u8 {
            return switch (self) {
                .minus, .plus => 10,
                .slash, .asterisk => 20,
                else => {
                    std.debug.print("{any}\n", .{self});
                    @panic("tag has no precedence");
                },
            };
        }
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

    // zig fmt: off
    fn is_number(self: *Self) bool {
        return self.index + 1 < self.source.len 
            and self.source[self.index + 1] >= '0' 
            and self.source[self.index + 1] <= '9';
    }

    fn is_within_string(self: *Self) bool {
        return self.index < self.source.len and self.source[self.index] != '"';
    }

    fn is_identifier(self: *Self) bool {
        return self.index + 1 < self.source.len and 
            (self.source[self.index + 1] >= 'a' and self.source[self.index + 1] <= 'z')
            or
            (self.source[self.index + 1] >= 'A' and self.source[self.index + 1] <= 'Z')
            or 
            self.source[self.index + 1] == '_' or self.is_number();
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
                ':' => {
                    result.tag = .colon;
                    self.index += 1;
                    result.loc.end = self.index;
                    return result;
                },
                '=' => {
                    result.tag = .equal;
                    self.index += 1;
                    result.loc.end = self.index;
                    return result;
                },
                ',' => {
                    result.tag = .comma;
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
                '"' => {
                    self.index += 1;

                    while (self.is_within_string()) : (self.index += 1) {}
                    result.tag = .string_lit;
                    self.index += 1;
                    result.loc.end = self.index;
                    return result;
                },
                '(' => {
                    result.tag = .lparen;
                    self.index += 1;
                    result.loc.end = self.index;
                    return result;
                },
                ')' => {
                    result.tag = .rparen;
                    self.index += 1;
                    result.loc.end = self.index;
                    return result;
                },
                '{' => {
                    result.tag = .lbrace;
                    self.index += 1;
                    result.loc.end = self.index;
                    return result;
                },
                '}' => {
                    result.tag = .rbrace;
                    self.index += 1;
                    result.loc.end = self.index;
                    return result;
                },
                ' ', '\n' => result.loc.start = self.index + 1,
                'a'...'z', 'A'...'Z' => {
                    while (self.is_identifier()) : (self.index += 1) {}
                    result.tag = .identifier;
                    self.index += 1;
                    result.loc.end = self.index;

                    const eql = std.mem.eql;

                    if (eql(u8, self.source[result.loc.start..result.loc.end], "fn")) {
                        result.tag = .kw_fn;
                    } else if (eql(u8, self.source[result.loc.start..result.loc.end], "return")) {
                        result.tag = .kw_return;
                    }

                    return result;
                },
                else => {
                    std.debug.print("{any}\n", .{self.source[self.index]});
                    @panic("internal lexer panic");
                },
            }
        }

        return result;
    }
};
