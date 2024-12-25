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

        eq,
        not_eq,
        less,
        less_eq,
        greater,
        greater_eq,

        not,
        plus,
        minus,
        slash,
        asterisk,
        dollar,

        xor,
        bit_or,
        con_or,

        bit_and,
        con_and,

        lparen,
        rparen,
        lbrace,
        rbrace,
        lbracket,
        rbracket,

        arrow,
        equal,
        colon,
        comma,
        semicolon,

        kw_if,
        kw_elif,
        kw_else,
        kw_while,
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
                .xor,
                .not,
                .plus,
                .minus,
                .slash,
                .asterisk,
                .con_or,
                .con_and,
                .eq,
                .not_eq,
                .less,
                .less_eq,
                .greater,
                .greater_eq,
                => true,
                else => false,
            };
        }

        pub fn precedence(self: Tag) u8 {
            return switch (self) {
                .con_or => 10,
                .con_and => 20,
                .eq, .not_eq, .less, .less_eq, .greater, .greater_eq => 30,
                .not, .xor => 35,
                .minus, .plus => 40,
                .slash, .asterisk => 60,
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
    fn isNumber(self: *Self) bool {
        return self.index + 1 < self.source.len 
            and self.source[self.index + 1] >= '0' 
            and self.source[self.index + 1] <= '9';
    }

    fn isWithinString(self: *Self) bool {
        return self.index < self.source.len and self.source[self.index] != '"';
    }

    fn isIdentifier(self: *Self) bool {
        return self.index + 1 < self.source.len and 
            (self.source[self.index + 1] >= 'a' and self.source[self.index + 1] <= 'z')
            or
            (self.source[self.index + 1] >= 'A' and self.source[self.index + 1] <= 'Z')
            or 
            self.source[self.index + 1] == '_' or self.isNumber();
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

    fn genTokenIfNextIs(
        self: *Self,
        next: u8,
        then: Token.Tag,
        otherwise: Token.Tag,
        start: usize,
    ) Token {
        var default = self.genToken(otherwise, start);

        if (self.index >= self.source.len) {
            return default;
        }

        if (self.source[self.index] == next) {
            self.index += 1;
            default.tag = then;
            default.loc.end = self.index;
        }

        return default;
    }

    pub fn genNext(self: *Self) Token {
        var result: Token = .{
            .tag = .eof,
            .loc = .{
                .start = self.index,
                .end = self.index + 1,
            },
        };

        while (self.index < self.source.len) : (self.index += 1) {
            return switch (self.source[self.index]) {
                '^' => self.genToken(.xor, result.loc.start),
                '+' => self.genToken(.plus, result.loc.start),
                '/' => self.genToken(.slash, result.loc.start),
                '*' => self.genToken(.asterisk, result.loc.start),
                ':' => self.genToken(.colon, result.loc.start),
                ';' => self.genToken(.semicolon, result.loc.start),
                ',' => self.genToken(.comma, result.loc.start),
                '(' => self.genToken(.lparen, result.loc.start),
                ')' => self.genToken(.rparen, result.loc.start),
                // credits: @Austromo <3
                // late night session :)
                '[' => self.genToken(.lbracket, result.loc.start),
                ']' => self.genToken(.rbracket, result.loc.start),
                '{' => self.genToken(.lbrace, result.loc.start),
                '}' => self.genToken(.rbrace, result.loc.start),
                '$' => self.genToken(.dollar, result.loc.start),
                '-' => self.genTokenIfNextIs('>', .arrow, .minus, result.loc.start),
                '!' => self.genTokenIfNextIs('=', .not_eq, .not, result.loc.start),
                '<' => self.genTokenIfNextIs('=', .less_eq, .less, result.loc.start),
                '>' => self.genTokenIfNextIs('=', .greater_eq, .greater, result.loc.start),
                '|' => self.genTokenIfNextIs('|', .con_or, .bit_or, result.loc.start),
                '&' => self.genTokenIfNextIs('&', .con_and, .bit_and, result.loc.start),
                '=' => self.genTokenIfNextIs('=', .eq, .equal, result.loc.start),
                '0'...'9' => {
                    while (self.isNumber()) : (self.index += 1) {}
                    return self.genToken(.number_lit, result.loc.start);
                },
                '"' => {
                    self.index += 1;

                    while (self.isWithinString()) : (self.index += 1) {}

                    defer self.index += 1;
                    self.index -= 1;

                    return self.genToken(.string_lit, result.loc.start + 1);
                },
                'a'...'z', 'A'...'Z' => {
                    while (self.isIdentifier()) : (self.index += 1) {}
                    var token = self.genToken(.identifier, result.loc.start);
                    const eql = std.mem.eql;

                    if (eql(u8, self.source[token.loc.start..token.loc.end], "if")) {
                        token.tag = .kw_if;
                    } else if (eql(u8, self.source[token.loc.start..token.loc.end], "else")) {
                        token.tag = .kw_else;
                    } else if (eql(u8, self.source[token.loc.start..token.loc.end], "elif")) {
                        token.tag = .kw_elif;
                    } else if (eql(u8, self.source[token.loc.start..token.loc.end], "while")) {
                        token.tag = .kw_while;
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
