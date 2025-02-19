const std = @import("std");
const Writer = std.fs.File.Writer;
const @"lush-server" = @import("lush-server");

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

    try processLuaRecurse(allocator, dir, "");
}

fn processLuaRecurse(
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
                    const file = try dir.openFile(entry.name, .{});
                    defer file.close();

                    const content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
                    defer allocator.free(content);

                    const bc = try @"lush-server".lua.makeBytecode(allocator, content);
                    defer allocator.free(bc);

                    const dest = try std.fs.path.join(allocator, &[_][]const u8{ "dist/client", parent_path, entry.name });
                    defer allocator.free(dest);

                    if (std.fs.path.dirname(dest)) |dest_dir| {
                        try std.fs.cwd().makePath(dest_dir);
                    }

                    const new_file = try std.fs.cwd().createFile(dest, .{});
                    defer new_file.close();

                    try new_file.writeAll(bc);
                }
            },
            else => continue,
        }
    }
}
