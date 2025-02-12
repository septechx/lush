const std = @import("std");
const cli = @import("zig-cli");
const template = @import("template.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var config = struct {
    port: u16 = 3000,
    name: []const u8 = "my-lush-app",
}{};

fn init(r: *cli.AppRunner) !cli.Command {
    return cli.Command{
        .name = "init",
        .description = cli.Description{
            .one_line = "Create a new project",
        },
        .target = cli.CommandTarget{
            .action = cli.CommandAction{
                .exec = run_init,
                .positional_args = .{
                    .optional = try r.allocPositionalArgs(&.{
                        .{
                            .name = "name",
                            .help = "name for the project to create",
                            .value_ref = r.mkRef(&config.name),
                        },
                    }),
                },
            },
        },
    };
}

fn build(r: *cli.AppRunner) !cli.Command {
    _ = r;
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

fn parseArgs() !cli.ExecFn {
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
                    try init(&r),
                    try build(&r),
                }),
            },
        },
        .version = "0.1.0",
    };
    return try r.getAction(&app);
}

pub fn main() !void {
    const action = try parseArgs();
    try action();
    freeConfig();
}

fn freeConfig() void {
    if (!std.mem.eql(u8, config.name, "my-lush-app")) {
        allocator.free(config.name);
    }
    if (gpa.deinit() == .leak) {
        @panic("Leaked");
    }
}

fn run_server() !void {
    std.log.debug("server is listening on localhost:{d}", .{config.port});
}

fn run_dev() !void {
    try startBuild();
    try run_server();
}

fn run_build() !void {
    try startBuild();
}

fn run_init() !void {
    try startInit();
}

fn startInit() !void {
    var templateMap = try allocator.alloc(template.StringMap, template.templateMap.len);
    _ = &templateMap;
    defer allocator.free(templateMap);
    try template.makeTemplate(allocator, config.name, templateMap);
    try template.createProject(config.name, templateMap);
}

fn startBuild() !void {
    std.fs.cwd().deleteTree("dist") catch |err| {
        if (err != error.FileNotFound) return err;
    };

    const result = try std.process.Child.run(.{
        .allocator = allocator,
        // TODO: Make this run the file
        .argv = &.{ "bun", "run", "node_modules/@lush/lush/scripts/frontend-build.ts" },
        .max_output_bytes = 1024 * 1024,
    });
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }

    try std.io.getStdOut().writer().writeAll(result.stdout);
    try std.io.getStdErr().writer().writeAll(result.stderr);
}
