const std = @import("std");

const Elf = @import("../Elf.zig");
const Mir = @import("../sema/Mir.zig");

// /r reg and r/m are registers

pub fn genCode(gpa: std.mem.Allocator, mir: Mir, start: usize) !std.ArrayList(u8) {
    _ = start;
    var machine_code = std.ArrayList(u8).init(gpa);

    for (mir.instructions.items) |item| {
        switch (item.tag) {
            .pop => try pop(item.lhs.?, &machine_code),
            .push => try push(item.lhs.?, &machine_code),
            .add => try add(item.lhs.?, item.rhs.?, &machine_code),
            .sub => try sub(item.lhs.?, item.rhs.?, &machine_code),
            .mul => try sub(item.lhs.?, item.rhs.?, &machine_code),
            else => {},
        }
    }

    try machine_code.appendSlice(&[_]u8{
        0x48, 0xc7, 0xc0, 0x3c, 0x00, 0x00, 0x00,
        0x0f, 0x05,
    });

    return machine_code;
}

fn moveImmediate(reg: u8, imm64: i64, buffer: *std.ArrayList(u8)) !void {
    // 0x40
    // B8 + rd io
    // Rex.W
    //     |
    // 01001000
    //
    //        1
    //       2
    //      4
    //     8
    //    16
    //   32
    //  64
    // 4 * 16 => 64 + 8 72 => 0x48

    try buffer.append(0x48);
    try buffer.append(0xb8 + reg);

    var buf: [8]u8 = undefined;
    std.mem.writeInt(i64, &buf, imm64, .little);

    try buffer.appendSlice(&buf);
}

fn pop(lhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    switch (lhs) {
        .immediate => std.debug.panic("Pop immediate?\n", .{}),
        .variable => {
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
        .immediate => {
            try moveImmediate(0, lhs.immediate, buffer);
            try buffer.append(0x50);
        },
        .variable => try pushVariable(lhs.variable, buffer),
        .register => try buffer.append(0x50 + lhs.register),
    }
}

fn pushVariable(offset: u32, buffer: *std.ArrayList(u8)) !void {
    // FF /6
    try buffer.append(0xFF);

    // 0xB4 => 16 * 11 + 4 => 180
    // => 10110100

    // https://wiki.osdev.org/X86-64_Instruction_Encoding
    // MOD REG R/M
    // 10  110 100
    try buffer.append(0xB4);

    // SIB
    // 36 => 0x2
    // 00 100 100 => Mod 10 => X.Index = 0.100 SP | B.Base => SP
    try buffer.append(0x24);

    // displacement
    var buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &buf, offset, .little);

    try buffer.appendSlice(&buf);
}

fn add(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    // NOTE: currently only implementing reg + reg since the intermediate representation is very simple and
    // transforms everything in that form

    // Rex.W
    // 01001000
    try buffer.append(0x48);
    try buffer.append(0x01);
    // ModR/M
    // MR => r/m | reg
    try buffer.append(0b11000000 + (rhs.register << 3) + lhs.register);
}

fn sub(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    // Rex.W
    // 01001000
    try buffer.append(0x48);
    try buffer.append(0x29);
    // ModR/M
    // MR => r/m | reg
    try buffer.append(0b11000000 + (rhs.register << 3) + lhs.register);
}

fn mul(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    _ = rhs;

    // Rex.W
    // 01001000
    try buffer.append(0x48);
    try buffer.append(0xF7);
    // ModR/M
    // MR => r/m | reg
    try buffer.append(0b11100000 + lhs.register);
}

fn div(lhs: Mir.Operand, rhs: Mir.Operand, buffer: *std.ArrayList(u8)) !void {
    _ = rhs;
    // TODO: implement mov for operand

    // mov(lhs) ; try moveImmediate(2, imm64: i64, buffer: *std.ArrayList(u8)) !void {

    // Rex.W
    // 01001000
    try buffer.append(0x48);
    try buffer.append(0xF7);
    // ModR/M
    // MR => r/m | reg
    try buffer.append(0b11111000 + lhs.register);
}
