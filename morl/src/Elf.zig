// following this elf spec : https://www.infania.net/misc1/sgi_techpubs/techpubs/007-4658-001.pdf

const std = @import("std");
const Mir = @import("sema/Mir.zig");

const EI_NIDENT: usize = 16;

mir: Mir,
e_header: ElfHeader,
p_header: ProgramHeader, // TODO: probably more in the future
machine_code: []const u8,

const Self = @This();

// Name             Size    Alignment   Purpose
// Elf64_Addr       8       8           Unsigned program address
// Elf64_Half       2       2           Unsigned small integer
// Elf64_Off        8       8           Unsigned file offset
// Elf64_Sword      4       4           Signed medium integer
// Elf64_Sxword     8       8           Signed large integer
// Elf64_Word       4       4           Unsigned medium integer
// Elf64_Xword      8       8           Unsigned large integer
// Elf64_Byte       1       1           Unsigned tiny integer
// Elf64_Section    2       2           Section index (unsigned)

const ElfHeader = struct {
    e_ident: [EI_NIDENT]u8,
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

    fn init() ElfHeader {
        return .{
            .e_ident = [EI_NIDENT]u8{
                // EI_MAG0-3    => magic number
                0x7f, 0x45, 0x4C, 0x46, // 0x7f, 'E', 'L', 'F',
                // EI_CLASS     => 64-bit format
                0x02,
                // EI_DATA      => little endian
                0x01,
                // EI_VERSION   => 1
                0x01,
                // EI_OSABI
                0x00,
                // EI_ABIVERSION
                0x00,
                // EI_PAD
                0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00,
            },
            // ET_EXEC
            .e_type = 0x02,
            // x86
            .e_machine = 0x03,
            .e_version = 0x01,
            .e_entry = 0x780040,
            .e_phoff = 0x40,
            .e_shoff = 0x00,
            .e_flags = 0x00,
            .e_ehsize = 0x40,
            .e_phentsize = 0x38,
            .e_phnum = 0x01,
            .e_shentsize = 0x40,
            .e_shnum = 0x00,
            .e_shstrndx = 0x00,
        };
    }

    fn writeToBin(
        self: ElfHeader,
        writer: anytype, // TODO: get better at zig...
    ) !void {
        _ = try writer.write(&self.e_ident);
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

const ProgramHeader = struct {
    p_type: u32,
    p_flags: u32,
    p_offset: u64,
    p_vaddr: u64,
    p_paddr: u64,
    p_filesz: u64,
    p_memsz: u64,
    p_align: u64,

    fn init() ProgramHeader {
        return .{
            .p_type = 0x01,
            .p_flags = 0x05,
            .p_offset = 0x78,
            .p_vaddr = 0x780040,
            .p_paddr = 0x00,
            .p_filesz = 0x10,
            .p_memsz = 0x10,
            .p_align = 0x0010,
        };
    }

    fn writeToBin(self: *ProgramHeader, writer: anytype) !void {
        try writer.writeBits(self.p_type, 32);
        try writer.writeBits(self.p_flags, 32);
        try writer.writeBits(self.p_offset, 64);
        try writer.writeBits(self.p_vaddr, 64);
        try writer.writeBits(self.p_paddr, 64);
        try writer.writeBits(self.p_filesz, 64);
        try writer.writeBits(self.p_memsz, 64);
        try writer.writeBits(self.p_align, 64);
    }
};

pub fn init(
    mir: Mir,
) Self {
    return .{
        .mir = mir,
        .machine_code = "",
        .e_header = ElfHeader.init(),
        .p_header = ProgramHeader.init(),
    };
}

pub fn genExecutable(self: *Self) !void {
    const cwd = std.fs.cwd();
    const file = try cwd.createFile("bin", .{ .read = true });
    defer file.close();

    var bit_stream = std.io.bitWriter(.little, file.writer());

    try self.e_header.writeToBin(&bit_stream);
    try self.p_header.writeToBin(&bit_stream);

    _ = try bit_stream.write(&[_]u8{
        0x48, 0xC7, 0xC0, 0x3C,
        0x00, 0x00, 0x00, 0x48,
        0xC7, 0xC7, 0x2A, 0x00,
        0x00, 0x00, 0x0F, 0x05,
    });
}

pub fn deinit(self: *Self) void {
    _ = self;
}
