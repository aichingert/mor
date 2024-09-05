// Mir.zig: Mor intermediate representation

const std = @import("std");

const Ast = @import("Ast.zig");

const InstrList = std.MultiArrayList(Instr);

const Self = @This();

instructions: InstrList.Slice,

pub const Operand = struct {
    kind: Kind,

    const Register = enum(u8) {
        R0 = 0,
        R1,
        R2,
        R3,
        R5,
        R6,
        R7,
        R8,
        R9,
        R10,
        R11,
        R12,
        SP,
    };

    const Kind = union(enum) {
        reg: Register,
        val: Register,
        immediate: i64,
        indexed: std.meta.Tuple(&[_]type{ Register, *Kind }),
    };

    pub fn print(self: Operand, nl: bool) void {
        switch (self.kind) {
            .reg => |r| std.debug.print("{s}", .{std.enums.tagName(Register, r).?}),
            .val => |r| std.debug.print("[{s}]", .{std.enums.tagName(Register, r).?}),
            .indexed => @panic("TODO: printing indexed"),
            .immediate => |v| std.debug.print("{d}", .{v}),
        }

        if (nl) std.debug.print("\n", .{});
    }
};

pub const Instr = struct {
    tag: Tag,
    data: Data,

    const Data = struct {
        lhs: Operand,
        rhs: Operand,
    };

    pub const Tag = enum {
        neg,
        add,
        sub,
        div,
        mul,
        mov,
        lbl,
        jmp,
        ret,
        call,

        pop,
        push,
    };
};

pub fn init(gpa: std.mem.Allocator, ast: Ast) !Self {
    var instructions = InstrList{};

    for (ast.stmts.items) |item| {
        try genInstructionsFromStatement(&ast, gpa, item, &instructions);
    }

    return .{ .instructions = instructions.toOwnedSlice() };
}

fn genInstructionsFromStatement(
    ast: *const Ast,
    gpa: std.mem.Allocator,
    stmt: usize,
    instructions: *InstrList,
) !void {
    const data = ast.nodes.items(.data)[stmt];

    switch (ast.nodes.items(.tag)[stmt]) {
        .mutable_declare, .constant_declare => {
            _ = try genInstructionsFromExpression(0, ast, gpa, data.rhs, instructions);
        },
        .function_declare => {
            try instructions.append(gpa, .{
                .tag = .lbl,
                .data = .{
                    .lhs = .{ .kind = .{ .immediate = @intCast(data.lhs) } },
                    .rhs = undefined,
                },
            });
            // TODO: function specific stuff

            for (ast.funcs.items(.body)[data.rhs].items) |fstmt| {
                try genInstructionsFromStatement(ast, gpa, fstmt, instructions);
            }

            std.debug.print("Function declare\n", .{});
        },
        .return_expression => {
            _ = try genInstructionsFromExpression(
                0,
                ast,
                gpa,
                ast.nodes.items(.data)[stmt].lhs,
                instructions,
            );
            try instructions.append(gpa, .{ .tag = .ret, .data = undefined });
        },
        else => {
            std.debug.print("found tag {any}\n", .{ast.nodes.items(.tag)[stmt]});
            @panic("Failed with incorrect tag");
        },
    }
}

fn genInstructionsFromExpression(
    reg: i32,
    ast: *const Ast,
    gpa: std.mem.Allocator,
    expr: usize,
    instructions: *InstrList,
) !Operand {
    switch (ast.nodes.items(.tag)[expr]) {
        .unary_expression => {
            const data = ast.nodes.items(.data)[expr];
            const main = ast.nodes.items(.main)[expr];

            const tag = ast.tokens.items(.tag)[main];
            const operands: Instr.Data = .{
                .lhs = try genInstructionsFromExpression(reg, ast, gpa, data.lhs, instructions),
                .rhs = undefined,
            };

            switch (tag) {
                .minus => try instructions.append(gpa, .{ .tag = .neg, .data = operands }),
                else => unreachable,
            }
        },
        .binary_expression => {
            const data = ast.nodes.items(.data)[expr];

            const tag = ast.tokens.items(.tag)[ast.nodes.items(.main)[expr]];
            const operands: Instr.Data = .{
                .lhs = try genInstructionsFromExpression(reg, ast, gpa, data.lhs, instructions),
                .rhs = try genInstructionsFromExpression(reg + 1, ast, gpa, data.rhs, instructions),
            };

            switch (tag) {
                .plus => try instructions.append(gpa, .{ .tag = .add, .data = operands }),
                .minus => try instructions.append(gpa, .{ .tag = .sub, .data = operands }),
                .slash => try instructions.append(gpa, .{ .tag = .div, .data = operands }),
                .asterisk => try instructions.append(gpa, .{ .tag = .mul, .data = operands }),
                else => unreachable,
            }
        },
        .number_expression => {
            const tok_idx = ast.nodes.items(.main)[expr];
            const tok_loc = ast.tokens.items(.loc)[tok_idx];

            // TODO: some sort of type checking should have happened before this so we know the type
            const num_lit = ast.source[tok_loc.start..tok_loc.end];
            const integer = try std.fmt.parseInt(i64, num_lit, 10);

            try instructions.append(gpa, .{
                .tag = .mov,
                .data = .{
                    .lhs = .{ .kind = .{ .reg = @enumFromInt(reg) } },
                    .rhs = .{ .kind = .{ .immediate = integer } },
                },
            });
        },
        .call_expression => {
            const data = ast.nodes.items(.data)[expr];
            const call = ast.calls.items[data.rhs];

            for (call.args.items, @intCast(reg)..) |arg, register| {
                std.debug.print("{d}\n", .{arg});
                _ = try genInstructionsFromExpression(
                    @intCast(register),
                    ast,
                    gpa,
                    arg,
                    instructions,
                );
            }

            // TODO: argument passing
            try instructions.append(gpa, .{
                .tag = .call,
                .data = .{
                    .lhs = .{ .kind = .{ .immediate = @intCast(ast.nodes.items(.data)[expr].lhs) } },
                    .rhs = undefined,
                },
            });
        },
        .identifier => {
            // TODO: implement variables
        },

        .string_expression => {
            @panic("TODO: have to generate constant strings to store in the asm");
        },
        else => {
            std.debug.print("found tag {any}\n", .{ast.nodes.items(.tag)[expr]});
            @panic("Failed not an expression");
        },
    }

    return .{ .kind = .{ .reg = @enumFromInt(reg) } };
}

pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
    self.instructions.deinit(gpa);
}
