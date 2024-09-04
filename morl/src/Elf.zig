const std = @import("std");
const Mir = @import("sema/Mir.zig");

mir: Mir,
header: Header,

const Self = @This();

pub const Header = struct {
    // TODO: read more about the elf format and create elf header
};

pub fn init(
    mir: Mir,
) Self {
    return .{
        .mir = mir,
        .header = undefined,
    };
}

pub fn genExecutable(self: *Self) void {
    _ = self;
}

pub fn deinit(self: *Self) void {
    _ = self;
}
