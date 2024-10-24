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
            .push => push(item, &machine_code),
            else => {},
        }
    }

    try machine_code.appendSlice(&[_]u8{
        0x48, 0xc7, 0xc0, 0x3c, 0x00, 0x00, 0x00,
        0x0f, 0x05,
    });

    return machine_code;
}

fn push(instr: Mir.Instr, buffer: *std.ArrayList(u8)) void {
    _ = buffer;
    std.debug.print("{any}\n", .{instr.lhs});
}
