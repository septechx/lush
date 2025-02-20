const std = @import("std");
const ziglua = @import("ziglua");
const lua_lib = @import("lua_lib.zig");

pub fn makeBytecode(allocator: std.mem.Allocator, source: []const u8) ![]const u8 {
    return try ziglua.compile(allocator, source, .{});
}

pub fn srrv(allocator: std.mem.Allocator, dir: []const u8, stderr: std.fs.File.Writer) !std.StringHashMap([]const u8) {
    const variables = std.StringHashMap([]const u8).init(allocator);

    var lua = try ziglua.Lua.init(allocator);
    defer lua.deinit();

    lua.openLibs();
    inline for (lua_lib.functions) |function| {
        pushFn(lua, function.function, function.name);
    }

    const lua_path = try std.fs.path.join(allocator, &[_][]const u8{ dir, "server.lua" });
    defer allocator.free(lua_path);

    var buf: [1024]u8 = undefined;
    const bc = try std.fs.cwd().readFile(lua_path, &buf);

    lua.loadBytecode("...", bc) catch {
        try stderr.print("Error in lua code: {s}", .{try lua.toString(-1)});
    };
    lua.protectedCall(.{}) catch {
        try stderr.print("Error in lua code: {s}", .{try lua.toString(-1)});
    };

    return variables;
}

fn pushFn(lua: *ziglua.Lua, comptime function: fn (*ziglua.Lua) i32, name: [:0]const u8) void {
    lua.pushFunction(ziglua.wrap(function));
    lua.setGlobal(name);
}
