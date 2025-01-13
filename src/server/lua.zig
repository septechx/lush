const std = @import("std");
const log = std.log.scoped(.lua);
const ziglua = @import("ziglua");
const lua_lib = @import("lua_lib.zig");

fn pushFn(lua: *ziglua.Lua, comptime function: anytype, name: []const u8) void {
    lua.pushFunction(ziglua.wrap(function));
    lua.setGlobal(name);
}

const Variables = struct {
    _allocator: std.mem.Allocator,
    map: std.StringHashMap([]const u8),

    pub fn init(allocator: std.mem.Allocator) Variables {
        return .{ ._allocator = allocator, .map = std.StringHashMap([]const u8).init(allocator) };
    }
};

pub fn getVariables(path: [:0]const u8, allocator: std.mem.Allocator) !Variables {
    const variables = Variables.init(allocator);

    var lua = try ziglua.Lua.init(allocator);
    defer lua.deinit();

    lua.openLibs();
    for (lua_lib.functions) |function| {
        pushFn(lua, function.function, function.name);
    }

    lua.doFile(path) catch {
        log.err("{s}\n", .{lua.toString(-1)});
    };

    lua.getGlobal("Template");
    if (!lua.isTable(-1)) {
        log.err("Error: Template is not a table\n", .{});
        return error.TemplateError;
    }

    lua.pushNil();
    while (lua.next(-2)) : (lua.pop(1)) {
        const key = lua.toString(-2);
        const value = lua.toString(-1);
        variables.map.put(key, value);
        log.info("Key: {}, Value: {}\n", .{ key, value });
    }

    return variables;
}
