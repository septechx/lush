const std = @import("std");

pub const StringMap = struct {
    path: []const u8,
    content: []const u8,
};

pub const TemplateMap = []StringMap;

pub const templateMap = [_]StringMap{
    .{ .path = "src/", .content = "" },
    .{ .path = ".gitignore", .content = @embedFile("template/.gitignore") },
    .{ .path = ".npmrc", .content = @embedFile("template/.npmrc") },
    .{ .path = "bundler.config.ts", .content = @embedFile("template/bundler.config.ts") },
    .{ .path = "package.json", .content = @embedFile("template/package.json") },
};

pub fn getSize(map: StringMap, name: []const u8) usize {
    return map.content.len - 6 + name.len;
}

pub fn makeTemplate(allocator: std.mem.Allocator, name: []const u8, destination: TemplateMap) !void {
    std.mem.copyForwards(StringMap, destination, &templateMap);

    for (destination) |*map| {
        if (std.mem.eql(u8, map.path, "package.json")) {
            const size = getSize(map.*, name);
            const templateBuf = try allocator.alloc(u8, size);
            errdefer allocator.free(templateBuf);

            _ = std.mem.replace(u8, map.content, "{name}", name, templateBuf);
            map.content = templateBuf;
        }
    }
}

pub fn createProject(basePath: []const u8, template: TemplateMap) !void {
    var dir = try std.fs.cwd().makeOpenPath(basePath, .{});
    defer dir.close();

    for (template) |map| {
        const path = map.path;
        const content = map.content;

        if (std.mem.endsWith(u8, path, "/")) {
            try dir.makePath(path);
            continue;
        }

        if (std.mem.lastIndexOf(u8, path, "/")) |last_slash| {
            const dir_path = path[0..last_slash];
            try dir.makePath(dir_path);
        }

        const file = try dir.createFile(path, .{});
        defer file.close();
        try file.writeAll(content);
    }
}
