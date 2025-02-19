const std = @import("std");
const ziglua = @import("ziglua");

pub const functions = [_]Function{.{ .function = fetcher, .name = "Fetch" }};

const Function = struct {
    function: fn (*ziglua.Lua) i32,
    name: [:0]const u8,
};

fn fetcher(lua: *ziglua.Lua) i32 {
    _ = lua.pushString("test text");
    return 1;
}
