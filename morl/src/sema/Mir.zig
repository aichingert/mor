// Mir.zig: Mor intermediate representation

const std = @import("std");

const Ast = @import("Ast.zig");
const lex = @import("lexer.zig");

const Self = @This();

ast: Ast,
gpa: std.mem.Allocator,
instructions: std.ArrayList(Instr),

const Context = struct {
    sp: i32,
    locals: std.StringHashMap(i32),
};

pub const Operand = union(enum) {
    register: u8,
    variable: i32,
    immediate: i64,

    fn print(self: Operand) void {
        switch (self) {
            .register => std.debug.print("rg{d}", .{self.register}),
            .variable => std.debug.print("[sp + {d}]", .{self.variable}),
            .immediate => std.debug.print("{d}", .{self.immediate}),
        }
    }
};

pub const Instr = struct {
    tag: Tag,

    lhs: ?Operand = null,
    rhs: ?Operand = null,

    pub const Tag = enum {
        neg,
        add,
        sub,
        div,
        mul,

        mov,
        pop,
        push,

        fn unaryFrom(token: lex.Token.Tag) Tag {
            switch (token) {
                .minus => return .neg,
                else => std.debug.panic("Unknown unary expr kind: {any}\n", .{token}),
            }
        }

        fn binaryFrom(token: lex.Token.Tag) Tag {
            switch (token) {
                .plus => return .add,
                .minus => return .sub,
                .slash => return .div,
                .asterisk => return .mul,
                else => std.debug.panic("Unknown binary expr kind: {any}\n", .{token}),
            }
        }
    };
};

pub fn init(gpa: std.mem.Allocator, ast: Ast) Self {
    return .{
        .gpa = gpa,
        .ast = ast,
        .instructions = undefined,
    };
}

pub fn genInstructions(self: *Self) !void {
    self.instructions = std.ArrayList(Instr).init(self.gpa);

    var ctx: Context = .{
        .sp = 0,
        .locals = std.StringHashMap(i32).init(self.gpa),
    };
    defer ctx.locals.deinit();

    // TODO: support multiple top level statements (like other functions and imports)
    try self.genFromStatement(self.ast.stmts.items[0], &ctx);

    var it = ctx.locals.valueIterator();
    while (it.next()) |item| {
        std.debug.print("{any}\n", .{item.*});
    }
}

fn genFromStatement(self: *Self, stmt: usize, ctx: *Context) !void {
    const data = self.ast.nodes.items(.data)[stmt];

    switch (self.ast.nodes.items(.tag)[stmt]) {
        .mutable_declare, .constant_declare => {
            // a := 10

            const tok = self.ast.nodes.items(.main)[data.lhs];
            const loc = self.ast.tokens.items(.loc)[tok];
            const ident = self.ast.source[loc.start..loc.end];

            try self.genFromExpression(data.rhs, ctx);
            try ctx.locals.put(ident, ctx.sp);
        },
        .assign_stmt => {},
        .function_declare => {
            for (self.ast.funcs.items(.body)[data.rhs].items) |func_stmt| {
                try self.genFromStatement(func_stmt, ctx);
            }
        },
        else => {},
    }
}

fn genFromExpression(self: *Self, expr: usize, ctx: *Context) !void {
    std.debug.print("{any}\n", .{self.ast.nodes.items(.tag)[expr]});
    const data = self.ast.nodes.items(.data)[expr];
    const main = self.ast.nodes.items(.main)[expr];

    switch (self.ast.nodes.items(.tag)[expr]) {
        .num_expr => {
            const loc = self.ast.tokens.items(.loc)[main];
            const lit = self.ast.source[loc.start..loc.end];
            const num = try std.fmt.parseInt(i64, lit, 10);

            try self.instructions.append(.{ .tag = .push, .lhs = .{ .immediate = num } });
            ctx.sp += 8;
        },
        .ident => {
            const loc = self.ast.tokens.items(.loc)[main];
            const ident = self.ast.source[loc.start..loc.end];

            const value = ctx.locals.get(ident);
            if (value == null) {
                std.debug.print("TODO: better debug info but use of unknown var\n", .{});
                std.process.exit(1);
            }

            try self.instructions.append(.{ .tag = .push, .lhs = .{ .variable = ctx.sp - (value.? - 8) } });
            ctx.sp += 8;
        },
        .binary_expr => {
            const tag = Instr.Tag.binaryFrom(self.ast.tokens.items(.tag)[main]);

            try self.genFromExpression(data.lhs, ctx);
            try self.genFromExpression(data.rhs, ctx);

            try self.instructions.append(.{
                .tag = .pop,
                .lhs = .{ .register = 0 },
            });
            try self.instructions.append(.{
                .tag = .pop,
                .lhs = .{ .register = 1 },
            });
            ctx.sp -= 16;

            try self.instructions.append(.{
                .tag = tag,
                .lhs = .{ .register = 0 },
                .rhs = .{ .register = 1 },
            });
            try self.instructions.append(.{
                .tag = .push,
                .lhs = .{ .register = 0 },
            });
            ctx.sp += 8;
        },
        .unary_expr => {
            const tag = Instr.Tag.unaryFrom(self.ast.tokens.items(.tag)[main]);

            try self.genFromExpression(data.lhs, ctx);

            try self.instructions.append(.{
                .tag = .pop,
                .lhs = .{ .register = 0 },
            });
            ctx.sp -= 8;

            try self.instructions.append(.{
                .tag = tag,
                .lhs = .{ .register = 0 },
            });
            try self.instructions.append(.{
                .tag = .push,
                .lhs = .{ .register = 0 },
            });
            ctx.sp += 8;
        },
        else => {},
    }
}

pub fn printInstrs(self: *Self) void {
    for (self.instructions.items) |item| {
        std.debug.print("{s} ", .{std.enums.tagName(Instr.Tag, item.tag).?});

        switch (item.tag) {
            .neg => {
                std.debug.print("-", .{});
                item.lhs.?.print();
            },
            .pop, .push => {
                item.lhs.?.print();
            },
            .add, .sub, .mul, .div => {
                item.lhs.?.print();
                std.debug.print(", ", .{});
                item.rhs.?.print();
            },
            else => {},
        }

        std.debug.print("\n", .{});
    }
}
