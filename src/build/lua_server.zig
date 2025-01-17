const std = @import("std");
const fs = std.fs;
const log = std.log.scoped(.build);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    try fs.cwd().deleteTree("server");

    var app_dir = try fs.cwd().openDir("app", .{ .iterate = true });
    defer app_dir.close();

    var walker = try app_dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        log.info("Found: {s}", .{entry.basename});

        if (std.mem.eql(u8, entry.basename, "server.lua")) {
            const dest_path = try std.fmt.allocPrint(allocator, "server/{s}", .{entry.path});
            defer allocator.free(dest_path);

            if (fs.path.dirname(dest_path)) |dirname| {
                try fs.cwd().makePath(dirname);
            }

            const app_path = try std.fmt.allocPrint(allocator, "app/{s}", .{entry.path});
            defer allocator.free(app_path);

            try fs.cwd().copyFile(app_path, fs.cwd(), dest_path, .{});

            log.info("Copied from {s} to {s}", .{ app_path, dest_path });
        }
    }
}
