// following this elf spec : https://www.infania.net/misc1/sgi_techpubs/techpubs/007-4658-001.pdf
// and a lot of other sources at the bottom of this one are some v
// https://gist.github.com/x0nu11byt3/bcb35c3de461e5fb66173071a2379779

const std = @import("std");
const Mir = @import("sema/Mir.zig");

const base_point: u64 = 0x400000;

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
        self: ElfHeader,
        writer: anytype, // TODO: get better at zig...
    ) !void {
        _ = try writer.write(&self.magic);
        try writer.writeBits(self.class, 8);
        try writer.writeBits(self.endianness, 8);
        try writer.writeBits(self.version, 8);
        try writer.writeBits(self.abi, 8);
        try writer.writeBits(self.abi_version, 8);
        _ = try writer.write(&self.padding);

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

pub fn genExecutable(gpa: std.mem.Allocator, mir: Mir.InstrList.Slice) !void {
    var machine_code = std.ArrayList(u8).init(gpa);
    defer machine_code.deinit();

    for (mir.items(.tag), 0..) |tag, i| {
        switch (tag) {
            .lbl, .push, .pop, .call, .ret, .jmp => {}, // TODO:
            .mov => {
                // it is not feasable to look up every option, I will have to understand
                // the intel manual first before I can generate the machine code for intel

                // 48 c7 c0 3c 00 00 00    mov    rax,0x3c
                // 48 c7 c1 3c 00 00 00    mov    rcx,0x3c
                // 48 c7 c2 3c 00 00 00    mov    rdx,0x3c
                // 48 c7 c3 3c 00 00 00    mov    rbx,0x3c
                // 48 c7 c6 3c 00 00 00    mov    rbp,0x3c
                // 48 c7 c6 3c 00 00 00    mov    rsi,0x3c
                // 48 c7 c7 3c 00 00 00    mov    rdi,0x3c
                const data = mir.items(.data)[i];
                _ = data;

                //machine_code.append(0x48);
                //machine_code.append(0xc7);
                //machine_code.append(@intFromEnum(data.lhs.kind.reg));
                //machine_code.append();
            },
            else => {},
        }

        std.debug.print("{s}\n", .{std.enums.tagName(Mir.Instr.Tag, tag).?});
    }

    const sys_exit = [_]u8{
        0x48, 0xc7, 0xc0, 0x3c, 0x00, 0x00, 0x00,
        0x48, 0xc7, 0xc7, 0x01, 0x00, 0x00, 0x00,
        0x0f, 0x05,
    };

    const header_off = 64 + 56;
    const entry_off = base_point + header_off;
    const file_size = header_off + machine_code.items.len;

    var e_header = ElfHeader.init(entry_off);
    var p_header = ProgHeader.init(.load, file_size, file_size);

    const cwd = std.fs.cwd();
    const file = try cwd.createFile("bin", .{ .read = true });
    defer file.close();

    var bit_stream = std.io.bitWriter(.little, file.writer());

    try e_header.writeToBin(&bit_stream);
    try p_header.writeToBin(&bit_stream);
    for (machine_code.items) |byte| {
        try bit_stream.writeBits(byte, 8);
    }
    _ = try bit_stream.write(&sys_exit);
    try bit_stream.flushBits();
}
