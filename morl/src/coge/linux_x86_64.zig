const std = @import("std");

const Elf = @import("../Elf.zig");
const Mir = @import("../sema/Mir.zig");

const Context = struct {
    locals: std.StringHashMap(i32),
};

pub fn genCode(gpa: std.mem.Allocator, mir: Mir) !std.ArrayList(u8) {
    var ctx = .{
        .locals = std.StringHashMap(i32).init(gpa),
    };

    var machine_code = std.ArrayList(u8).init(gpa);

    for (mir.instructions.items) |item| {
        switch (item.tag) {
            .mov => genMov(gpa, &ctx, item),
            else => {},
        }
    }

    try machine_code.appendSlice(&[_]u8{
        0x48, 0xc7, 0xc0, 0x3c, 0x00, 0x00, 0x00,
        0x0f, 0x05,
    });

    return machine_code;
}

pub fn genMov(gpa: std.mem.Allocator, ctx: *Context, instr: Mir.Instr) void {
    _ = gpa;
    _ = ctx;
    _ = instr;
}
