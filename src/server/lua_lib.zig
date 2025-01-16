const std = @import("std");
const ziglua = @import("ziglua");

pub const functions = [_]Function{.{ .function = fetcher, .name = "fetch" }};

const Function = struct {
    function: fn (*ziglua.Lua) i32,
    name: []const u8,
};

fn fetcher(lua: *ziglua.Lua) i32 {
    lua.pushString("test text");
    return 1;
}
