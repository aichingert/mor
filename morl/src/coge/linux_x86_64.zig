const std = @import("std");

const Elf = @import("../Elf.zig");
const Mir = @import("../sema/Mir.zig");

const Context = struct {
    locals: std.StringHashMap(i32),
};

pub fn genCode(gpa: std.mem.Allocator, mir: Mir.InstrList.Slice) !std.ArrayList(u8) {
    var ctx = .{
        .locals = std.StringHashMap(i32).init(gpa),
    };

    var machine_code = std.ArrayList(u8).init(gpa);

    for (mir.items(.tag), 0..) |tag, i| {
        switch (tag) {
            .lbl, .call, .ret, .jmp => {}, // TODO:
            .mov => genMov(gpa, &ctx, mir.items(.data)[i]),
            else => {},
        }
    }

    try machine_code.appendSlice(&[_]u8{
        0x48, 0xc7, 0xc0, 0x3c, 0x00, 0x00, 0x00,
        0x0f, 0x05,
    });

    return machine_code;
}

pub fn genMov(gpa: std.mem.Allocator, ctx: *Context, instr: Mir.Instr.Data) void {
    std.debug.print("0x48 0x8B\n", .{});

    _ = gpa;
    _ = ctx;
    _ = instr;
}
