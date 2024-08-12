const std = @import("std");
const lex = @import("lexer.zig");
const Parser = @import("Parser.zig");

const Self = @This();

source: []const u8,
nodes: NodeList.Slice,
tokens: TokenList.Slice,

pub const TokenList = std.MultiArrayList(lex.Token);
pub const NodeList = std.MultiArrayList(Node);

pub const Node = struct {
    tag: Tag,
    main: u32,
    data: Data,

    const Data = struct {
        lhs: u32,
        rhs: u32,
    };

    const Tag = enum {
        bi_op,
        un_op,
    };
};

pub fn init(gpa: std.mem.Allocator, source: []const u8) std.mem.Allocator.Error!Self {
    var tokens = Self.TokenList{};
    defer tokens.deinit(gpa);

    var lexer = lex.Lexer.init(source);

    while (true) {
        const token = lexer.next();
        try tokens.append(gpa, token);
        if (token.tag == .eof) break;
    }

    var parser = Parser.init(gpa, source, tokens.items(.tag), tokens.items(.loc));
    defer parser.deinit();
    try parser.parse();

    return .{
        .source = source,
        .tokens = tokens.toOwnedSlice(),
        .nodes = parser.nodes.toOwnedSlice(),
    };
}

pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
    self.tokens.deinit(gpa);
    self.nodes.deinit(gpa);
    self.* = undefined;
}
