const std = @import("std");

const Ast = @import("Ast.zig");

const Self = @This();

const Operand = struct {
    kind: Kind,

    const Register = enum {
        rax,
        rbx,
        rcx,
        rdx,
        rsi,
        rdi,
        rbp,
        rsp,
    };

    const Kind = union(enum) {
        reg: Register,
        val: Register,
        immediate: i64,
        indexed: std.meta.Tuple(&[_]type{ Register, Operand }),
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
    _ = gpa;
    _ = ast;

    return .{};
}

pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
    _ = gpa;
    _ = self;
}
