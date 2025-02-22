const std = @import("std");
const Writer = std.fs.File.Writer;
const lua_copy = @import("lua_copy.zig");

pub fn prepareBuild(allocator: std.mem.Allocator, stdOut: Writer, clear: bool) !void {
    if (clear) {
        try stdOut.writeAll("\x1B[2J\x1B[H");
    }

    std.fs.cwd().deleteTree("dist") catch |err| {
        if (err != error.FileNotFound) return err;
    };

    try std.fs.cwd().makeDir("dist");

    var dir = try std.fs.cwd().openDir("src/routes", .{ .iterate = true });
    defer dir.close();

    try lua_copy.processLuaRecurse(allocator, dir, "");
}
