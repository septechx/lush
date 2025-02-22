const std = @import("std");

pub fn processLuaRecurse(
    allocator: std.mem.Allocator,
    dir: std.fs.Dir,
    parent_path: []const u8,
) !void {
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        switch (entry.kind) {
            .directory => {
                var subdir = try dir.openDir(entry.name, .{ .iterate = true });
                defer subdir.close();
                const new_path = try std.fs.path.join(allocator, &[_][]const u8{ parent_path, entry.name });
                defer allocator.free(new_path);
                try processLuaRecurse(allocator, subdir, new_path);
            },
            .file => {
                const ext = std.fs.path.extension(entry.name);
                if (std.mem.eql(u8, ext, ".lua")) {
                    const dest = try std.fs.path.join(allocator, &[_][]const u8{ "dist/client", parent_path, entry.name });
                    defer allocator.free(dest);

                    if (std.fs.path.dirname(dest)) |dest_path| {
                        try std.fs.cwd().makePath(dest_path);

                        var dest_dir = try std.fs.cwd().openDir(dest_path, .{});
                        defer dest_dir.close();

                        try dir.copyFile(entry.name, dest_dir, entry.name, .{});
                    }
                }
            },
            else => continue,
        }
    }
}
