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
        semicolon,

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

    fn genToken(self: *Self, tag: Token.Tag, start: usize) Token {
        self.index += 1;

        return .{
            .tag = tag,
            .loc = .{
                .start = start,
                .end = self.index,
            },
        };
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
            return switch (self.source[self.index]) {
                '+' => self.genToken(.plus, result.loc.start),
                '-' => self.genToken(.minus, result.loc.start),
                '/' => self.genToken(.slash, result.loc.start),
                '*' => self.genToken(.asterisk, result.loc.start),
                ':' => self.genToken(.colon, result.loc.start),
                ';' => self.genToken(.semicolon, result.loc.start),
                '=' => self.genToken(.equal, result.loc.start),
                ',' => self.genToken(.comma, result.loc.start),
                '(' => self.genToken(.lparen, result.loc.start),
                ')' => self.genToken(.rparen, result.loc.start),
                '{' => self.genToken(.lbrace, result.loc.start),
                '}' => self.genToken(.rbrace, result.loc.start),
                '0'...'9' => {
                    while (self.is_number()) : (self.index += 1) {}
                    return self.genToken(.number_lit, result.loc.start);
                },
                '"' => {
                    self.index += 1;

                    while (self.is_within_string()) : (self.index += 1) {}
                    return self.genToken(.string_lit, result.loc.start);
                },
                'a'...'z', 'A'...'Z' => {
                    while (self.is_identifier()) : (self.index += 1) {}
                    var token = self.genToken(.identifier, result.loc.start);
                    const eql = std.mem.eql;

                    if (eql(u8, self.source[token.loc.start..token.loc.end], "fn")) {
                        token.tag = .kw_fn;
                    } else if (eql(u8, self.source[token.loc.start..token.loc.end], "return")) {
                        token.tag = .kw_return;
                    }

                    return token;
                },
                ' ', '\n' => {
                    result.loc.start = self.index + 1;
                    continue;
                },
                else => {
                    std.debug.print("{any}\n", .{self.source[self.index]});
                    @panic("internal lexer panic");
                },
            };
        }

        return result;
    }
};
