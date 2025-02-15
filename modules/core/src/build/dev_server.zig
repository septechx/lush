const std = @import("std");
const Writer = std.fs.File.Writer;
const Reader = std.fs.File.Reader;
const io = std.io;

const stdin = io.getStdIn().reader();
const stdout = io.getStdOut().writer();

const Proto = struct {
    id: u1,

    const Self = @This();

    pub fn build() []const u8 {
        const instr = Self{ .id = 0 };

        return instr.send();
    }

    fn send(comptime self: Self) []const u8 {
        const lu = [_][]const u8{
            "b",
        };

        return lu[self.id] ++ "\n";
    }
};

pub fn init(allocator: std.mem.Allocator) !void {
    var child = std.process.Child.init(&[_][]const u8{ "bun", "node_modules/@lush/lush/scripts/child.ts" }, allocator);

    child.stdin_behavior = .Pipe;
    child.stdout_behavior = .Pipe;

    try child.spawn();

    const stdin_writer = child.stdin.?.writer();
    const stdout_reader = child.stdout.?.reader();

    try build(stdin_writer, stdout_reader);

    while (true) {
        var buf: [2]u8 = undefined;
        const cmd = try stdin.readUntilDelimiter(&buf, '\n');

        if (cmd.len < 1) {
            continue;
        }

        switch (cmd[0]) {
            'r' => {
                try build(stdin_writer, stdout_reader);
            },
            else => {},
        }
    }

    _ = try child.kill();
}

fn build(stdin_writer: Writer, stdout_reader: Reader) !void {
    try stdin_writer.writeAll(Proto.build());

    var buf: [256]u8 = undefined;
    const rawOut = try stdout_reader.readUntilDelimiter(&buf, '\n');

    var ftmBuf: [256]u8 = undefined;
    const out = try std.fmt.bufPrint(&ftmBuf, "{s}\n", .{rawOut});

    try stdout.writeAll(out);
}
