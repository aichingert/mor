// Tct.zig: Type checked tree
// NOTE: this is my attempt to enforce types
// I should probably learn more about type
// theory but I found out that I learn the most
// if I just do something mess up and then do it
// again. So this is just try

const std = @import("std");
const Ast = @import("Ast.zig");
const Token = @import("lexer.zig").Token;

const Self = @This();

// TODO: add in between step of ast and mir
// therefore giving more information to mir
// which enables it to use different sizes
// and makes it possible to figure out what
// types get passed to functions and able to
// implement structs
//
// TODO: what are types? and going from expected to actual with like
//
// n : u8 = 255
// a : u8[][] = {0}
// f : fn(i32) -> i32 = |a| a + 1
// s : structy = { a := 10, b := 20 } // not sure about this syntax
//
// numbers -> u8, i8 - u64, i64 ? is there a difference between sizes or should it truncate/extend them
// strings -> pretty simple they are just an array of characters
// structs -> now things get weird (is this just a name or actually the different values in a struct like
//            it has the variable (b: i32, c: u8) -> or okay this is a struct so you can access variables
//            then again checking that a struct has that variable requires it to store the names of those
//            member variables but how are they represented in the type system
// arrays  -> should this store something else or what do types actually need just information that it is
//            an array so you can index it, but then again the size does matter because when you index an
//            array you get another type

// TODO: not sure...
source: []const u8,

types: std.ArrayList(Type),
funcs: std.StringHashMap(TypedFunc),

t_numbers: std.ArrayList(TypedNumber),
t_singles: std.ArrayList(TypedSingleExpr),
t_binaries: std.ArrayList(TypedBinaryExpr),

pub const Type = struct {
    tag: Tag,
    val: Token,

    typ: u32,

    pub const Tag = enum {
        unknown,
        signed_number,
        unsigned_number,

        unary_expr,
        binary_expr,
        return_expr,

        // TODO: can these be the same?
        // probably not.
        constant_type,
        variable_type,

        function_type,
    };
};

pub const TypedFunc = struct {
    args: std.ArrayList(Type.Tag),
    body: std.ArrayList(Type),

    return_type: Type.Tag,

    fn init(gpa: std.mem.Allocator, ast: *const Ast, stmt: usize) TypedFunc {
        var func = .{
            .args = std.ArrayList(Type.Tag).init(gpa),
            .body = std.ArrayList(Type).init(gpa),

            .return_type = .unknown,
        };

        std.debug.print("{any}\n", .{ast.nodes.items(.tag)[stmt]});
        const ast_func = ast.nodes.items(.data)[stmt].rhs;

        for (ast.funcs.items(.args)[ast_func].items) |arg| {
            std.debug.print("{any}\n", .{arg});
        }

        func.return_type = .unknown;

        return func;
    }

    fn deinit(self: *TypedFunc) void {
        self.args.deinit();
        self.body.deinit();
    }
};

pub const TypedNumber = struct {
    size: u8,
};

// NOTE: used for paren- and unary expressions
// since both of them only have a single value
pub const TypedSingleExpr = struct {
    typ: u32,
};

pub const TypedBinaryExpr = struct {
    lhs: u32,
    rhs: u32,
};

pub fn init(gpa: std.mem.Allocator, ast: Ast) !Self {
    var tct = .{
        .source = ast.source,

        .types = std.ArrayList(Type).init(gpa),
        .funcs = std.StringHashMap(TypedFunc).init(gpa),
        .t_numbers = std.ArrayList(TypedNumber).init(gpa),
        .t_singles = std.ArrayList(TypedSingleExpr).init(gpa),
        .t_binaries = std.ArrayList(TypedBinaryExpr).init(gpa),
    };

    std.debug.print("<Tct.zig  \\\n", .{});

    for (ast.stmts.items) |stmt| {
        const tag = ast.nodes.items(.tag)[stmt];

        switch (tag) {
            .function_declare => {
                const typed_func = TypedFunc.init(gpa, &ast, stmt);
                try tct.funcs.put(ast.getIdent(ast.nodes.items(.data)[stmt].lhs), typed_func);
            },
            else => @panic("Error(Tct.zig): unknown top level statement"),
        }

        std.debug.print("{any}\n", .{tag});
    }

    std.debug.print("Tct.zig   />\n", .{});
    try tct.types.append(.{ .tag = .unknown, .val = undefined, .typ = 0 });

    return tct;
}

pub fn deinit(self: *Self) void {
    var fs = self.funcs.iterator();
    while (fs.next()) |kv| {
        kv.value_ptr.*.deinit();
    }

    self.types.deinit();
    self.funcs.deinit();
    self.t_numbers.deinit();
    self.t_singles.deinit();
    self.t_binaries.deinit();
}
