const std = @import("std");

const StringMap = struct { []const u8, []const u8 };

const templateMap = [_]StringMap{
    .{ ".gitignore", @embedFile("../template/.gitignore") },
    .{ ".npmrc", @embedFile("../template/.npmrc") },
    .{ "bundler.config.ts", @embedFile("../template/bundler.config.ts") },
    .{ "package.json", @embedFile("../template/package.json") },
};

pub fn makeTemplate(name: []const u8, destination: *templateMap) !void {
    var buf: [templateMap.len]StringMap = undefined;

    for (templateMap) |map| {
        if (std.mem.eql(u8, "package.json")) {
            const size = map[1].len - 6 + name.len;
            var templateBuf: [size]u8 = undefined;
            std.mem.replace(u8, map[1], "{name}", name, &templateBuf);
            buf.append(.{ map[0], templateBuf });
        } else {
            buf.append(map);
        }
    }

    try std.mem.copyForwards(StringMap, destination, buf);
}
