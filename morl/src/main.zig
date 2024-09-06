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

        var mir: Mir.InstrList.Slice = try Mir.genInstructionsFromAst(allocator, ast);
        defer mir.deinit(allocator);

        for (mir.items(.tag), 0..) |tag, i| {
            const data = mir.items(.data)[i];

            switch (tag) {
                .lbl => {
                    const node = ast.nodes.items(.main)[@intCast(data.lhs.kind.immediate)];
                    const tok = ast.tokens.items(.loc)[node];

                    std.debug.print("{s}:\n", .{ast.source[tok.start..tok.end]});
                },
                .call => {
                    const node = ast.nodes.items(.main)[@intCast(data.lhs.kind.immediate)];
                    const tok = ast.tokens.items(.loc)[node];

                    std.debug.print("    call {s}\n", .{ast.source[tok.start..tok.end]});
                },
                .ret => {
                    std.debug.print("    {s}\n", .{std.enums.tagName(Mir.Instr.Tag, tag).?});
                    std.debug.print(" {any}\n", .{data});
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

        try Elf.genExecutable(allocator, mir);
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
