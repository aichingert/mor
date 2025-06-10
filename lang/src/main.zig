const std = @import("std");
const Allocator = std.mem.Allocator;

const Ast = @import("sema/Ast.zig");
//const Tct = @import("sema/Tct.zig");
//const Mir = @import("sema/Mir.zig");
const Elf = @import("Elf.zig");

const CompileError = error {
    Ast,
    File,
    Allocator,
};

pub fn compile(path: []const u8, allocator: Allocator) CompileError!void {
    var file = std.fs.cwd().openFile(path, .{}) catch return CompileError.File;
    defer file.close();

    const source = file.readToEndAlloc(allocator, 4 * 1024 * 1024) 
        catch return CompileError.File;
    defer allocator.free(source);

    var ast = Ast.from_source(allocator, source) catch |e| {
        std.debug.print("{any}\n", .{e});
        return CompileError.Ast;
    }; 
    defer ast.deinit(allocator);

    //var tct = try Tct.init(allocator, ast);
    //defer tct.deinit();

    //var mir = Mir.init(allocator, ast);
    //try mir.genInstructions();
    //defer mir.instructions.deinit();

    //try Elf.genExe(allocator, mir);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // TODO: error handling as well as logging
    //
    for (args[1..]) |arg| {
        try compile(arg, allocator);
    }
}
