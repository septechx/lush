const std = @import("std");
const lua = @import("server/templating/lua.zig");

pub fn main() !void {
    const stderr = std.io.getStdErr().writer();
    const allocator = std.heap.page_allocator;
    var ssrv = try lua.srrv(allocator, "../../test/my-lush-app/src/routes", stderr);
    ssrv.deinit();
}
