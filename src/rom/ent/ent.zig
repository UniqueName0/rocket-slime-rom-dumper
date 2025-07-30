pub const FS_entry = struct {
    file_name: []const u8,
    file_data_addr: u64,
    file_size: u32,
};

//these are hardcoded in the rom
pub const ListAddresses = enum(u64) {
    forewood = 0x13222C, // add 0x1FFC000 to get the address in ghidra
    tootinschleiman = 0x132240,
    // TODO: add the rest
};
