const std = @import("std");
const log = std.log.scoped(.lua);
const ziglua = @import("ziglua");
const lua_lib = @import("lua_lib.zig");

fn pushFn(lua: *ziglua.Lua, comptime function: fn (*ziglua.Lua) i32, name: [:0]const u8) void {
    lua.pushFunction(ziglua.wrap(function));
    lua.setGlobal(name);
}

pub fn getVariables(path: [:0]const u8, allocator: std.mem.Allocator) !std.StringHashMap([]const u8) {
    var variables = std.StringHashMap([]const u8).init(allocator);

    var lua = try ziglua.Lua.init(allocator);
    defer lua.deinit();

    lua.openLibs();
    inline for (lua_lib.functions) |function| {
        pushFn(lua, function.function, function.name);
    }

    lua.doFile(path) catch {
        log.err("{s}", .{try lua.toString(-1)});
    };

    _ = try lua.getGlobal("Template");
    if (!lua.isTable(-1)) {
        log.err("Error: Template is not a table", .{});
        return error.TemplateError;
    }

    lua.pushNil();
    while (lua.next(-2)) : (lua.pop(1)) {
        const luaKey = try lua.toString(-2);
        const luaValue = try lua.toString(-1);

        const keyLen = luaKey.len;
        const valueLen = luaValue.len;

        const key = try allocator.alloc(u8, keyLen);
        const value = try allocator.alloc(u8, valueLen);

        std.mem.copyForwards(u8, key, luaKey);
        std.mem.copyForwards(u8, value, luaValue);

        try variables.put(@ptrCast(key), @ptrCast(value));

        log.info("Key: {s}, Value: {s}", .{ key, value });
    }

    return variables;
}
