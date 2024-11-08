// Mir.zig: Mor intermediate representation

const std = @import("std");

const Ast = @import("Ast.zig");
const lex = @import("lexer.zig");

const Self = @This();

ast: Ast,
gpa: std.mem.Allocator,
instructions: std.ArrayList(Instr),

const Context = struct {
    sp: u32,
    locals: std.StringHashMap(u32),
};

pub const Operand = union(enum) {
    register: u8,
    variable: u32,
    immediate: i64,

    fn print(self: Operand) void {
        switch (self) {
            .register => std.debug.print("rg{d}", .{self.register}),
            .variable => std.debug.print("[sp + {d}]", .{self.variable}),
            .immediate => std.debug.print("{d}", .{self.immediate}),
        }
    }

    fn registerFromIdent(ident: []const u8) ?Operand {
        if (std.mem.eql(u8, ident, "rax")) {
            return .{ .register = 0b000 };
        } else if (std.mem.eql(u8, ident, "rcx")) {
            return .{ .register = 0b001 };
        } else if (std.mem.eql(u8, ident, "rdx")) {
            return .{ .register = 0b010 };
        } else if (std.mem.eql(u8, ident, "rbx")) {
            return .{ .register = 0b011 };
        } else if (std.mem.eql(u8, ident, "rsp")) {
            return .{ .register = 0b100 };
        } else if (std.mem.eql(u8, ident, "rbp")) {
            return .{ .register = 0b101 };
        } else if (std.mem.eql(u8, ident, "rsi")) {
            return .{ .register = 0b110 };
        } else if (std.mem.eql(u8, ident, "rdi")) {
            return .{ .register = 0b111 };
        }

        return null;
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

        syscall,

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
        .locals = std.StringHashMap(u32).init(self.gpa),
    };
    defer ctx.locals.deinit();

    // TODO: support multiple top level statements (like other functions and imports)
    try self.genFromStatement(self.ast.stmts.items[0], &ctx);
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
        .macro_call_expr => {
            const man = self.ast.nodes.items(.main)[data.lhs];
            const loc = self.ast.tokens.items(.loc)[man];
            const lit = self.ast.source[loc.start..loc.end];

            if (std.mem.eql(u8, lit, "asm")) {
                try self.genFromMacroCall(&self.ast.calls.items[data.rhs], ctx);
            } else {
                std.debug.print("{s}\n", .{lit});
                @panic("Error: invalid compile macro");
            }

            std.debug.print("CALL: {s}\n", .{lit});
        },
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

            try self.instructions.append(.{ .tag = .push, .lhs = .{ .variable = ctx.sp - value.? } });
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

fn genFromMacroCall(self: *Self, macro_call: *Ast.Call, ctx: *Context) !void {
    for (macro_call.args.items) |arg| {
        if (self.ast.nodes.items(.tag)[arg] != .str_expr) @panic("ERROR: macro expected str_expr");

        const loc = self.ast.tokens.items(.loc)[self.ast.nodes.items(.main)[arg]];
        const val = self.ast.source[loc.start..loc.end];

        var it = std.mem.split(u8, val, " ");
        const op = it.next().?;

        if (std.mem.eql(u8, op, "mov")) {
            var instr: Instr = .{ .tag = .mov };

            const lhs = it.next().?;
            const rhs = it.next().?;

            instr.lhs = Operand.registerFromIdent(lhs[0 .. lhs.len - 1]);
            instr.rhs = Operand.registerFromIdent(rhs);

            if (instr.lhs == null) {
                const res = std.fmt.parseInt(i64, lhs[0 .. lhs.len - 1], 10);

                if (res == error.InvalidCharacter) {
                    const value = ctx.locals.get(lhs[0 .. lhs.len - 1]);
                    if (value == null) @panic("ERROR: variable is not defined lhs");

                    instr.lhs = .{ .variable = ctx.sp - value.? };
                } else {
                    instr.lhs = .{ .immediate = res catch @panic("ERROR: number overflows") };
                }
            }

            if (instr.rhs == null) {
                const res = std.fmt.parseInt(i64, rhs, 10);

                if (res == error.InvalidCharacter) {
                    const value = ctx.locals.get(rhs);
                    if (value == null) @panic("ERROR: variable is not defined lhs");

                    instr.rhs = .{ .variable = ctx.sp - value.? };
                } else {
                    instr.rhs = .{ .immediate = res catch @panic("ERROR: number overflows") };
                }
            }

            try self.instructions.append(instr);
        } else if (std.mem.eql(u8, op, "syscall")) {
            try self.instructions.append(.{ .tag = .syscall });
        } else {}
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
