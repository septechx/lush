const std = @import("std");
const serverLog = std.log.scoped(.server);
const server = @import("server/server.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    server.createServer(allocator) catch |err| {
        serverLog.err("server error: {}", .{err});
        if (@errorReturnTrace()) |trace| {
            std.debug.dumpStackTrace(trace.*);
        }
    };
}
