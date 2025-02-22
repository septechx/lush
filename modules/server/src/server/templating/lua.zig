const std = @import("std");
const ziglua = @import("ziglua");
const lua_lib = @import("lua_lib.zig");

pub fn srrv(allocator: std.mem.Allocator, dir: []const u8) !std.StringHashMap([]const u8) {
    var variables = std.StringHashMap([]const u8).init(allocator);
    errdefer variables.deinit();

    var lua = try ziglua.Lua.init(allocator);
    defer lua.deinit();

    lua.openLibs();
    inline for (lua_lib.functions) |function| {
        pushFn(lua, function.function, function.name);
    }

    const lua_path = try std.fs.path.joinZ(allocator, &[_][]const u8{ dir, "server.lua" });
    defer allocator.free(lua_path);

    const lua_file = try std.fs.cwd().openFile(lua_path, .{});
    defer lua_file.close();

    var lua_buf: [1024]u8 = undefined;
    const lua_buf_size = try lua_file.readAll(&lua_buf);
    lua_buf[lua_buf_size] = 0;

    try lua.doString(lua_buf[0..lua_buf_size :0]);

    std.debug.assert(try lua.getGlobal("Export") == .table);
    lua.pushNil();
    while (lua.next(-2)) : (lua.pop(1)) {
        const key = try lua.toString(-2);
        const val = try lua.toString(-1);

        const alloc_key = try allocator.alloc(u8, key.len);
        const alloc_val = try allocator.alloc(u8, val.len);

        @memcpy(alloc_key, key);
        @memcpy(alloc_val, val);

        try variables.put(alloc_key, alloc_val);
    }

    return variables;
}

fn pushFn(lua: *ziglua.Lua, comptime function: fn (*ziglua.Lua) i32, name: [:0]const u8) void {
    lua.pushFunction(ziglua.wrap(function));
    lua.setGlobal(name);
}
