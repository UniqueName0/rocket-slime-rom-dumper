const std = @import("std");
const FS = @import("FS/FS.zig");

pub const Color = packed struct(u16) {
    padding: u1,
    r: u5,
    g: u5,
    b: u5,
};

pub const Palette16 = [16]Color;
pub const Palette256 = [256]Color;

pub const area_data = packed struct {
    width: u16,
    height: u16,
    unknown: u16, // not sure what this is used for
    file_index1: u16, // still need to figure out what these files actually are
    file_index2: u16,
    loaded_index1: u16, // file data array index if they are loaded
    loaded_index2: u16,
};

pub fn readAreaData(area_id: usize) !area_data {
    const base_addr = 0x12C1F4; // 0x12E9F0 for tank battles
    try FS.rom.seekTo(base_addr + area_id * @sizeOf(area_data));
    return try FS.rom.reader().readStruct(area_data);
}

pub fn debugPrintPalette(palette: Palette256) void {
    for (palette, 0..) |color, i| {
        if (i % 16 == 0) {
            std.debug.print("\n", .{});
        }
        std.debug.print(
            "\x1b[48;2;{d};{d};{d}m  \x1b[0m",
            .{
                color.r,
                color.g,
                color.b,
            },
        );
    }
}
