const std = @import("std");
const Ast = @import("sema/Ast.zig");
const Mir = @import("sema/Mir.zig");

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

        var mir = Mir.init(allocator, ast);
        defer mir.deinit(allocator);

        //for (ast.nodes.items(.tag), 0..) |tag, i| {
        //    std.debug.print("{any}\n", .{tag});

        //    const idx = ast.nodes.items(.main)[i];
        //    const tok = ast.tokens.items(.tag)[idx];
        //    std.debug.print("  {any}\n", .{tok});
        //    std.debug.print("  {any}\n", .{ast.nodes.items(.data)[i]});
        //}
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
