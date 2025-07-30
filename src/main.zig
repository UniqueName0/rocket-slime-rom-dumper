const std = @import("std");
const archive = @import("rom/FS/archive.zig");
const FS = @import("rom/FS/FS.zig");
const parser = @import("rom/parsing.zig");
const graphics = @import("rom/graphics.zig");
const file = @import("rom/FS/file.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    std.debug.print("rom path: {s}\n", .{args[1]});
    FS.init(args[1], allocator);
    defer FS.deinit();

    const area: graphics.area_data = try graphics.readAreaData(41); // 41 is the first area in forewood forest
    std.debug.print("size: {x}\n", .{area.width});
    var bg_data: file.FSFile = FS.rom_archive.OpenFile("stage_bg.bin");
    const size = bg_data.SeekIndexed(area.file_index1);

    // not 100% sure that this is actually a palette, its just 512 bytes so my first assumption was 256 color palette
    const palette: *graphics.Palette256 = try allocator.create(graphics.Palette256);
    _ = try FS.rom.read(&@as(*[512]u8, @ptrCast(palette)).*);

    std.log.info("{} bytes", .{size});

    graphics.debugPrintPalette(palette.*);
}
