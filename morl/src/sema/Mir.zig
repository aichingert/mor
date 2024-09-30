// Mir.zig: Mor intermediate representation

const std = @import("std");
const Allocator = std.mem.Allocator;

const Ast = @import("Ast.zig");
const lex = @import("lexer.zig");

pub const InstrList = std.MultiArrayList(Instr);

pub const Operand = struct {
    kind: Kind,

    const Reg = struct {
        kind: RegKind,
        count: u8,

        const RegKind = enum(u8) {
            sp, // stack pointer
            gp, // general purpose
        };
    };

    const Kind = union(enum) {
        reg: Reg,
        token: usize,
        immediate: i64,
    };
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

fn addInstr(gpa: Allocator, instrs: *InstrList, tag: Instr.Tag, data: Instr.Data) !Operand {
    try instrs.append(gpa, .{
        .tag = tag,
        .data = data,
    });

    return data.lhs;
}

pub fn genFromAst(gpa: std.mem.Allocator, ast: Ast) !InstrList.Slice {
    var instructions = InstrList{};

    for (ast.stmts.items) |item| {
        try genFromStmt(&ast, gpa, item, &instructions);
    }

    return instructions.toOwnedSlice();
}

fn genFromStmt(ast: *const Ast, gpa: Allocator, stmt: usize, instrs: *InstrList) !void {
    const tag = ast.nodes.items(.tag)[stmt];
    const data = ast.nodes.items(.data)[stmt];

    switch (tag) {
        .assign_stmt, .mutable_declare, .constant_declare => {
            const operands = .{
                .lhs = .{ .kind = .{ .token = ast.nodes.items(.main)[data.lhs] } },
                .rhs = try genFromExpr(ast, gpa, data.rhs, 0, instrs),
            };

            _ = try addInstr(gpa, instrs, .mov, operands);
        },
        .function_declare => {
            _ = try addInstr(gpa, instrs, .lbl, .{
                .lhs = .{ .kind = .{ .token = ast.nodes.items(.main)[data.lhs] } },
                .rhs = undefined,
            });

            for (ast.funcs.items(.body)[data.rhs].items) |func_stmt| {
                try genFromStmt(ast, gpa, func_stmt, instrs);
            }
        },
        .return_stmt => {
            _ = try genFromExpr(ast, gpa, data.lhs, 0, instrs);
            try instrs.append(gpa, .{ .tag = .ret, .data = undefined });
        },
        else => std.debug.panic("Invalid statment type: {any}\n", .{tag}),
    }
}

fn genFromExpr(
    ast: *const Ast,
    gpa: Allocator,
    expr: usize,
    r_count: u8,
    instrs: *InstrList,
) !Operand {
    const tag = ast.nodes.items(.tag)[expr];

    if (tag == .num_expr) {
        const tok_idx = ast.nodes.items(.main)[expr];
        const tok_loc = ast.tokens.items(.loc)[tok_idx];

        const num_lit = ast.source[tok_loc.start..tok_loc.end];
        const integer = try std.fmt.parseInt(i64, num_lit, 10);

        const data = .{
            .lhs = .{ .kind = .{ .reg = .{ .kind = .gp, .count = r_count } } },
            .rhs = .{ .kind = .{ .immediate = integer } },
        };

        return addInstr(gpa, instrs, .mov, data);
    }

    const data = ast.nodes.items(.data)[expr];
    const main = ast.nodes.items(.main)[expr];

    return switch (tag) {
        .ident => addInstr(gpa, instrs, .mov, .{
            .lhs = .{ .kind = .{ .reg = .{ .kind = .gp, .count = r_count } } },
            .rhs = .{ .kind = .{ .token = main } },
        }),
        .call_expr => {
            for (ast.calls.items[data.rhs].args.items, r_count..) |c_expr, reg| {
                _ = try genFromExpr(ast, gpa, c_expr, @intCast(reg), instrs);
            }

            // TODO: figure out how to tell it to use the return value or how to
            // generally handle state between functions with registers and stuff
            return addInstr(gpa, instrs, .call, .{
                .lhs = .{ .kind = .{ .token = ast.nodes.items(.main)[data.lhs] } },
                .rhs = undefined,
            });
        },
        .unary_expr, .binary_expr => {
            const operand = .{
                .lhs = try genFromExpr(ast, gpa, data.lhs, r_count, instrs),
                .rhs = if (tag == .unary_expr)
                    undefined
                else
                    try genFromExpr(ast, gpa, data.rhs, r_count + 1, instrs),
            };

            const instr_tag = if (tag == .unary_expr)
                Instr.Tag.unaryFrom(ast.tokens.items(.tag)[main])
            else
                Instr.Tag.binaryFrom(ast.tokens.items(.tag)[main]);

            return addInstr(gpa, instrs, instr_tag, operand);
        },
        else => std.debug.panic("Invalid expr kind: {any}\n", .{tag}),
    };
}

pub fn printInstrs(ast: *const Ast, instrs: InstrList.Slice) void {
    for (instrs.items(.tag), 0..) |tag, i| {
        printTag(tag);

        switch (tag) {
            .lbl, .neg, .call => printOperand(ast, instrs.items(.data)[i].lhs),
            .add, .sub, .mul, .div, .mov => {
                printOperand(ast, instrs.items(.data)[i].lhs);
                std.debug.print(", ", .{});
                printOperand(ast, instrs.items(.data)[i].rhs);
            },
            else => {},
        }

        std.debug.print("\n", .{});
    }
}

fn printTag(tag: Instr.Tag) void {
    if (tag != .lbl) {
        std.debug.print("  ", .{});
    }

    std.debug.print("{s} ", .{std.enums.tagName(Instr.Tag, tag).?});
}

fn printOperand(ast: *const Ast, operand: Operand) void {
    switch (operand.kind) {
        .reg => |r| std.debug.print("{s}[{d}]", .{ std.enums.tagName(Operand.Reg.RegKind, r.kind).?, r.count }),
        .token => |t| {
            const loc = ast.tokens.items(.loc)[t];
            std.debug.print("{s}", .{ast.source[loc.start..loc.end]});
        },
        .immediate => |i| std.debug.print("{d}", .{i}),
    }
}
