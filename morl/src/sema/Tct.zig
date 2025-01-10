// Tct.zig: Type checked tree

const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;

const Ast = @import("Ast.zig");
const Token = @import("lexer.zig").Token;

const Self = @This();

source: []const u8,

types: ArrayList(Type),
funcs: StringHashMap(TypedFunc),

t_decs: ArrayList(TypedDec),
t_vars: ArrayList(TypedVar),
t_numbers: ArrayList(TypedNumber),
t_singles: ArrayList(TypedSingleExpr),
t_binaries: ArrayList(TypedBinaryExpr),

const TypeEnvironment = struct {
    dyns: StringHashMap(u32),

    vars: StringHashMap(u32),
    func: StringHashMap(u32),
};

pub const Type = struct {
    at: u32,
    tag: Tag,

    pub const Tag = enum {
        unknown,
        signed_number,
        unsigned_number,

        unary_expr,
        binary_expr,
        return_expr,

        declare_type,
        constant_type,
        variable_type,

        function_type,
    };

    fn get(tct: *Self, tok: Token) !?Type {
        const ident = tct.source[tok.loc.start..tok.loc.end];

        if (std.mem.eql(u8, ident, "u8")) {
            const n = try tct.addTypedNumber(.{ .size = 8, .val = undefined });
            return .{ .at = n, .tag = .unsigned_number };
        }
        if (std.mem.eql(u8, ident, "u32")) {
            const n = try tct.addTypedNumber(.{ .size = 32, .val = undefined });
            return .{ .at = n, .tag = .unsigned_number };
        }
        if (std.mem.eql(u8, ident, "i32")) {
            const n = try tct.addTypedNumber(.{ .size = 32, .val = undefined });
            return .{ .at = n, .tag = .signed_number };
        }

        return null;
    }
};

pub const TypedFunc = struct {
    args: ArrayList(Type),
    body: ArrayList(Type),

    return_type: Type,

    fn init(tct: *Self, gpa: std.mem.Allocator, ast: *const Ast, stmt: usize) !TypedFunc {
        var func: TypedFunc = .{
            .args = ArrayList(Type).init(gpa),
            .body = ArrayList(Type).init(gpa),

            .return_type = .{ .at = 0, .tag = .unknown },
        };

        const ast_func = ast.nodes.items(.data)[stmt].rhs;
        const toks = ast.tokens;

        for (ast.funcs.items(.args)[ast_func].items) |arg| {
            std.debug.assert(ast.nodes.items(.tag)[arg] == .type_declare);
            const data = ast.nodes.items(.data)[arg];
            const lhs = data.lhs;
            const rhs = data.rhs;

            const ident = .{ .loc = toks.items(.loc)[lhs], .tag = toks.items(.tag)[lhs] };
            const token = .{ .loc = toks.items(.loc)[rhs], .tag = toks.items(.tag)[rhs] };

            if (try Type.get(tct, token)) |p_type| {
                const typ = try tct.addType(p_type);
                const at = try tct.addTypedDec(.{ .typ = typ, .ident = ident });
                try func.args.append(.{ .at = at, .tag = .declare_type });
            } else {
                @panic("Error(TypedFunc): parameter type is invalid\n");
            }
        }

        func.return_type = .{ .at = 1, .tag = undefined };
        return func;
    }

    fn deinit(self: *TypedFunc) void {
        self.args.deinit();
        self.body.deinit();
    }
};

pub const TypedDec = struct {
    typ: u32,
    ident: Token,
};

pub const TypedVar = struct {
    typ: u32,
    val: u32,
    ident: Token,
};

pub const TypedNumber = struct {
    size: u8,
    val: Token,
};

// NOTE: used for paren- and unary expressions
// since both of them only have a single value
pub const TypedSingleExpr = struct {
    typ: u32,
    val: u32,
};

pub const TypedBinaryExpr = struct {
    lhs: u32,
    rhs: u32,
    val: u32,
};

fn addType(self: *Self, t: Type) !u32 {
    try self.types.append(t);
    return @intCast(self.types.items.len - 1);
}

fn addTypedDec(self: *Self, d: TypedDec) !u32 {
    try self.t_decs.append(d);
    return @intCast(self.t_decs.items.len - 1);
}

fn addTypedNumber(self: *Self, n: TypedNumber) !u32 {
    try self.t_numbers.append(n);
    return @intCast(self.t_numbers.items.len - 1);
}

pub fn init(gpa: std.mem.Allocator, ast: Ast) !Self {
    var tct: Self = .{
        .source = ast.source,

        .types = ArrayList(Type).init(gpa),
        .funcs = StringHashMap(TypedFunc).init(gpa),
        .t_decs = ArrayList(TypedDec).init(gpa),
        .t_vars = ArrayList(TypedVar).init(gpa),
        .t_numbers = ArrayList(TypedNumber).init(gpa),
        .t_singles = ArrayList(TypedSingleExpr).init(gpa),
        .t_binaries = ArrayList(TypedBinaryExpr).init(gpa),
    };

    _ = try tct.addType(.{ .at = 0, .tag = .unknown });
    std.debug.print("<Tct.zig  \\\n", .{});

    for (ast.stmts.items) |stmt| {
        const tag = ast.nodes.items(.tag)[stmt];

        switch (tag) {
            .function_declare => {
                try tct.funcs.put(
                    ast.getIdent(ast.nodes.items(.data)[stmt].lhs),
                    try TypedFunc.init(&tct, gpa, &ast, stmt),
                );
            },
            else => @panic("Error(Tct.zig): unknown top level statement"),
        }

        std.debug.print("{any}\n", .{tag});
    }

    std.debug.print("Tct.zig   />\n", .{});

    return tct;
}

pub fn deinit(self: *Self) void {
    var fs = self.funcs.iterator();
    while (fs.next()) |kv| {
        kv.value_ptr.*.deinit();
    }

    self.types.deinit();
    self.funcs.deinit();
    self.t_vars.deinit();
    self.t_decs.deinit();
    self.t_numbers.deinit();
    self.t_singles.deinit();
    self.t_binaries.deinit();
}
