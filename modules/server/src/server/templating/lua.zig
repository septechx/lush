const std = @import("std");
const ziglua = @import("ziglua");
const lua_lib = @import("lua_lib.zig");

pub fn makeBytecode(allocator: std.mem.Allocator, source: []const u8) ![]const u8 {
    return try ziglua.compile(allocator, source, .{});
}

pub fn srrv(allocator: std.mem.Allocator, dir: []const u8, stderr: std.fs.File.Writer) !std.StringHashMap([]const u8) {
    var variables = std.StringHashMap([]const u8).init(allocator);
    _ = &variables;

    var lua = try ziglua.Lua.init(allocator);
    defer lua.deinit();

    lua.openLibs();
    inline for (lua_lib.functions) |function| {
        pushFn(lua, function.function, function.name);
    }

    const lua_path = try std.fs.path.joinZ(allocator, &[_][]const u8{ dir, "server.lua" });
    defer allocator.free(lua_path);

    lua.doFile(lua_path) catch {
        try stderr.print("Error in lua code: {s}", .{try lua.toString(-1)});
    };

    lua.pushGlobalTable();
    lua.pushNil();
    while (lua.next(-1)) : (lua.pop(1)) {
        const key = try lua.toString(-2);
        const val = try lua.toString(-1);

        std.debug.print("{s} -> {s}\n", .{ key, val });
    }
}

fn pushFn(lua: *ziglua.Lua, comptime function: fn (*ziglua.Lua) i32, name: [:0]const u8) void {
    lua.pushFunction(ziglua.wrap(function));
    lua.setGlobal(name);
}
