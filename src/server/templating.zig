const std = @import("std");

const Variables = struct {
    _allocator: std.mem.Allocator,
    map: std.StringArrayHashMap(u8),

    pub fn init(allocator: std.mem.Allocator) Variables {
        return .{ ._allocator = allocator, ._map = std.StringArrayHashMap(u8).init(allocator) };
    }
};

pub fn parse(page: []const u8, allocator: std.mem.Allocator) []const u8 {
    const variables = Variables.init(allocator);

    for (std.mem.splitAny(u8, page, "\n")) |line| {
        _ = line;
        _ = variables;
        // Look at the lines and replace
    }
}
