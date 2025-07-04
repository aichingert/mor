// following this elf spec : https://www.infania.net/misc1/sgi_techpubs/techpubs/007-4658-001.pdf
// and a lot of other sources at the bottom of this one are some v
// https://gist.github.com/x0nu11byt3/bcb35c3de461e5fb66173071a2379779

const std = @import("std");

const Mir = @import("sema/Mir.zig");
const Asm = @import("coge/linux_x86_64.zig");

const base_point: u64 = 0x400000;

const ElfHeader = struct {
    magic: [4]u8 = "\x7fELF".*,
    class: u8 = 2,
    endianness: u8 = 1,
    version: u8 = 1,
    abi: u8 = 0,
    abi_version: u8 = 0,
    padding: [7]u8 = [_]u8{0} ** 7,

    e_type: u16,
    e_machine: u16,
    e_version: u32,
    e_entry: u64,
    e_phoff: u64,
    e_shoff: u64,
    e_flags: u32,
    e_ehsize: u16,
    e_phentsize: u16,
    e_phnum: u16,
    e_shentsize: u16,
    e_shnum: u16,
    e_shstrndx: u16,

    fn init(entry: u64) ElfHeader {
        return .{
            .e_type = 0x2,
            .e_machine = 0x3e,
            .e_version = 0x1,
            .e_entry = entry,
            .e_phoff = 0x40,
            .e_shoff = 0x00,
            .e_flags = 0x00,
            .e_ehsize = 0x40,
            .e_phentsize = 0x38,
            .e_phnum = 0x1,
            .e_shentsize = 0x40,
            .e_shnum = 0x00,
            .e_shstrndx = 0x00,
        };
    }

    fn writeToBin(
        self: *ElfHeader,
        writer: anytype,
    ) !void {
        for (0..self.magic.len) |i| {
            try writer.writeBits(self.magic[i], 8);
        }
        try writer.writeBits(self.class, 8);
        try writer.writeBits(self.endianness, 8);
        try writer.writeBits(self.version, 8);
        try writer.writeBits(self.abi, 8);
        try writer.writeBits(self.abi_version, 8);
        for (0..self.padding.len) |i| {
            try writer.writeBits(self.padding[i], 8);
        }
        try writer.writeBits(self.e_type, 16);
        try writer.writeBits(self.e_machine, 16);
        try writer.writeBits(self.e_version, 32);
        try writer.writeBits(self.e_entry, 64);
        try writer.writeBits(self.e_phoff, 64);
        try writer.writeBits(self.e_shoff, 64);
        try writer.writeBits(self.e_flags, 32);
        try writer.writeBits(self.e_ehsize, 16);
        try writer.writeBits(self.e_phentsize, 16);
        try writer.writeBits(self.e_phnum, 16);
        try writer.writeBits(self.e_shentsize, 16);
        try writer.writeBits(self.e_shnum, 16);
        try writer.writeBits(self.e_shstrndx, 16);
    }
};

const ProgHeader = struct {
    p_type: ProgType,
    p_flags: u32,
    p_offset: u64,
    p_vaddr: u64,
    p_paddr: u64,
    p_filesz: u64,
    p_memsz: u64,
    p_align: u64,

    const ProgType = enum(u32) {
        load = 0x1,
        dynamic = 0x2,
    };

    fn init(prog_type: ProgType, file_size: u64, mem_size: u64) ProgHeader {
        return .{
            .p_type = prog_type,
            .p_flags = 0x7,
            .p_offset = 0x00,
            .p_vaddr = base_point,
            .p_paddr = base_point,
            .p_filesz = file_size,
            .p_memsz = mem_size,
            .p_align = 0x100,
        };
    }

    fn writeToBin(self: *ProgHeader, writer: anytype) !void {
        try writer.writeBits(@intFromEnum(self.p_type), 32);
        try writer.writeBits(self.p_flags, 32);
        try writer.writeBits(self.p_offset, 64);
        try writer.writeBits(self.p_vaddr, 64);
        try writer.writeBits(self.p_paddr, 64);
        try writer.writeBits(self.p_filesz, 64);
        try writer.writeBits(self.p_memsz, 64);
        try writer.writeBits(self.p_align, 64);
    }
};

pub fn genExe(gpa: std.mem.Allocator, mir: Mir) !void {
    var machine_code = try Asm.genCode(gpa, mir.instructions.items[0..]);
    defer machine_code.deinit();

    const cwd = std.fs.cwd();
    const file = try cwd.createFile("bin", .{ .read = true });
    defer file.close();

    var bit_stream = std.io.bitWriter(.little, file.writer());

    const header_off = @sizeOf(ElfHeader) + @sizeOf(ProgHeader);
    const entry_off = base_point + header_off;
    const file_size = header_off + machine_code.items.len;
    var e_header = ElfHeader.init(entry_off);
    var p_header = ProgHeader.init(.load, file_size, file_size);
    try e_header.writeToBin(&bit_stream);
    try p_header.writeToBin(&bit_stream);

    for (machine_code.items) |byte| {
        try bit_stream.writeBits(byte, 8);
    }

    try bit_stream.flushBits();
}
