const std = @import("std");

const Ast = @import("sema/Ast.zig");
const Mir = @import("sema/Mir.zig");
const Elf = @import("Elf.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Parse args into string array (error union needs 'try')
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    for (args[1..]) |arg| {
        var file = try std.fs.cwd().openFile(arg, .{});
        defer file.close();

        const source = try file.readToEndAlloc(allocator, 4 * 1024 * 1024);
        defer allocator.free(source);

        var ast = try Ast.init(allocator, source);
        defer ast.deinit(allocator);

        var mir = try Mir.init(allocator, ast);
        defer mir.deinit(allocator);

        var elf = Elf.init(mir);
        defer elf.deinit();

        for (mir.instructions.items(.tag), 0..) |tag, i| {
            const data = mir.instructions.items(.data)[i];

            switch (tag) {
                .lbl => {
                    const tok = ast.tokens.items(.loc)[@intCast(data.lhs.kind.immediate)];

                    std.debug.print("{d}-{d} / {s}:\n", .{ tok.start, tok.end, ast.source[tok.start..tok.end] });
                },
                .mov, .add, .sub, .div, .mul => {
                    std.debug.print("    {s} ", .{std.enums.tagName(Mir.Instr.Tag, tag).?});
                    data.lhs.print(false);
                    std.debug.print(", ", .{});
                    data.rhs.print(true);
                },
                else => {
                    std.debug.print("    {s} ", .{std.enums.tagName(Mir.Instr.Tag, tag).?});
                    data.lhs.print(true);
                },
            }
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
