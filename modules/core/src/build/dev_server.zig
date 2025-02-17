const std = @import("std");
const Writer = std.fs.File.Writer;
const Reader = std.fs.File.Reader;
const io = std.io;
const globals = @import("../globals.zig");
const lon = @import("../lon.zig");

const chalk = @cImport({
    @cDefine("CHALK_NO_PREFIX", {});
    @cInclude("chalk.h");
    @cInclude("chalk-ext.h");
});

const stdin = io.getStdIn().reader();
const stdout = io.getStdOut().writer();

const Proto = struct {
    const lu = [_][]const u8{
        "b",
    };

    pub fn build() []const u8 {
        return send(0);
    }

    fn send(comptime ins: u1) []const u8 {
        return lu[ins] ++ "\n";
    }
};

pub fn init(allocator: std.mem.Allocator, config: anytype) !void {
    var child = std.process.Child.init(&[_][]const u8{ "bun", "node_modules/@lush/lush/scripts/child.ts" }, allocator);

    child.stdin_behavior = .Pipe;
    child.stdout_behavior = .Pipe;

    try child.spawn();

    const stdin_writer = child.stdin.?.writer();
    const stdout_reader = child.stdout.?.reader();

    const first = try build(allocator, true, stdin_writer, stdout_reader);
    defer allocator.free(first);

    const obj = try lon.parse(allocator, first);
    const timeToStart = obj.object.get("realTime").?.number;

    try startupMessage(allocator, config, timeToStart);

    var reloads: u32 = 1;

    while (true) {
        var buf: [2]u8 = undefined;
        const cmd = try stdin.readUntilDelimiter(&buf, '\n');

        if (cmd.len < 1) {
            continue;
        }

        switch (cmd[0]) {
            'r' => {
                _ = try build(allocator, true, stdin_writer, stdout_reader);
                try reload(allocator, reloads);
                reloads += 1;
            },
            else => {},
        }
    }

    _ = try child.kill();
}

fn makeLink(allocator: std.mem.Allocator, url: []const u8) ![]const u8 {
    return try std.fmt.allocPrint(allocator, "\x1b]8;;{s}\x1b\\\x1b[36m{s}\x1b[0m\x1b]8;;\x1b\\", .{ url, url });
}

fn makeTimestamp(allocator: std.mem.Allocator) ![]const u8 {
    const timestamp = std.time.timestamp();
    const seconds = @as(u64, @intCast(timestamp));

    const epoch_seconds = seconds;
    const tm = std.time.epoch.EpochSeconds{ .secs = epoch_seconds };
    const dt = tm.getDaySeconds();

    return try std.fmt.allocPrint(allocator, "\x1b[38;5;103m{d:0>2}:{d:0>2}:{d:0>2}\x1b[0m", .{
        dt.getHoursIntoDay(),
        dt.getMinutesIntoHour(),
        dt.getSecondsIntoMinute(),
    });
}

fn makeReloads(allocator: std.mem.Allocator, reloads: u32) ![]const u8 {
    return if (reloads > 1) try std.fmt.allocPrint(allocator, "\x1b[33m(x{d})\x1b[0m", .{reloads}) else "";
}

fn reload(allocator: std.mem.Allocator, reloads: u32) !void {
    const timestamp = try makeTimestamp(allocator);
    defer allocator.free(timestamp);

    const reloadAmount = try makeReloads(allocator, reloads);
    defer allocator.free(reloadAmount);

    try stdout.print("{s} {s} server restarted. {s}\n", .{ timestamp, chalk.CYAN("[lush]"), reloadAmount });
}

fn startupMessage(allocator: std.mem.Allocator, config: anytype, time: f64) !void {
    var buf: [23]u8 = undefined;
    const url = try std.fmt.bufPrint(&buf, "http://localhost:{d}/", .{config.port});
    const link = try makeLink(allocator, url);
    defer allocator.free(link);

    try stdout.print(
        \\
        \\  {s}{s} {s} {d}ms
        \\
        \\  {s}  Local: {s}
        \\  {s}  {s} r + enter {s}
        \\
    , .{
        chalk.GREEN("LUSH v"),
        chalk.GREEN(globals.version),
        chalk.GRAY("ready in"),
        time,
        chalk.LIGHT_GREEN("➜"),
        link,
        chalk.GREEN("➜"),
        chalk.GRAY("press"),
        chalk.GRAY("to reload"),
    });
}

fn build(allocator: std.mem.Allocator, mute: bool, stdin_writer: Writer, stdout_reader: Reader) ![]const u8 {
    try stdin_writer.writeAll(Proto.build());

    var outBuf: [256]u8 = undefined;
    const rawOut = try stdout_reader.readUntilDelimiter(&outBuf, '$');
    const separator = std.mem.indexOf(u8, rawOut, "%").?;

    if (!mute) {
        const buildOut = rawOut[0..separator];

        var ftmBuf: [256]u8 = undefined;
        const out = try std.fmt.bufPrint(&ftmBuf, "{s}\n", .{buildOut});

        try stdout.writeAll(out);
    }

    const obj = rawOut[separator + 1 ..];
    const ret = try allocator.alloc(u8, obj.len);
    @memcpy(ret, obj);
    return ret;
}
