const std = @import("std");
const Writer = std.fs.File.Writer;

pub fn prepareBuild(stdOut: Writer) !void {
    try stdOut.writeAll("\x1B[2J\x1B[H");

    std.fs.cwd().deleteTree("dist") catch |err| {
        if (err != error.FileNotFound) return err;
    };
}

pub fn build(allocator: std.mem.Allocator, stdOut: Writer, stdErr: Writer) !void {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "bun", "run", "node_modules/@lush/lush/scripts/build-once.ts" },
    });
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }

    try stdOut.writeAll(result.stdout);
    try stdErr.writeAll(result.stderr);
}
