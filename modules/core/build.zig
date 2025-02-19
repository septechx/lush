const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "lush",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const @"zig-cli" = b.dependency("zig-cli", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zig-cli", @"zig-cli".module("zig-cli"));

    const @"lush-server" = b.dependency("lush-server", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("lush-server", @"lush-server".module("lush-server"));

    exe.root_module.addIncludePath(.{ .cwd_relative = "include" });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
