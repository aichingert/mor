const std = @import("std");

const Elf = @import("../Elf.zig");
const Mir = @import("../sema/Mir.zig");

// ModR/M:
// Bit    76   |    543  |  210
// Usage "Mod" |   "Reg" | "R/M"

const sp: u8 = 0b100;
const bp: u8 = 0b101;
const rex_w: u8 = 0x48;

// /r reg and r/m are registers
pub fn genCode(gpa: std.mem.Allocator, instr: []Mir.Instr) !std.ArrayList(u8) {
    var machine_code = std.ArrayList(u8).init(gpa);

    for (instr) |item| {
        switch (item.tag) {
            .je => try je(item.lhs.?, &machine_code),
            .cmp => try cmp(item.lhs.?, item.rhs.?, &machine_code),
            .jmp => try jmp(item.lhs.?, &machine_code),

            .lea => try lea(item.lhs.?, item.rhs.?, &machine_code),
            .mov => try mov(item.lhs.?, item.rhs.?, &machine_code),
            .cmove => try cmov(item.lhs.?, item.rhs.?, 0x44, &machine_code),
            .cmovg => try cmov(item.lhs.?, item.rhs.?, 0x4F, &machine_code),
            .cmovl => try cmov(item.lhs.?, item.rhs.?, 0x4C, &machine_code),
            .cmovne => try cmov(item.lhs.?, item.rhs.?, 0x45, &machine_code),
            .cmovge => try cmov(item.lhs.?, item.rhs.?, 0x4D, &machine_code),
            .cmovle => try cmov(item.lhs.?, item.rhs.?, 0x4E, &machine_code),

            .pop => try pop(item.lhs.?, &machine_code),
            .push => try push(item.lhs.?, &machine_code),

            .xor => try xor(item.lhs.?, item.rhs.?, &machine_code),
            .bit_or => try bit_or(item.lhs.?, item.rhs.?, &machine_code),
            .bit_and => try bit_and(item.lhs.?, item.rhs.?, &machine_code),

            .neg => try neg(item.lhs.?, &machine_code),
            .add => try add(item.lhs.?, item.rhs.?, &machine_code),
            .sub => try sub(item.lhs.?, item.rhs.?, &machine_code),
            .mul => try mul(item.lhs.?, item.rhs.?, &machine_code),
            .div => try div(item.lhs.?, item.rhs.?, &machine_code),

            .ret => try machine_code.append(0xC3),
            .call => try call(item.lhs.?, &machine_code),
            .syscall => try syscall(&machine_code),
            //else => {
            //    std.debug.print("Tag: {any}\n", .{item.tag});
            //    @panic("ERROR(coge/gen): failed invalid instruction");
            //},
        }
    }

    return machine_code;
}

// je := 0F 84 cd
fn je(lhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    if (lhs != .immediate) @panic("ERROR(compiler): only imm");

    try buffer.append(0x0F);
    try buffer.append(0x84);

    var buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &buf, @intCast(lhs.immediate), .little);
    try buffer.appendSlice(&buf);
}

// jmp := E9 cd
fn jmp(lhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    if (lhs != .immediate) @panic("ERROR(coge/jmp): only imm");

    try buffer.append(0xE9);

    var buf: [4]u8 = undefined;
    std.mem.writeInt(i32, &buf, @intCast(lhs.immediate), .little);
    try buffer.appendSlice(&buf);
}

// TODO: hard coded for testing purposes
fn lea(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    if (lhs != .register) @panic("ERROR(coge/lea): only supports stores in registers");

    switch (rhs) {
        .variable => try leaRegStk(lhs.register, sp, rhs.variable, buffer),
        .parameter => try leaRegStk(lhs.register, bp, rhs.parameter, buffer),
        else => @panic("ERROR(coge/lea): currently only supports var/par"),
    }
}

// lea := 8D /r | (r64, r/m64)
fn leaRegStk(lhs: u8, sreg: u8, rhs: u32, buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice(&[_]u8{ rex_w, 0x8D, 0b10000000 | lhs << 3 | sreg });
    if (sreg == sp) try buffer.append(0x24);

    var buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &buf, @intCast(rhs), .little);
    try buffer.appendSlice(&buf);
}

// call := E8 cd | ModRM:r/m (r)
fn call(lhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    if (lhs != .immediate) @panic("ERROR(coge/call): only imm");

    try buffer.append(0xE8);

    var buf: [4]u8 = undefined;
    std.mem.writeInt(i32, &buf, @intCast(lhs.immediate), .little);
    try buffer.appendSlice(&buf);
}

fn cmp(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    if (lhs == .register and rhs == .register) {
        try cmpRegReg(lhs, rhs, buffer);
    } else if (lhs == .register and rhs == .immediate) {
        try cmpRegImm(lhs, rhs, buffer);
    } else {
        @panic("ERROR(coge/cmp): cannot compare rhs with lhs");
    }
}

// cmp := REX.W + 3B /r
fn cmpRegReg(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    try buffer.append(rex_w);
    try buffer.append(0x3B);
    try buffer.append(0b11000000 | (rhs.register << 3) | lhs.register);
}

// cmp := REX.W + 81 /7 id
fn cmpRegImm(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    try buffer.append(rex_w);
    try buffer.append(0x81);
    try buffer.append(0b11111000 | lhs.register);

    var buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &buf, @intCast(rhs.immediate), .little);
    try buffer.appendSlice(&buf);
}

fn mov(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    if (lhs == .immediate) @panic("ERROR(compiler): cannot mov into immediate");

    switch (lhs) {
        .indexed => try movIdx(lhs.indexed, rhs, buffer),
        .register => try movReg(lhs.register, rhs, buffer),
        .variable => try movStk(sp, lhs.variable, rhs, buffer),
        .parameter => try movStk(bp, lhs.parameter, rhs, buffer),
        else => @panic("unreachable"),
    }
}

fn movIdx(regi: u8, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    switch (rhs) {
        .register => try movIdxReg(regi, rhs.register, buffer),
        else => @panic("TODO(coge/movi): not implemented"),
    }
}

// mov [rax], rcx
fn movIdxReg(regi: u8, reg: u8, buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice(&[_]u8{ rex_w, 0x89, reg << 3 | regi });
}

fn movReg(reg: u8, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    switch (rhs) {
        .indexed => @panic("ERROR(coge/movr): not implemented"),
        .variable => try movRegStk(reg, sp, rhs.variable, buffer),
        .register => try movRegReg(reg, rhs.register, buffer),
        .parameter => try movRegStk(reg, bp, rhs.parameter, buffer),
        .immediate => try movRegImm(reg, rhs.immediate, buffer),
    }
}

fn movStk(sreg: u8, off: u32, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    if (rhs == .variable or rhs == .parameter)
        @panic("ERROR(compiler): cannot mov value from memory to memory");

    switch (rhs) {
        .register => try movStkReg(sreg, rhs.register, off, buffer),
        .immediate => try movStkImm(sreg, rhs.immediate, off, buffer),
        else => @panic("unreachable"),
    }
}

// mov: REX.W + 8B /r | (r64, r/m64)
fn movRegStk(reg: u8, sreg: u8, off: u32, buffer: *std.ArrayList(u8)) !void {
    // 0x24 => SIB - byte
    try buffer.appendSlice(&[_]u8{ rex_w, 0x8B, 0b10000000 | reg << 3 | sreg });
    if (sreg == sp) try buffer.append(0x24);

    var buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &buf, off, .little);
    try buffer.appendSlice(&buf);
}

// mov: REX.W + 8B /r | (r64, r/m64) -> r/m64 into r64
fn movRegReg(lhs: u8, rhs: u8, buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice(&[_]u8{ rex_w, 0x8B, 0b11000000 | lhs << 3 | rhs });
}

// mov: REX.W + B8+ rd io | (r64, imm64)
fn movRegImm(reg: u8, imm: i64, buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice(&[_]u8{ rex_w, 0xB8 + reg });

    var buf: [8]u8 = undefined;
    std.mem.writeInt(i64, &buf, imm, .little);
    try buffer.appendSlice(&buf);
}

// mov: REX.W + 89 /r | (r/m64, r64)
fn movStkReg(sreg: u8, reg: u8, off: u32, buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice(&[_]u8{ rex_w, 0x89, 0b10000000 | reg << 3 | sreg });
    if (sreg == sp) try buffer.append(0x24);

    var buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &buf, off, .little);
    try buffer.appendSlice(&buf);
}

fn movStkImm(sreg: u8, imm: i64, off: u32, buffer: *std.ArrayList(u8)) !void {
    // rbx -> since it is most likely not used...
    const rbx: u8 = 0b010;

    try movRegImm(rbx, imm, buffer);
    try movStkReg(rbx, sreg, off, buffer);
}

// cmov: REX.W + 0F __ /r | (r64, r/m64)
fn cmov(lhs: Mir.Operand, rhs: Mir.Operand, op: u8, buffer: *std.ArrayList(u8)) !void {
    if (lhs != .register or rhs != .immediate) @panic("ERROR(coge/cmove): invalid branchless reg/imm");

    // NOTE: using register 3 here since 0, 1, ... could be used by the intermediate representation
    try movRegImm(3, rhs.immediate, buffer);
    try buffer.appendSlice(&[_]u8{ rex_w, 0x0F, op, 0b11000101 | (lhs.register << 3) });
}

fn pop(lhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    switch (lhs) {
        .indexed => @panic("ERROR(coge/pop): not possible?"),
        .immediate => std.debug.panic("Pop immediate?\n", .{}),
        .variable, .parameter => {
            // 8F /0
            //try buffer.append(0x8F);
            //try buffer.append(0xB4);
            //try buffer.append(0x24);

            //var buf: [4]u8 = undefined;
            //std.mem.writeInt(u32, &buf, lhs.variable, .little);

            //try buffer.appendSlice(&buf);
        },
        .register => try buffer.append(0x58 + lhs.register),
    }
}

fn push(lhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    switch (lhs) {
        .indexed => try pushIndexed(lhs.indexed, buffer),
        .immediate => {
            try movRegImm(0, lhs.immediate, buffer);
            try buffer.append(0x50);
        },
        .variable => try pushVariable(sp, lhs.variable, buffer),
        .parameter => try pushVariable(bp, lhs.parameter, buffer),
        .register => try buffer.append(0x50 + lhs.register),
    }
}

// push: FF /6 | (r/m64)
fn pushVariable(sreg: u8, offset: u32, buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice(&[_]u8{ 0xFF, 0b10110000 | sreg });
    if (sreg == sp) try buffer.append(0x24);

    var buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &buf, offset, .little);
    try buffer.appendSlice(&buf);
}

// push: FF /6 | (r/m64)
fn pushIndexed(regi: u8, buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice(&[_]u8{ 0xFF, 0b00110000 | regi });
}

fn xor(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    // NOTE: currently only implementing reg ^ reg since
    // the intermediate representation is very simple and
    // transforms everything in that form
    if (lhs != .register or rhs != .register) @panic("ERROR(coge/xor): only support reg/reg");

    // Instruction: REX.W + 33 /r

    // REX.W
    try buffer.append(rex_w);
    try buffer.append(0x33);

    // ModR/M
    // MR => r/m | reg

    // 0b11xxxxxx => /r
    try buffer.append(0b11000000 + (lhs.register << 3) + rhs.register);
}

// or := REX.W + 0B /r
fn bit_or(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    if (lhs != .register or rhs != .register) @panic("ERROR(coge/bit_or): only support reg/reg");

    try buffer.appendSlice(&[_]u8{ rex_w, 0x0B, 0b11000000 | (lhs.register << 3) | rhs.register });
}

// or := REX.W + 23 /r
fn bit_and(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    if (lhs != .register or rhs != .register) @panic("ERROR(coge/bit_and): only support reg/reg");

    try buffer.appendSlice(&[_]u8{ rex_w, 0x23, 0b11000000 | (lhs.register << 3) | rhs.register });
}

// neg := REX.W + F7 /3 | (r/m64)
fn neg(lhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    if (lhs != .register) @panic("ERROR(coge/neg): can only negate registers");

    try buffer.appendSlice(&[_]u8{ rex_w, 0xF7, 0b11011000 | lhs.register });
}

// add := REX.W + 01 /r
fn add(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    switch (rhs) {
        .register => {
            try buffer.append(rex_w);
            try buffer.append(0x01);
            try buffer.append(0b11000000 | (rhs.register << 3) | lhs.register);
        },
        .immediate => {
            const rbx: Mir.Operand = .{ .register = 3 };
            try mov(rbx, rhs, buffer);
            try add(lhs, rbx, buffer);
        },
        else => @panic("ERROR(coge/and): only supports reg/reg or reg/imm"),
    }
}

// sub := REX.W + 2B /r
fn sub(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    switch (rhs) {
        .register => {
            try buffer.append(rex_w);
            try buffer.append(0x29);
            try buffer.append(0b11000000 | (lhs.register << 3) | rhs.register);
        },
        .immediate => {
            const rbx: Mir.Operand = .{ .register = 3 };

            try mov(rbx, rhs, buffer);

            try buffer.append(rex_w);
            try buffer.append(0x29);
            try buffer.append(0b11000000 | (rbx.register << 3) | lhs.register);
            return;
        },
        else => @panic("ERROR(coge/sub): only supports reg/reg or reg/imm"),
    }

    // TODO: figure out how to use only one instruction for sub
    try movRegReg(lhs.register, rhs.register, buffer);
}

// mul := REX.W + F7 /4
fn mul(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    if (lhs != .register and lhs.register != 0) @panic("ERROR(coge/mul): lhs is not rax");
    if (rhs != .register) @panic("ERROR(coge/mul): rhs is not a register");

    try buffer.append(rex_w);
    try buffer.append(0xF7);
    try buffer.append(0b11100000 | rhs.register);

    //try movRegReg(0, 7, buffer);
}

// div := REX.W + F7 /6
fn div(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    try mov(.{ .register = 3 }, lhs, buffer);
    try mov(.{ .register = 0 }, rhs, buffer);
    try buffer.appendSlice(&[_]u8{ rex_w, 0xF7, 0b11110011 });
}

fn syscall(buffer: *std.ArrayList(u8)) !void {
    try buffer.append(0x0F);
    try buffer.append(0x05);
}
