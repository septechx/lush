const std = @import("std");
const ziglua = @import("ziglua");

pub fn fetcher(lua: *ziglua.Lua) i32 {
    lua.pushString("test text");
    return 1;
}
