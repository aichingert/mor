// Mir.zig: Mor intermediate representation

const std = @import("std");

const Ast = @import("Ast.zig");

const InstrList = std.MultiArrayList(Instr);

const Self = @This();

gpa: std.mem.Allocator,
instructions: InstrList.Slice,

const Operand = struct {
    kind: Kind,

    const Register = enum {
        R0,
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
};

const Instr = struct {
    tag: Tag,

    const Tag = enum {
        neg,
        add,
        sub,
        div,
        mul,
        jmp,
        ret,
        call,

        pop,
        push,
    };
};

pub fn init(gpa: std.mem.Allocator, ast: Ast) Self {
    var instructions = InstrList{};

    for (ast.stmts.items) |item| {
        genInstructionsFromStatement(&instructions, &ast, item);
    }

    return .{
        .gpa = gpa,
        .instructions = instructions.toOwnedSlice(),
    };
}

fn genInstructionsFromStatement(instructions: *InstrList, ast: *const Ast, stmt: usize) void {
    const data = ast.nodes.items(.data)[stmt];

    switch (ast.nodes.items(.tag)[stmt]) {
        .mutable_declare => genInstructionsFromExpression(instructions, ast, data.rhs),
        .constant_declare => genInstructionsFromExpression(instructions, ast, data.rhs),
        .function_declare => {
            // TODO: function specific stuff

            for (ast.funcs.items(.body)[data.lhs].items) |fstmt| {
                genInstructionsFromStatement(instructions, ast, fstmt);
            }

            std.debug.print("Function declare\n", .{});
        },
        else => {
            std.debug.print("found tag {any}\n", .{ast.nodes.items(.tag)[stmt]});
            @panic("Failed with incorrect tag");
        },
    }
}

fn genInstructionsFromExpression(instructions: *InstrList, ast: *const Ast, expr: usize) void {
    switch (ast.nodes.items(.tag)[expr]) {
        .unary_expression => {
            std.debug.print("unary expr\n", .{});
        },
        .binary_expression => {
            std.debug.print("binary expr\n", .{});
        },
        .number_expression => {
            std.debug.print("number expr\n", .{});
        },
        .string_expression => {
            @panic("TODO: have to generate constant strings to store in the asm");
        },
        else => {
            std.debug.print("found tag {any}\n", .{ast.nodes.items(.tag)[expr]});
            @panic("Failed not an expression");
        },
    }

    _ = instructions;
}

pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
    self.instructions.deinit(gpa);
}
