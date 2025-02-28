const std = @import("std");
const templating = @import("templating/templating.zig");
const http = std.http;
const net = std.net;

const buffer_size = 8192;

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const Server = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Server {
        return .{ .allocator = allocator };
    }

    fn handleRequest(self: *Server, request: *http.Server.Request) !void {
        try stdout.print("{s} {s} {s}\n", .{ @tagName(request.head.method), @tagName(request.head.version), request.head.target });

        const file_path = try self.getFilePath(request.head.target);
        defer self.allocator.free(file_path);
        if (try self.serveFile(file_path, request)) {
            return;
        } else {
            try self.handleNotFound(request);
        }
    }

    fn getFilePath(self: *Server, target: []const u8) ![]u8 {
        const file_name = if (std.mem.eql(u8, target, "/"))
            "index.html"
        else if (target[0] == '/') target[1..] else target;
        return try std.fmt.allocPrint(self.allocator, "dist/client/{s}", .{file_name});
    }

    fn serveFile(
        self: *Server,
        file_path: []const u8,
        request: *http.Server.Request,
    ) !bool {
        if (!self.shouldServe(file_path)) return false;

        const file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
            if (err == error.FileNotFound) return false;
            return err;
        };
        defer file.close();

        const file_size = try file.getEndPos();
        const content = try file.readToEndAlloc(self.allocator, file_size);
        defer self.allocator.free(content);

        const content_type = try self.getContentType(file_path);

        const headers = [_]http.Header{.{
            .name = "Content-Type",
            .value = content_type,
        }};

        if (std.mem.eql(u8, content_type, "text/html")) {
            const processed = try templating.parse(self.allocator, content, file_path);

            try request.respond(processed, .{
                .extra_headers = &headers,
            });
        } else {
            try request.respond(content, .{
                .extra_headers = &headers,
            });
        }

        return true;
    }

    fn shouldServe(self: *Server, path: []const u8) bool {
        _ = self;
        if (std.mem.endsWith(u8, path, "server.lua")) return false;
        return true;
    }

    fn handleNotFound(self: *Server, request: *http.Server.Request) !void {
        _ = self;
        const body = "404 - Not Found";

        try request.respond(body, .{ .status = .not_found, .extra_headers = &[_]http.Header{.{ .name = "Content_Type", .value = "text/plain" }} });
    }

    fn getContentType(self: *Server, path: []const u8) ![]const u8 {
        _ = self;
        if (std.mem.endsWith(u8, path, ".html")) return "text/html";
        if (std.mem.endsWith(u8, path, ".css")) return "text/css";
        if (std.mem.endsWith(u8, path, ".js")) return "application/javascript";
        if (std.mem.endsWith(u8, path, ".png")) return "image/png";
        if (std.mem.endsWith(u8, path, ".jpg") or std.mem.endsWith(u8, path, ".jpeg")) return "image/jpeg";
        return "application/octet-stream";
    }

    pub fn runServer(self: *Server, tcp_server: *net.Server) !void {
        while (true) {
            var connection = tcp_server.accept() catch |err| {
                try stdout.print("Connection to client interrupted: {}\n", .{err});
                continue;
            };
            defer connection.stream.close();

            var read_buffer: [buffer_size]u8 = undefined;
            var http_server = http.Server.init(connection, &read_buffer);

            var request = http_server.receiveHead() catch |err| {
                try stderr.print("Could not read head: {}\n", .{err});
                continue;
            };

            self.handleRequest(&request) catch |err| {
                try stderr.print("Could not handle request: {}\n", .{err});
                return err;
                //continue;
            };
        }
    }
};

pub fn createServer(allocator: std.mem.Allocator, ip: []const u8, port: u16) !void {
    var server = Server.init(allocator);

    const address = net.Address.parseIp4(ip, port) catch unreachable;
    var tcp_server = try address.listen(.{});

    try server.runServer(&tcp_server);
}
