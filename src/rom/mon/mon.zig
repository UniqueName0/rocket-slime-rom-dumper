// this is how it is structured in the rom
pub const FS_entry = extern struct {
    def_index: u8,
    flags: u8,
    index: u8,
    facing_direction: u8,
    X: u16,
    Y: u16,
    area_id: u8,
    special_def_index: u8,
    field0_0xa: u16,
    field0_0xc: u16,
    load_flags: u16,
};
