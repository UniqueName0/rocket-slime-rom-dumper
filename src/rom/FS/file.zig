const std = @import("std");
const FS = @import("FS.zig");
const archive = @import("archive.zig");

pub const FS_FILE_NAME_MAX = 127;
pub const FS_DMA_NOT_USE = @as(u32, @bitCast(~@as(i32, 0)));

pub const FSDirPos = extern struct {
    arc: ?*archive.FSArchive = null,
    index: u16 = 0,
    pos: u32 = 0,
    bottom: u32 = 0,
};

pub const FSFileID = extern struct {
    arc: *archive.FSArchive,
    file_id: u32,
};

pub const FSDirEntry = extern struct {
    id: extern union {
        file_id: FSFileID,
        dir_id: FSDirPos,
    },
    is_directory: u32,
    name_len: u32,
    name: [FS_FILE_NAME_MAX + 1]u8,
};

pub const FSFileLink = extern struct {
    prev: *FSFile,
    next: *FSFile,
};

pub const FSFile = extern struct {
    link: FSFileLink,
    arc: *archive.FSArchive,

    props: extern struct {
        pos: FSDirPos,
        parent: u32,
        name: [*c]u8,
        name_len: u32,
    },

    pub fn OpenNextFile(
        self: *FSFile,
        index: u16,
    ) void {
        const rom: *std.fs.File = FS.rom;
        std.log.info("offset: {x}", .{self.props.pos.pos + self.arc.fnt});
        rom.seekTo(self.props.pos.pos + self.arc.fnt) catch |err| {
            std.log.err("Failed to seek to file position: {}\n", .{err});
            return;
        };

        const len = (rom.reader().readByte() catch 0) & 0x7F;
        self.props.pos.pos += @sizeOf(u8);
        const name = std.heap.page_allocator.alloc(u8, len) catch |err| {
            std.log.err("Failed to allocate memory for file name: {}\n", .{err});
            return;
        };
        _ = rom.reader().read(name) catch |err| {
            std.log.err("Failed to read file name: {}\n", .{err});
            return;
        };
        self.props.pos.index = index;
        std.log.info("File \"{s}\" with len {}", .{ name, len });
        self.props.name = @ptrCast(name);
        self.props.name_len = len;
        self.props.pos.pos += len;
    }

    pub fn close(
        self: *FSFile,
    ) void {
        std.heap.page_allocator.free(self.props.name[0..self.props.name_len]);
    }

    pub fn SeekTo(self: *FSFile) void {
        const pos = self.arc.fat + self.props.pos.index * @sizeOf(FatFileEntry);
        std.log.info("File entry offset: {x}", .{pos});
        FS.rom.seekTo(pos) catch |err| {
            std.log.err("Failed to seek to file position: {}\n", .{err});
            return;
        };
        std.log.info("File entry offset: {x}", .{pos});
        const entry = FS.rom.reader().readStruct(FatFileEntry) catch |err| {
            std.log.err("Failed to read file position: {}\n", .{err});
            return;
        };
        self.props.pos.pos = entry.top;
        self.props.pos.bottom = entry.bottom;
        FS.rom.seekTo(entry.top) catch |err| {
            std.log.err("Failed to seek to file position: {}\n", .{err});
            return;
        };
        std.log.info("File data offset: {x} to {x}", .{ entry.top, entry.bottom });
    }

    pub fn SeekIndexed(self: *FSFile, index: i64) u32 {
        self.SeekTo();
        const reader = FS.rom.reader();
        const num_entries = reader.readInt(u32, .little) catch |err| {
            std.log.err("Failed to read file length: {}\n", .{err});
            return 0;
        };
        FS.rom.seekBy(index * 8) catch |err| {
            std.log.err("Failed to seek to file position: {}\n", .{err});
            return 0;
        };
        const offset = reader.readInt(u32, .little) catch |err| {
            std.log.err("Failed to read file length: {}\n", .{err});
            return 0;
        };
        std.debug.print("start_offset: {x}\n", .{offset});
        const size = reader.readInt(u32, .little) catch |err| {
            std.log.err("Failed to read file length: {}\n", .{err});
            return 0;
        };
        std.debug.print("size: {x}\n", .{size});
        self.SeekTo();
        FS.rom.seekBy(offset + num_entries * 8 + 4) catch |err| {
            std.log.err("Failed to seek to file position: {}\n", .{err});
            return 0;
        };
        return size;
    }

    pub fn length(self: *FSFile) u32 {
        return self.props.pos.bottom - self.props.pos.pos;
    }
};

pub const FntDirEntry = extern struct {
    entry_start: u32,
    entry_file_id: u16,
    parent_id: u16,
};

pub const FatFileEntry = extern struct {
    top: u32,
    bottom: u32,
};
