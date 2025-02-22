const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addModule("lush-server", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const ziglua = b.dependency("ziglua", .{
        .target = target,
        .optimize = optimize,
        .lang = .luau,
    });
    lib.addImport("ziglua", ziglua.module("ziglua"));

    const @"alpha-html" = b.dependency("alpha-html", .{
        .target = target,
        .optimize = optimize,
    });
    lib.addImport("alpha-html", @"alpha-html".module("alpha-html"));
}
