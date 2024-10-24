const std = @import("std");

const Elf = @import("../Elf.zig");
const Mir = @import("../sema/Mir.zig");

pub fn genCode(gpa: std.mem.Allocator, mir: Mir) !std.ArrayList(u8) {
    var machine_code = std.ArrayList(u8).init(gpa);

    for (mir.instructions.items) |item| {
        switch (item.tag) {
            .pop => {
                std.debug.print("pop\n", .{});
            },
            .push => try push(item, &machine_code),
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

fn push(instr: Mir.Instr, buffer: *std.ArrayList(u8)) !void {
    switch (instr.lhs.?) {
        .immediate => {
            try moveImmediate(0, instr.lhs.?.immediate, buffer);
            try pushReg(0, buffer);
        },
        .variable => try pushVariable(instr.lhs.?.variable, buffer),
        .register => try pushReg(instr.lhs.?.register, buffer),
    }
}

fn pushReg(reg: u8, buffer: *std.ArrayList(u8)) !void {
    try buffer.append(0x50 + reg);
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
