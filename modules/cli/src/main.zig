const std = @import("std");
const cli = @import("zig-cli");

var config = struct {
    port: u16 = 3000,
}{};

pub fn main() !void {
    var r = try cli.AppRunner.init(std.heap.page_allocator);

    const app = cli.App{
        .command = cli.Command{
            .name = "lush",
            .description = .{ .one_line = "Lua based web framework written in zig." },
            .options = try r.allocOptions(&.{
                .{
                    .long_name = "port",
                    .help = "port to bind to",
                    .required = false,
                    .value_ref = r.mkRef(&config.port),
                },
            }),
            .target = cli.CommandTarget{
                .action = cli.CommandAction{ .exec = run_server },
            },
        },
    };
    return r.run(&app);
}

fn run_server() !void {
    std.log.debug("server is listening on localhost:{d}", .{config.port});
}
