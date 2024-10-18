const std = @import("std");

const Rex = enum {
    W,
    R,
    X,
    B,

    None,
};

// TODO
const Sib = struct {
    base: u8,
    scale: u8,
    index: u8,
};

const Opcode = struct {
    lhs: ?Operand = null,
    rhs: ?Operand = null,

    const Op = enum {
        Add,
        Sub,
        // ...
    };

    const Operand = struct {
        kind: Kind,

        const Kind = union(enum) {
            memory: u8,
            register: u8,
        };
    };
};

pub const Instr = struct {
    rex_prefix: Rex,
    opcode: Opcode,
};
