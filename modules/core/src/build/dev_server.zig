const std = @import("std");
const Writer = std.fs.File.Writer;
const Reader = std.fs.File.Reader;
const io = std.io;

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

pub fn init(allocator: std.mem.Allocator) !void {
    var child = std.process.Child.init(&[_][]const u8{ "bun", "node_modules/@lush/lush/scripts/child.ts" }, allocator);

    child.stdin_behavior = .Pipe;
    child.stdout_behavior = .Pipe;

    try child.spawn();

    const stdin_writer = child.stdin.?.writer();
    const stdout_reader = child.stdout.?.reader();

    try build(true, stdin_writer, stdout_reader);

    try startupMessage();

    while (true) {
        var buf: [2]u8 = undefined;
        const cmd = try stdin.readUntilDelimiter(&buf, '\n');

        if (cmd.len < 1) {
            continue;
        }

        switch (cmd[0]) {
            'r' => {
                try build(false, stdin_writer, stdout_reader);
            },
            else => {},
        }
    }

    _ = try child.kill();
}

fn startupMessage() !void {
    try stdout.print(
        \\
        \\  {s}{s} {s} {d}ms
        \\
        \\  {s}  {s} {s}
        \\  {s}  {s} -p 3000 
        \\  {s}  {s} r + enter
        \\
    , .{
        chalk.GREEN("LUSH v"),
        chalk.GREEN("0.1.9"),
        chalk.GRAY("ready in"),
        14,
        chalk.LIGHT_GREEN("➜"),
        chalk.GRAY("Running on"),
        chalk.LINK("http://localhost:3000/", chalk.CYAN("http://localhost:3000/")),
        chalk.GREEN("➜"),
        chalk.GRAY("Change port using"),
        chalk.GREEN("➜"),
        chalk.GRAY("Reload with"),
    });
}

fn build(mute: bool, stdin_writer: Writer, stdout_reader: Reader) !void {
    try stdin_writer.writeAll(Proto.build());

    if (!mute) {
        var buf: [256]u8 = undefined;
        const rawOut = try stdout_reader.readUntilDelimiter(&buf, '\n');

        var ftmBuf: [256]u8 = undefined;
        const out = try std.fmt.bufPrint(&ftmBuf, "{s}\n", .{rawOut});

        try stdout.writeAll(out);
    }
}
