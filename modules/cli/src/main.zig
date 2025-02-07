const std = @import("std");
const cli = @import("zig-cli");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var config = struct {
    port: u16 = 3000,
}{};

fn build() cli.Command {
    return cli.Command{
        .name = "build",
        .description = cli.Description{
            .one_line = "Build the app",
        },

        .target = cli.CommandTarget{
            .action = cli.CommandAction{
                .exec = run_build,
            },
        },
    };
}

fn dev(r: *cli.AppRunner) !cli.Command {
    return cli.Command{
        .name = "dev",
        .description = cli.Description{
            .one_line = "Build the app and run the server",
        },
        .options = try r.allocOptions(&.{
            cli.Option{
                .long_name = "port",
                .help = "port to bind to",
                .short_alias = 'p',
                .required = false,
                .value_ref = r.mkRef(&config.port),
            },
        }),
        .target = cli.CommandTarget{
            .action = cli.CommandAction{
                .exec = run_dev,
            },
        },
    };
}

fn parseArgs() cli.AppRunner.Error!cli.ExecFn {
    var r = try cli.AppRunner.init(allocator);

    const app = cli.App{
        .option_envvar_prefix = "LUSH_",
        .command = cli.Command{
            .name = "lush",
            .description = cli.Description{
                .one_line = "Lua based web framework written in zig.",
            },
            .target = cli.CommandTarget{
                .subcommands = try r.allocCommands(&.{
                    try dev(&r),
                    build(),
                }),
            },
        },
        .version = "0.1.0",
    };

    return r.getAction(&app);
}

pub fn main() !void {
    try (try parseArgs())();
    freeConfig();
}

fn freeConfig() void {
    if (gpa.deinit() == .leak) {
        @panic("config leaked");
    }
}

fn run_dev() !void {}

fn run_build() !void {
    try createFrontendBuildFiles();

    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "bun", "run", "./.lush/build-frontend.ts" },
        .max_output_bytes = 1024 * 1024,
    }) catch |err| {
        std.log.err("Failed to execute bun: {s}\n", .{@errorName(err)});
        return;
    };

    std.debug.print("{s}\n", .{result.stdout});
}

fn run_server() !void {
    std.log.debug("server is listening on localhost:{d}", .{config.port});
}

const File = struct {
    path: []const u8,
    content: []const u8,
};

const files = [_]File{
    .{
        .path = "build-frontend.ts",
        .content = @embedFile("./frontend/build-frontend.ts"),
    },
    .{
        .path = "tailwind-plugin.ts",
        .content = @embedFile("frontend/tailwind-plugin.ts"),
    },
};

fn createFrontendBuildFiles() !void {
    try std.fs.cwd().deleteTree(".lush");
    try std.fs.cwd().makeDir(".lush");

    for (files) |file| {
        var newFile = try std.fs.cwd().createFile(
            try std.fs.path.join(
                allocator,
                &[_][]const u8{ ".lush/", file.path },
            ),
            .{ .read = true },
        );
        defer newFile.close();
        try newFile.writeAll(file.content);
    }
}
