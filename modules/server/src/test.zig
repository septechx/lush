const std = @import("std");
const lua = @import("server/templating/lua.zig");

pub fn main() !void {
    const stderr = std.io.getStdErr().writer();
    const allocator = std.heap.page_allocator;
    const out = lua.srrv(allocator, "../../my-lush-app/src/routes", stderr);
    std.debug.print("{s}\n", .{out});
}
