const std = @import("std");
const FS = @import("FS/FS.zig");

const mon = @import("mon/mon.zig");
const ent = @import("ent/ent.zig");
const graphics = @import("graphics.zig");

pub fn filename_from_index(index: u64, allocator: std.mem.Allocator) ![]const u8 {
    try FS.rom.seekTo(0x1307C8 + (index * @sizeOf(u32)));
    const addr = try FS.rom.reader().readInt(u32, .little);
    try FS.rom.seekTo(addr - 0x1ffc000);
    try FS.rom.seekBy(1); // skip the "/", it isn't used in the FS.zig parser
    std.log.info("addr: {x}", .{addr - 0x1ffc000});
    const file_name: []u8 = try FS.rom.reader().readUntilDelimiterAlloc(allocator, 0, 100);

    return file_name;
}

pub fn read_mon_data(filename: []const u8, area_id: u8, allocator: std.mem.Allocator) void {
    var mon_data = FS.rom_archive.OpenFile(filename);
    _ = mon_data.SeekIndexed(0);

    std.log.info("offset 0x{x}\n", .{try FS.rom.getPos()});

    try FS.rom.seekBy(4);
    const length = try FS.rom.reader().readInt(u16, .little);

    const mon_array = allocator.alloc(mon.FS_entry, length) catch {
        std.log.err("Failed to allocate mon array", .{});
        return;
    };

    std.log.info("Mon Entry Dump", .{});
    std.log.info("length: {x}", .{length});

    for (0..length) |i| {
        const mon_entry = try FS.rom.reader().readStruct(mon.FS_entry);
        if ((mon_entry.area_id) == area_id)
            mon_array[i] = mon_entry;
    }
}

pub fn read_area_ent_file_list(address: ent.ListAddresses, allocator: std.mem.Allocator) ![]u8 {
    try FS.rom.seekTo(@intFromEnum(address));

    const file_list: []u8 = try FS.rom.reader().readUntilDelimiterAlloc(allocator, 0, 50);

    return file_list;
}

pub fn read_ent_data(address: ent.ListAddresses, allocator: std.mem.Allocator) ![]ent.FS_entry {
    const file_list = try read_area_ent_file_list(address, allocator);
    const entry_list = try allocator.alloc(ent.FS_entry, file_list.len);
    for (file_list, 0..) |id, i| {
        const file_name = try filename_from_index(id, allocator);
        var ent_data = FS.rom_archive.OpenFile(file_name);
        ent_data.SeekTo();

        entry_list[i] = ent.FS_entry{
            .file_name = file_name,
            .file_data_addr = try FS.rom.getPos(),
            .file_size = ent_data.length(),
        };
    }
    return entry_list;
}
