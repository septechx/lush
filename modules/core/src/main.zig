const std = @import("std");
const cli = @import("zig-cli");
const @"lush-server" = @import("lush-server");
const template = @import("template.zig");
const dev_server = @import("build/dev_server.zig");
const build_once = @import("build/build_once.zig");
const prepare = @import("build/prepare.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const stdOut = std.io.getStdOut().writer();
const stdErr = std.io.getStdErr().writer();

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

fn serve(r: *cli.AppRunner) !cli.Command {
    return cli.Command{
        .name = "serve",
        .description = cli.Description{
            .one_line = "Run the server",
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
                .exec = run_serve,
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
                    try serve(&r),
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

fn run_dev() !void {
    try prepare.prepareBuild(allocator, stdOut, true);
    try dev_server.init(allocator, config.port);
}

fn run_build() !void {
    try prepare.prepareBuild(allocator, stdOut, false);
    try build_once.build(allocator, stdOut, stdErr);
}

fn run_serve() !void {
    try @"lush-server".server.createServer(allocator, "127.0.0.1", config.port);
}

fn run_init() !void {
    var templateMap = try allocator.alloc(template.StringMap, template.templateMap.len);
    _ = &templateMap;
    defer allocator.free(templateMap);
    try template.makeTemplate(allocator, config.name, templateMap);
    try template.createProject(config.name, templateMap);
}
