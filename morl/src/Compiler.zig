const std = @import("std");

const Ast = @import("sema/Ast.zig");
const Mir = @import("sema/Mir.zig");
const Elf = @import("Elf.zig");

const Self = @This();

pub fn compile(path: []const u8, allocator: std.mem.Allocator) !void {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const source = try file.readToEndAlloc(allocator, 4 * 1024 * 1024);
    defer allocator.free(source);

    var ast = try Ast.init(allocator, source);
    defer ast.deinit(allocator);

    var mir = Mir.init(allocator, ast);
    try mir.genInstructions();
    defer mir.instructions.deinit();

    mir.printInstrs();

    try Elf.genExe(allocator, mir);
}
