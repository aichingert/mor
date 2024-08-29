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
    const Tag = enum {
        neg,
        add,
        sub,
        div,
        mul,
        jmp,
        ret,
        call,
    };
};

pub fn init(gpa: std.mem.Allocator, ast: Ast) Self {
    var instructions = InstrList{};

    for (ast.stmts.items) |item| {
        std.debug.print("{any}\n", .{item});
    }

    return .{
        .gpa = gpa,
        .instructions = instructions.toOwnedSlice(),
    };
}

pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
    self.instructions.deinit(gpa);
}
