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

    const exe = b.addExecutable(.{
        .name = "test",
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("ziglua", ziglua.module("ziglua"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run test");
    run_step.dependOn(&run_cmd.step);
}
